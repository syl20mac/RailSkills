//
//  OfflineQueue.swift
//  RailSkills
//
//  File d'attente pour les opérations de synchronisation en mode hors-ligne
//

import Foundation
import Combine
import Network

/// Type d'opération de synchronisation
enum SyncOperationType: String, Codable {
    case driverUpdate
    case driverCreate
    case driverDelete
    case checklistUpdate
    case checklistCreate
    case evaluation
    case report
}

/// Opération de synchronisation en attente
struct PendingSyncOperation: Identifiable, Codable {
    let id: UUID
    let type: SyncOperationType
    let data: Data // Données JSON encodées
    let timestamp: Date
    var retryCount: Int
    let metadata: [String: String] // Informations supplémentaires (nom du conducteur, etc.)
    
    init(id: UUID = UUID(), type: SyncOperationType, data: Data, timestamp: Date = Date(), retryCount: Int = 0, metadata: [String: String] = [:]) {
        self.id = id
        self.type = type
        self.data = data
        self.timestamp = timestamp
        self.retryCount = retryCount
        self.metadata = metadata
    }
}

/// Gestionnaire de file d'attente hors-ligne
@MainActor
class OfflineQueue: ObservableObject {
    static let shared = OfflineQueue()
    
    @Published var pendingOperations: [PendingSyncOperation] = []
    @Published var isProcessing: Bool = false
    @Published var lastProcessedDate: Date?
    
    private let queueStorageKey = "offlineQueue"
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 5.0 // 5 secondes entre les tentatives
    
