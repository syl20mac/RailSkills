//
//  AuditLogger.swift
//  RailSkills
//
//  Service de logging des actions sensibles pour traçabilité
//  Rotation automatique (max 1000 entrées), export JSON/CSV, filtrage
//

import Foundation
import UIKit

/// Actions auditées dans l'application
enum AuditAction: String, Codable {
    // Cycle de vie app
    case appLaunched = "APP_LAUNCHED"
    case appTerminated = "APP_TERMINATED"
    
    // Gestion conducteurs
    case driverCreated = "DRIVER_CREATED"
    case driverModified = "DRIVER_MODIFIED"
    case driverDeleted = "DRIVER_DELETED"
    case driverImported = "DRIVER_IMPORTED"
    case driverExported = "DRIVER_EXPORTED"
    
    // Évaluations
    case evaluationStarted = "EVALUATION_STARTED"
    case evaluationCompleted = "EVALUATION_COMPLETED"
    case questionValidated = "QUESTION_VALIDATED"
    case noteAdded = "NOTE_ADDED"
    case noteModified = "NOTE_MODIFIED"
    
    // Checklist
    case checklistImported = "CHECKLIST_IMPORTED"
    case checklistExported = "CHECKLIST_EXPORTED"
    case checklistModified = "CHECKLIST_MODIFIED"
    
    // Synchronisation
    case syncToSharePoint = "SYNC_SHAREPOINT"
    case syncToiCloud = "SYNC_ICLOUD"
    case syncConflictResolved = "SYNC_CONFLICT_RESOLVED"
    
    // Rapports
    case reportGenerated = "REPORT_GENERATED"
    case reportExported = "REPORT_EXPORTED"
    
    // Sécurité
    case authenticationSuccess = "AUTH_SUCCESS"
    case authenticationFailure = "AUTH_FAILURE"
    case encryptionKeyGenerated = "ENCRYPTION_KEY_GENERATED"
    case dataDecrypted = "DATA_DECRYPTED"
}

/// Entrée d'audit log enrichie
struct AuditEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let action: AuditAction
    let target: String              // Cible de l'action (conducteur, fichier, etc.)
    let details: [String: String]   // Détails additionnels
    let userId: String?             // ID utilisateur si disponible
    let deviceId: String            // ID unique de l'appareil
    let ipAddress: String?          // Adresse IP locale
    
    init(action: AuditAction, target: String, details: [String: String] = [:], userId: String? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.action = action
        self.target = target
        self.details = details
        self.userId = userId
        self.deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        self.ipAddress = nil // À implémenter si nécessaire
    }
}

/// Compatibilité avec anciens logs
struct AuditLogEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let action: String
    let details: String
    let userInfo: String?
    
    init(action: String, details: String, userInfo: String? = nil) {
        self.id = UUID()
        self.date = Date()
        self.action = action
        self.details = details
        self.userInfo = userInfo
    }
}

/// Service de logging des actions sensibles avec rotation automatique
class AuditLogger {
    static let shared = AuditLogger()
    
    private let maxEntries = 1000  // Rotation automatique à 1000 entrées
    private let logKey = "railSkills_auditLog_v2"
    
    private init() {}
    
    // MARK: - Logging
    
    /// Enregistre une action dans le log d'audit
    /// - Parameters:
    ///   - action: Type d'action auditée
    ///   - target: Cible de l'action (conducteur, fichier, etc.)
    ///   - details: Détails additionnels sous forme de dictionnaire
    ///   - userId: ID de l'utilisateur (optionnel)
    func log(action: AuditAction, target: String, details: [String: String] = [:], userId: String? = nil) {
        let entry = AuditEntry(action: action, target: target, details: details, userId: userId)
        
        var logs = loadLogs()
        logs.append(entry)
        
        // Rotation automatique si dépassement
        if logs.count > maxEntries {
            logs = Array(logs.suffix(maxEntries))
            Logger.info("Rotation des logs d'audit effectuée (limite: \(maxEntries))", category: "AuditLogger")
        }
        
        saveLogs(logs)
        Logger.info("Audit: \(action.rawValue) - \(target)", category: "AuditLogger")
    }
    
    // MARK: - Chargement / Sauvegarde
    
    private func loadLogs() -> [AuditEntry] {
        guard let data = UserDefaults.standard.data(forKey: logKey) else {
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let logs = try? decoder.decode([AuditEntry].self, from: data) else {
            return []
        }
        
        return logs
    }
    
    private func saveLogs(_ logs: [AuditEntry]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        if let data = try? encoder.encode(logs) {
            UserDefaults.standard.set(data, forKey: logKey)
        }
    }
    
    // MARK: - Récupération
    
    /// Récupère tous les logs d'audit triés par date (plus récents en premier)
    func getAllLogs() -> [AuditEntry] {
        return loadLogs().sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Filtre les logs par action
    /// - Parameter action: Type d'action à filtrer
    /// - Returns: Liste des entrées filtrées
    func filter(by action: AuditAction) -> [AuditEntry] {
        return getAllLogs().filter { $0.action == action }
    }
    
    /// Filtre les logs par période
    /// - Parameters:
    ///   - from: Date de début
    ///   - to: Date de fin
    /// - Returns: Liste des entrées dans la période
    func filter(from: Date, to: Date) -> [AuditEntry] {
        return getAllLogs().filter { $0.timestamp >= from && $0.timestamp <= to }
    }
    
    /// Filtre les logs par cible
    /// - Parameter target: Cible à rechercher (conducteur, fichier, etc.)
    /// - Returns: Liste des entrées filtrées
    func filter(by target: String) -> [AuditEntry] {
        return getAllLogs().filter { $0.target.contains(target) }
    }
    
    // MARK: - Export
    
    /// Exporte les logs au format JSON
    /// - Returns: Données JSON encodées
    /// - Throws: Erreur d'encodage
    func exportLog() throws -> Data {
        let logs = getAllLogs()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try encoder.encode(logs)
    }
    
    /// Exporte les logs au format CSV (compatible Excel)
    /// - Returns: String CSV
    func exportLogAsCSV() -> String {
        let logs = getAllLogs()
        
        var csv = "ID,Timestamp,Action,Target,Details,UserID,DeviceID\n"
        
        for entry in logs {
            let detailsStr = entry.details.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
            let userId = entry.userId ?? ""
            
            csv += "\"\(entry.id.uuidString)\",\"\(entry.timestamp)\",\"\(entry.action.rawValue)\",\"\(entry.target)\",\"\(detailsStr)\",\"\(userId)\",\"\(entry.deviceId)\"\n"
        }
        
        return csv
    }
    
    // MARK: - Gestion
    
    /// Efface tous les logs d'audit
    func clear() {
        UserDefaults.standard.removeObject(forKey: logKey)
        Logger.info("Tous les logs d'audit effacés", category: "AuditLogger")
    }
    
    /// Retourne des statistiques sur les logs
    func getStats() -> AuditStats {
        let logs = loadLogs()
        let actionCounts = Dictionary(grouping: logs, by: { $0.action })
            .mapValues { $0.count }
        
        return AuditStats(
            totalEntries: logs.count,
            oldestEntry: logs.map { $0.timestamp }.min(),
            newestEntry: logs.map { $0.timestamp }.max(),
            actionCounts: actionCounts
        )
    }
    
    struct AuditStats {
        let totalEntries: Int
        let oldestEntry: Date?
        let newestEntry: Date?
        let actionCounts: [AuditAction: Int]
        
        var description: String {
            var result = """
            Statistiques d'audit:
            - Total d'entrées: \(totalEntries)
            - Entrée la plus ancienne: \(oldestEntry?.description ?? "N/A")
            - Entrée la plus récente: \(newestEntry?.description ?? "N/A")
            
            Actions les plus fréquentes:
            """
            
            let sorted = actionCounts.sorted { $0.value > $1.value }.prefix(5)
            for (action, count) in sorted {
                result += "\n- \(action.rawValue): \(count)"
            }
            
            return result
        }
    }
}