    private var networkMonitor: NetworkMonitor?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadQueue()
        setupNetworkMonitoring()
    }
    
    // MARK: - Gestion de la file d'attente
    
    /// Ajoute une opération à la file d'attente
    func queueOperation(_ type: SyncOperationType, data: Data, metadata: [String: String] = [:]) {
        let operation = PendingSyncOperation(
            type: type,
            data: data,
            metadata: metadata
        )
        
        pendingOperations.append(operation)
        saveQueue()
        
        Logger.info("Opération ajoutée à la file d'attente: \(type.rawValue)", category: "OfflineQueue")
        
        // Si en ligne, essayer de traiter immédiatement
        if networkMonitor?.isConnected == true {
            Task {
                await processQueue()
            }
        }
    }
    
    /// Traite la file d'attente
    func processQueue() async {
        guard !isProcessing else {
            Logger.debug("Traitement déjà en cours", category: "OfflineQueue")
            return
        }
        
        guard networkMonitor?.isConnected == true else {
            Logger.info("Pas de connexion, file d'attente mise en pause", category: "OfflineQueue")
            return
        }
        
        guard !pendingOperations.isEmpty else {
            Logger.debug("Aucune opération en attente", category: "OfflineQueue")
            return
        }
        
        isProcessing = true
        Logger.info("Traitement de \(pendingOperations.count) opération(s) en attente", category: "OfflineQueue")
        
        var processedOperations: [UUID] = []
        var failedOperations: [PendingSyncOperation] = []
        
        for operation in pendingOperations {
            do {
                let success = try await executeOperation(operation)
                
                if success {
                    processedOperations.append(operation.id)
                    Logger.success("Opération \(operation.type.rawValue) traitée avec succès", category: "OfflineQueue")
                } else {
                    // Incrémenter le compteur de tentatives
                    var updatedOperation = operation
                    updatedOperation.retryCount += 1
                    
                    if updatedOperation.retryCount < maxRetries {
                        failedOperations.append(updatedOperation)
                        Logger.warning("Opération \(operation.type.rawValue) échouée, nouvelle tentative (\(updatedOperation.retryCount)/\(maxRetries))", category: "OfflineQueue")
                    } else {
                        Logger.error("Opération \(operation.type.rawValue) définitivement échouée après \(maxRetries) tentatives", category: "OfflineQueue")
                        // Optionnel: notifier l'utilisateur de l'échec définitif
                    }
                }
                
                // Délai entre les opérations pour éviter la surcharge
                try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                
            } catch let error {
                Logger.error("Erreur lors du traitement de l'opération \(operation.type.rawValue): \(error.localizedDescription)", category: "OfflineQueue")
                
                var updatedOperation = operation
                updatedOperation.retryCount += 1
                
                if updatedOperation.retryCount < maxRetries {
                    failedOperations.append(updatedOperation)
                }
            }
        }
        
        // Retirer les opérations traitées avec succès
        pendingOperations = failedOperations
        saveQueue()
        
        lastProcessedDate = Date()
        isProcessing = false
        
        let successCount = processedOperations.count
        let failedCount = failedOperations.count
        
        Logger.info("Traitement terminé: \(successCount) réussie(s), \(failedCount) échouée(s)", category: "OfflineQueue")
        
        // Notifier l'utilisateur si nécessaire
        if successCount > 0 {
            NotificationCenter.default.post(
                name: .offlineQueueProcessed,
                object: nil,
                userInfo: ["successCount": successCount, "failedCount": failedCount]
            )
        }
    }
    
    /// Exécute une opération de synchronisation
    private func executeOperation(_ operation: PendingSyncOperation) async throws -> Bool {
        let sharePointService = SharePointSyncService.shared
        
        switch operation.type {
        case .driverUpdate, .driverCreate:
            // Décoder le conducteur
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            guard let driver = try? decoder.decode(DriverRecord.self, from: operation.data) else {
                Logger.error("Impossible de décoder le conducteur", category: "OfflineQueue")
                return false
            }
            
            // Synchroniser le conducteur
            do {
                try await sharePointService.syncDrivers([driver])
                return true
            } catch let error {
                Logger.error("Échec de la synchronisation du conducteur: \(error.localizedDescription)", category: "OfflineQueue")
                return false
            }
            
        case .driverDelete:
            // Pour la suppression, on peut stocker l'ID dans les métadonnées
            guard operation.metadata["driverId"] != nil else {
                return false
            }
            // Implémenter la suppression si nécessaire
            return true
            
        case .checklistUpdate, .checklistCreate:
            if !AppConfigurationService.shared.allowChecklistUpload {
                Logger.info("Synchronisation checklist désactivée : opération ignorée", category: "OfflineQueue")
                return true
            }
            // Décoder la checklist
            let decoder = JSONDecoder()
            guard let checklist = try? decoder.decode(Checklist.self, from: operation.data) else {
                return false
            }
            
            // Synchroniser la checklist
            do {
                try await sharePointService.syncChecklist(checklist)
                return true
            } catch let error {
                Logger.error("Échec de la synchronisation de la checklist: \(error.localizedDescription)", category: "OfflineQueue")
                return false
            }
            
        case .evaluation, .report:
            // Traiter selon le besoin
            return true
        }
    }
    
    /// Vide la file d'attente
    func clearQueue() {
        pendingOperations.removeAll()
        saveQueue()
        Logger.info("File d'attente vidée", category: "OfflineQueue")
    }
    
    /// Retire une opération spécifique
    func removeOperation(_ id: UUID) {
        pendingOperations.removeAll { $0.id == id }
        saveQueue()
    }
    
    // MARK: - Persistance
    
    private func saveQueue() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let encoded = try? encoder.encode(pendingOperations) {
            UserDefaults.standard.set(encoded, forKey: queueStorageKey)
        }
    }
    
    private func loadQueue() {
        guard let data = UserDefaults.standard.data(forKey: queueStorageKey) else {
            return
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        if let operations = try? decoder.decode([PendingSyncOperation].self, from: data) {
            pendingOperations = operations
            Logger.info("\(operations.count) opération(s) chargée(s) depuis le stockage", category: "OfflineQueue")
        }
    }
    
    // MARK: - Monitoring réseau
    
    private func setupNetworkMonitoring() {
        networkMonitor = NetworkMonitor()
        
        networkMonitor?.$isConnected
            .sink { [weak self] isConnected in
                guard let self = self else { return }
                
                if isConnected && !self.pendingOperations.isEmpty {
                    Logger.info("Connexion rétablie, traitement de la file d'attente", category: "OfflineQueue")
                    Task {
                        await self.processQueue()
                    }
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - NetworkMonitor

@MainActor
class NetworkMonitor: ObservableObject {
    @Published var isConnected: Bool = true
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let offlineQueueProcessed = Notification.Name("offlineQueueProcessed")
}

