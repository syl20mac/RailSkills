//
//  Store.swift
//  RailSkills
//
//  Service de persistance des données (UserDefaults)
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class Store: ObservableObject {
    // Clés de stockage UserDefaults
    @AppStorage("drivers") private var driversData: Data = Data()
    @AppStorage("lastChecklist") private var lastChecklistData: Data = Data()
    @AppStorage("lastChecklistVP") private var lastChecklistVPData: Data = Data()
    @AppStorage("lastChecklistTE") private var lastChecklistTEData: Data = Data()
    @AppStorage("checklistVersion") private var appliedChecklistVersion: String = ""
    @AppStorage("sharePointAutoSyncEnabled") var sharePointAutoSyncEnabled: Bool = true
    
    // Service SharePoint pour la synchronisation automatique
    private let sharePointService = SharePointSyncService.shared
    
    // Données principales de l'application
    @Published var drivers: [DriverRecord] = [] {
        didSet { 
            saveDriversDebounced()
            // Ne pas synchroniser automatiquement si on est en train de supprimer des conducteurs
            // Cela évite que la synchronisation recrée les fichiers supprimés sur SharePoint
            if !isDeletingDrivers && sharePointAutoSyncEnabled && sharePointService.isConfigured && !drivers.isEmpty {
                syncDriversToSharePointDebounced()
            }
            // Mettre à jour l'index de recherche quand les conducteurs changent
            if let checklist = checklist {
                SearchService.updateNotesSearchIndex(drivers: drivers, checklistTitle: checklist.title)
            }
        }
    }
    @Published var checklist: Checklist? {
        didSet { 
            saveChecklistDebounced()
            if sharePointAutoSyncEnabled && sharePointService.isConfigured, checklist != nil {
                syncChecklistToSharePointDebounced()
            }
            // Mettre à jour l'index de recherche quand la checklist change
            if let checklist = checklist {
                SearchService.updateNotesSearchIndex(drivers: drivers, checklistTitle: checklist.title)
            } else {
                SearchService.resetSearchIndex()
            }
        }
    }
    
    @Published var checklistVP: Checklist? {
        didSet { 
            saveChecklistVPDebounced()
            if sharePointAutoSyncEnabled && sharePointService.isConfigured, checklistVP != nil {
                syncChecklistVPToSharePointDebounced()
            }
            // Mettre à jour l'index de recherche quand la checklist VP change
            if let checklist = checklistVP {
                SearchService.updateNotesSearchIndex(drivers: drivers, checklistTitle: checklist.title)
            }
        }
    }
    
    @Published var checklistTE: Checklist? {
        didSet { 
            saveChecklistTEDebounced()
            if sharePointAutoSyncEnabled && sharePointService.isConfigured, checklistTE != nil {
                syncChecklistTEToSharePointDebounced()
            }
            // Mettre à jour l'index de recherche quand la checklist TE change
            if let checklist = checklistTE {
                SearchService.updateNotesSearchIndex(drivers: drivers, checklistTitle: checklist.title)
            }
        }
    }
    
    /// Indicateur de sauvegarde en cours
    @Published var isSaving = false
    
    /// Flag pour désactiver temporairement la synchronisation automatique pendant une suppression
    /// Évite que la synchronisation automatique recrée les fichiers supprimés sur SharePoint
    private var isDeletingDrivers = false
    
    // MARK: - Filtrage logique des données
    //
    // Historique :
    // - Ces propriétés filtraient auparavant les données par identité SNCF (CTT) via SNCFIdentityService
    // - Suite à la suppression de SNCF_ID, l'application fonctionne désormais sur un jeu de données global
    // - On conserve ces propriétés pour éviter de casser l'API interne (ViewModel / vues) mais
    //   elles retournent simplement les collections complètes.
    //
    // Remarque maintenance :
    // - Si une nouvelle logique de filtrage (par profil local, rôle, etc.) est réintroduite,
    //   elle devra être centralisée ici pour limiter l'impact dans le reste du code.
    
    /// Retourne la liste complète des conducteurs (plus de filtrage par identité SNCF)
    var filteredDrivers: [DriverRecord] {
        drivers
    }
    
    /// Retourne la checklist actuelle (plus de filtrage par identité SNCF)
    var filteredChecklist: Checklist? {
        checklist
    }
    
    // Encoders/Décodeurs réutilisables pour optimiser la mémoire
    private let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private var saveCancellable: AnyCancellable?
    private var sharePointSyncCancellable: AnyCancellable?
    
    init() {
        // Charger les données depuis UserDefaults
        loadDrivers()
        loadChecklist()
        loadChecklistVP()
        loadChecklistTE()
        
        // Vérifier le mode démo de manière synchrone (UserDefaults est thread-safe)
        let isDemoModeEnabled = UserDefaults.standard.bool(forKey: "demo_mode_enabled")
        
        // Si le mode démo est activé, charger les données de démonstration
        if isDemoModeEnabled {
            // Charger les données de démo de manière synchrone
            loadDemoDataSync()
        } else {
            // Si pas de checklist locale, tenter de télécharger depuis SharePoint
            if checklist == nil {
                Logger.info("Aucune checklist triennale locale - tentative de téléchargement depuis SharePoint...", category: "Store")
                // Lancer le téléchargement en arrière-plan (asynchrone)
                Task {
                    await self.downloadDefaultChecklistIfNeeded()
                }
            } else if let cl = checklist {
                Logger.info("Checklist triennale présente: \(cl.title) avec \(cl.items.count) éléments", category: "Store")
            }
            
            // Télécharger les checklists VP et TE si absentes
            // Essayer d'abord de charger depuis les fichiers locaux
            if checklistVP == nil {
                if let localChecklist = loadChecklistFromBundle(fileName: "questions_VP.json") {
                    self.checklistVP = localChecklist
                    saveChecklistVP()
                    Logger.success("Checklist VP chargée depuis le système de fichiers local", category: "Store")
                } else {
                    Logger.info("Aucune checklist VP locale - tentative de téléchargement depuis SharePoint...", category: "Store")
                    Task {
                        await self.downloadDefaultChecklistVPIfNeeded()
                    }
                }
            }
            
            if checklistTE == nil {
                if let localChecklist = loadChecklistFromBundle(fileName: "questions_TE.json") {
                    self.checklistTE = localChecklist
                    saveChecklistTE()
                    Logger.success("Checklist TE chargée depuis le système de fichiers local", category: "Store")
                } else {
                    Logger.info("Aucune checklist TE locale - tentative de téléchargement depuis SharePoint...", category: "Store")
                    Task {
                        await self.downloadDefaultChecklistTEIfNeeded()
                    }
                }
            }
        }
        
        Logger.info("\(drivers.count) conducteur(s) présent(s) localement", category: "Store")
    }
    
    /// Charge les données de démonstration de manière synchrone
    private func loadDemoDataSync() {
        Logger.info("Mode démo activé - chargement des données de démonstration", category: "Store")
        
        // Créer les conducteurs de démo
        let calendar = Calendar.current
        let now = Date()
        
        let driver1 = DriverRecord(
            name: "MARTIN",
            firstName: "Jean",
            cpNumber: "CP-2024-001",
            lastEvaluation: calendar.date(byAdding: .month, value: -6, to: now),
            triennialStart: calendar.date(byAdding: .year, value: -1, to: now),
            ownerSNCFId: "demo.reviewer@sncf.fr"
        )
        
        let driver2 = DriverRecord(
            name: "DUPONT",
            firstName: "Pierre",
            cpNumber: "CP-2024-002",
            lastEvaluation: calendar.date(byAdding: .month, value: -3, to: now),
            triennialStart: calendar.date(byAdding: .year, value: -2, to: now),
            ownerSNCFId: "demo.reviewer@sncf.fr"
        )
        
        let driver3 = DriverRecord(
            name: "BERNARD",
            firstName: "Marie",
            cpNumber: "CP-2024-003",
            lastEvaluation: calendar.date(byAdding: .month, value: -1, to: now),
            triennialStart: calendar.date(byAdding: .month, value: -6, to: now),
            ownerSNCFId: "demo.reviewer@sncf.fr"
        )
        
        self.drivers = [driver1, driver2, driver3]
        
        // Créer la checklist de démo
        var items: [ChecklistItem] = []
        
        // Catégorie 1 : Sécurité
        items.append(ChecklistItem(title: "Sécurité", isCategory: true))
        items.append(ChecklistItem(title: "Vérification des équipements de sécurité", isCategory: false))
        items.append(ChecklistItem(title: "Connaissance des procédures d'urgence", isCategory: false))
        items.append(ChecklistItem(title: "Respect des limitations de vitesse", isCategory: false))
        
        // Catégorie 2 : Technique
        items.append(ChecklistItem(title: "Technique", isCategory: true))
        items.append(ChecklistItem(title: "Maîtrise des systèmes de signalisation", isCategory: false))
        items.append(ChecklistItem(title: "Gestion des situations d'incident", isCategory: false))
        items.append(ChecklistItem(title: "Communication avec le poste de commande", isCategory: false))
        
        // Catégorie 3 : Réglementaire
        items.append(ChecklistItem(title: "Réglementaire", isCategory: true))
        items.append(ChecklistItem(title: "Connaissance de la réglementation CFL", isCategory: false))
        items.append(ChecklistItem(title: "Respect des temps de conduite", isCategory: false))
        items.append(ChecklistItem(title: "Documentation à jour", isCategory: false))
        
        self.checklist = Checklist(
            title: "Checklist de démonstration CFL",
            items: items,
            ownerSNCFId: "demo.reviewer@sncf.fr"
        )
        
        // Ajouter quelques états de progression
        if let checklist = self.checklist {
            let questions = checklist.questions
            let checklistKey = checklist.title
            
            for (index, driver) in self.drivers.enumerated() {
                var updatedDriver = driver
                var states = updatedDriver.checklistStates[checklistKey] ?? [:]
                
                let questionsToValidate = min(questions.count, (index + 1) * 3)
                for i in 0..<questionsToValidate {
                    if i < questions.count {
                        let state = i % 3 == 0 ? 2 : (i % 3 == 1 ? 1 : 0)
                        states[questions[i].id] = state
                    }
                }
                
                updatedDriver.checklistStates[checklistKey] = states
                self.drivers[index] = updatedDriver
            }
        }
        
        Logger.success("Données de démonstration chargées: \(self.drivers.count) conducteur(s), \(items.count) élément(s) de checklist", category: "Store")
    }
    
    // MARK: - Téléchargement automatique de la checklist
    
    /// Télécharge la checklist par défaut depuis SharePoint si aucune n'est présente
    /// Appelé automatiquement au démarrage si l'iPad n'a pas de checklist
    /// Réessaie après un délai si le backend n'est pas encore prêt
    @MainActor
    func downloadDefaultChecklistIfNeeded() async {
        // Ne rien faire si une checklist est déjà présente
        guard checklist == nil else {
            Logger.debug("Checklist déjà présente, pas de téléchargement", category: "Store")
            return
        }
        
        // Attendre un peu que l'app soit complètement initialisée
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
        
        // Vérifier si SharePoint est configuré
        guard SharePointSyncService.shared.isConfigured else {
            Logger.info("SharePoint non configuré, checklist ne sera pas téléchargée automatiquement", category: "Store")
            return
        }
        
        // Vérifier si le backend est accessible
        let backendAccessible = await BackendTokenService.shared.testBackendConnection()
        guard backendAccessible else {
            Logger.warning("Backend inaccessible, impossible de télécharger la checklist", category: "Store")
            return
        }
        
        Logger.info("Téléchargement de la checklist par défaut depuis SharePoint...", category: "Store")
        
        do {
            if let downloadedChecklist = try await SharePointSyncService.shared.downloadDefaultChecklist() {
                // Sauvegarder la checklist téléchargée
                self.checklist = downloadedChecklist
                saveChecklist()
                
                Logger.success("Checklist par défaut téléchargée et sauvegardée: \(downloadedChecklist.title)", category: "Store")
                
                // Notifier l'UI que la checklist a changé
                NotificationCenter.default.post(name: NSNotification.Name("ChecklistDownloaded"), object: nil)
            } else {
                Logger.warning("Pas de checklist par défaut trouvée sur SharePoint (chemin: RailSkills/Checklists/questions_CFL.json)", category: "Store")
            }
        } catch {
            Logger.error("Erreur lors du téléchargement de la checklist: \(error.localizedDescription)", category: "Store")
        }
    }
    
    /// Force le téléchargement de la checklist depuis SharePoint
    /// Appelé manuellement par l'utilisateur si besoin
    @MainActor
    func forceDownloadChecklist() async -> Bool {
        Logger.info("Téléchargement forcé de la checklist depuis SharePoint...", category: "Store")
        
        guard SharePointSyncService.shared.isConfigured else {
            Logger.error("SharePoint non configuré", category: "Store")
            return false
        }
        
        do {
            if let downloadedChecklist = try await SharePointSyncService.shared.downloadDefaultChecklist() {
                self.checklist = downloadedChecklist
                saveChecklist()
                Logger.success("Checklist téléchargée: \(downloadedChecklist.title)", category: "Store")
                return true
            } else {
                Logger.warning("Aucune checklist trouvée sur SharePoint", category: "Store")
                return false
            }
        } catch {
            Logger.error("Erreur: \(error.localizedDescription)", category: "Store")
            return false
        }
    }
    
    /// Force le téléchargement de la checklist VP depuis SharePoint
    /// Appelé manuellement par l'utilisateur si besoin
    @MainActor
    func forceDownloadChecklistVP() async -> Bool {
        Logger.info("Téléchargement forcé de la checklist VP depuis SharePoint...", category: "Store")
        
        guard SharePointSyncService.shared.isConfigured else {
            Logger.error("SharePoint non configuré", category: "Store")
            return false
        }
        
        do {
            if let downloadedChecklist = try await SharePointSyncService.shared.downloadDefaultChecklistVP() {
                self.checklistVP = downloadedChecklist
                saveChecklistVP()
                Logger.success("Checklist VP téléchargée: \(downloadedChecklist.title)", category: "Store")
                return true
            } else {
                Logger.warning("Aucune checklist VP trouvée sur SharePoint", category: "Store")
                return false
            }
        } catch {
            Logger.error("Erreur: \(error.localizedDescription)", category: "Store")
            return false
        }
    }
    
    /// Force le téléchargement de la checklist TE depuis SharePoint
    /// Appelé manuellement par l'utilisateur si besoin
    @MainActor
    func forceDownloadChecklistTE() async -> Bool {
        Logger.info("Téléchargement forcé de la checklist TE depuis SharePoint...", category: "Store")
        
        guard SharePointSyncService.shared.isConfigured else {
            Logger.error("SharePoint non configuré", category: "Store")
            return false
        }
        
        do {
            if let downloadedChecklist = try await SharePointSyncService.shared.downloadDefaultChecklistTE() {
                self.checklistTE = downloadedChecklist
                saveChecklistTE()
                Logger.success("Checklist TE téléchargée: \(downloadedChecklist.title)", category: "Store")
                return true
            } else {
                Logger.warning("Aucune checklist TE trouvée sur SharePoint", category: "Store")
                return false
            }
        } catch {
            Logger.error("Erreur: \(error.localizedDescription)", category: "Store")
            return false
        }
    }
    
    /// Télécharge la checklist VP par défaut depuis SharePoint si aucune n'est présente
    @MainActor
    func downloadDefaultChecklistVPIfNeeded() async {
        guard checklistVP == nil else {
            Logger.debug("Checklist VP déjà présente, pas de téléchargement", category: "Store")
            return
        }
        
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
        
        // Essayer d'abord de charger depuis le bundle de l'app
        if let bundleChecklist = loadChecklistFromBundle(fileName: "questions_VP.json") {
            self.checklistVP = bundleChecklist
            saveChecklistVP()
            Logger.success("Checklist VP chargée depuis le bundle: \(bundleChecklist.title)", category: "Store")
            NotificationCenter.default.post(name: NSNotification.Name("ChecklistVPDownloaded"), object: nil)
            return
        }
        
        guard SharePointSyncService.shared.isConfigured else {
            Logger.info("SharePoint non configuré, checklist VP ne sera pas téléchargée automatiquement", category: "Store")
            return
        }
        
        let backendAccessible = await BackendTokenService.shared.testBackendConnection()
        guard backendAccessible else {
            Logger.warning("Backend inaccessible, impossible de télécharger la checklist VP", category: "Store")
            return
        }
        
        Logger.info("Téléchargement de la checklist VP par défaut depuis SharePoint...", category: "Store")
        
        do {
            if let downloadedChecklist = try await SharePointSyncService.shared.downloadDefaultChecklistVP() {
                self.checklistVP = downloadedChecklist
                saveChecklistVP()
                Logger.success("Checklist VP par défaut téléchargée et sauvegardée: \(downloadedChecklist.title)", category: "Store")
                NotificationCenter.default.post(name: NSNotification.Name("ChecklistVPDownloaded"), object: nil)
            } else {
                Logger.warning("Pas de checklist VP par défaut trouvée sur SharePoint", category: "Store")
            }
        } catch {
            Logger.error("Erreur lors du téléchargement de la checklist VP: \(error.localizedDescription)", category: "Store")
        }
    }
    
    /// Télécharge la checklist TE par défaut depuis SharePoint si aucune n'est présente
    @MainActor
    func downloadDefaultChecklistTEIfNeeded() async {
        guard checklistTE == nil else {
            Logger.debug("Checklist TE déjà présente, pas de téléchargement", category: "Store")
            return
        }
        
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
        
        // Essayer d'abord de charger depuis le bundle de l'app
        if let bundleChecklist = loadChecklistFromBundle(fileName: "questions_TE.json") {
            self.checklistTE = bundleChecklist
            saveChecklistTE()
            Logger.success("Checklist TE chargée depuis le bundle: \(bundleChecklist.title)", category: "Store")
            NotificationCenter.default.post(name: NSNotification.Name("ChecklistTEDownloaded"), object: nil)
            return
        }
        
        guard SharePointSyncService.shared.isConfigured else {
            Logger.info("SharePoint non configuré, checklist TE ne sera pas téléchargée automatiquement", category: "Store")
            return
        }
        
        let backendAccessible = await BackendTokenService.shared.testBackendConnection()
        guard backendAccessible else {
            Logger.warning("Backend inaccessible, impossible de télécharger la checklist TE", category: "Store")
            return
        }
        
        Logger.info("Téléchargement de la checklist TE par défaut depuis SharePoint...", category: "Store")
        
        do {
            if let downloadedChecklist = try await SharePointSyncService.shared.downloadDefaultChecklistTE() {
                self.checklistTE = downloadedChecklist
                saveChecklistTE()
                Logger.success("Checklist TE par défaut téléchargée et sauvegardée: \(downloadedChecklist.title)", category: "Store")
                NotificationCenter.default.post(name: NSNotification.Name("ChecklistTEDownloaded"), object: nil)
            } else {
                Logger.warning("Pas de checklist TE par défaut trouvée sur SharePoint", category: "Store")
            }
        } catch {
            Logger.error("Erreur lors du téléchargement de la checklist TE: \(error.localizedDescription)", category: "Store")
        }
    }
    
    /// Charge une checklist depuis le bundle de l'application ou le système de fichiers local
    /// - Parameter fileName: Le nom du fichier JSON à charger
    /// - Returns: La checklist chargée, ou nil si le fichier n'existe pas
    private func loadChecklistFromBundle(fileName: String) -> Checklist? {
        var url: URL?
        
        // Essayer d'abord depuis le bundle
        if let bundleURL = Bundle.main.url(forResource: fileName.replacingOccurrences(of: ".json", with: ""), withExtension: "json", subdirectory: "Checklists") {
            url = bundleURL
        } else {
            // Sinon, essayer depuis le système de fichiers local (pour le développement)
            // Chercher dans le dossier du projet
            let projectPath = "/Users/sylvaingallon/Desktop/Railskills rebuild/RailSkills/RailSkills/Checklists/\(fileName)"
            if FileManager.default.fileExists(atPath: projectPath) {
                url = URL(fileURLWithPath: projectPath)
            }
        }
        
        guard let fileURL = url else {
            Logger.debug("Fichier \(fileName) non trouvé dans le bundle ni dans le système de fichiers", category: "Store")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = jsonDecoder
            let checklist = try decoder.decode(Checklist.self, from: data)
            Logger.success("Checklist chargée depuis \(fileURL.lastPathComponent): \(checklist.title)", category: "Store")
            return checklist
        } catch {
            Logger.error("Erreur lors du chargement de la checklist depuis \(fileURL.path): \(error.localizedDescription)", category: "Store")
            return nil
        }
    }
    
    // MARK: - Téléchargement automatique des conducteurs
    
    /// Télécharge les conducteurs depuis SharePoint si aucun n'est présent localement
    /// Appelé automatiquement au démarrage si l'iPad n'a pas de conducteurs
    /// Cela permet de récupérer les conducteurs importés depuis le site web
    @MainActor
    func downloadDriversFromSharePointIfNeeded() async {
        // Ne rien faire si des conducteurs sont déjà présents
        guard drivers.isEmpty else {
            Logger.debug("Conducteurs déjà présents, pas de téléchargement", category: "Store")
            return
        }
        
        // Attendre un peu que l'app soit complètement initialisée
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
        
        // Vérifier si SharePoint est configuré
        guard SharePointSyncService.shared.isConfigured else {
            Logger.info("SharePoint non configuré, conducteurs ne seront pas téléchargés automatiquement", category: "Store")
            return
        }
        
        // Vérifier si le backend est accessible (si on utilise le backend)
        let backendAccessible = await BackendTokenService.shared.testBackendConnection()
        if !backendAccessible {
            Logger.warning("Backend inaccessible, tentative de téléchargement direct depuis SharePoint", category: "Store")
        }
        
        Logger.info("Téléchargement des conducteurs depuis SharePoint...", category: "Store")
        
        do {
            let downloadedDrivers = try await SharePointSyncService.shared.fetchDrivers()
            
            if !downloadedDrivers.isEmpty {
                // Sauvegarder les conducteurs téléchargés
                self.drivers = downloadedDrivers
                // Le didSet de drivers devrait appeler saveDriversDebounced automatiquement
                // Mais on force aussi une sauvegarde immédiate pour être sûr
                saveDrivers()
                Logger.success("\(downloadedDrivers.count) conducteur(s) téléchargé(s) depuis SharePoint et sauvegardé(s)", category: "Store")
                
                // Notifier que les conducteurs ont été téléchargés
                NotificationCenter.default.post(name: NSNotification.Name("DriversDownloaded"), object: nil)
            } else {
                Logger.info("Aucun conducteur trouvé sur SharePoint", category: "Store")
            }
        } catch {
            Logger.error("Erreur lors du téléchargement des conducteurs: \(error.localizedDescription)", category: "Store")
        }
    }
    
    /// Synchronise bidirectionnellement avec SharePoint pour récupérer les modifications depuis le site web
    /// Fusionne intelligemment les modifications locales et distantes
    /// - Note: Cette fonction peut être appelée manuellement ou périodiquement
    @MainActor
    func syncDriversBidirectional() async {
        guard sharePointService.isConfigured else {
            Logger.info("SharePoint non configuré, synchronisation impossible", category: "Store")
            return
        }
        
        guard !sharePointService.isSyncing else {
            Logger.debug("Synchronisation déjà en cours", category: "Store")
            return
        }
        
        Logger.info("Synchronisation bidirectionnelle avec SharePoint...", category: "Store")
        
        do {
            // 1. Récupérer les conducteurs depuis SharePoint
            let remoteDrivers = try await sharePointService.fetchDrivers()
            
            // 2. Créer un dictionnaire des conducteurs distants par ID
            let remoteDict = Dictionary(uniqueKeysWithValues: remoteDrivers.map { ($0.id, $0) })
            
            // 3. Fusionner avec les conducteurs locaux
            var updatedDrivers: [DriverRecord] = []
            var hasUpdates = false
            
            // Créer un dictionnaire des conducteurs locaux par ID pour vérification rapide
            let localDict = Dictionary(uniqueKeysWithValues: drivers.map { ($0.id, $0) })
            
            // Pour chaque conducteur local, vérifier s'il existe une version distante plus récente
            for localDriver in drivers {
                if let remoteDriver = remoteDict[localDriver.id] {
                    // Comparer les dates de dernière évaluation pour détecter les modifications
                    let localDate = localDriver.lastEvaluation ?? Date.distantPast
                    let remoteDate = remoteDriver.lastEvaluation ?? Date.distantPast
                    
                    if remoteDate > localDate {
                        // Version distante plus récente, fusionner intelligemment
                        let merged = sharePointService.mergeDriverRecords(local: localDriver, remote: remoteDriver)
                        updatedDrivers.append(merged)
                        hasUpdates = true
                        Logger.debug("Conducteur '\(localDriver.name)' mis à jour depuis SharePoint", category: "Store")
                    } else if localDate > remoteDate {
                        // Version locale plus récente, garder locale mais synchroniser vers SharePoint
                        updatedDrivers.append(localDriver)
                    } else {
                        // Dates identiques, fusionner quand même pour s'assurer que tout est à jour
                        let merged = sharePointService.mergeDriverRecords(local: localDriver, remote: remoteDriver)
                        updatedDrivers.append(merged)
                    }
                } else {
                    // Conducteur local n'existe pas sur SharePoint, garder local
                    updatedDrivers.append(localDriver)
                }
            }
            
            // 4. Ajouter les nouveaux conducteurs distants qui n'existent pas localement
            var newDriversCount = 0
            for remoteDriver in remoteDrivers {
                if localDict[remoteDriver.id] == nil {
                    // Nouveau conducteur depuis SharePoint, l'ajouter
                    updatedDrivers.append(remoteDriver)
                    hasUpdates = true
                    newDriversCount += 1
                    Logger.info("Nouveau conducteur '\(remoteDriver.name)' (ID: \(remoteDriver.id)) récupéré depuis SharePoint", category: "Store")
                }
            }
            
            Logger.info("Synchronisation: \(drivers.count) local(s), \(remoteDrivers.count) distant(s), \(newDriversCount) nouveau(x), \(updatedDrivers.count) total après fusion", category: "Store")
            
            // 5. Mettre à jour les conducteurs locaux avec les versions fusionnées
            // Toujours mettre à jour si le nombre a changé ou s'il y a des mises à jour
            let previousCount = drivers.count
            
            // Toujours mettre à jour pour s'assurer que les données fusionnées sont bien sauvegardées
            // Même si rien n'a changé visuellement, la fusion peut avoir modifié des détails
            self.drivers = updatedDrivers
            // Le didSet de drivers devrait appeler saveDriversDebounced automatiquement
            // Mais on force aussi une sauvegarde immédiate pour être sûr
            saveDrivers()
            
            if hasUpdates || updatedDrivers.count != previousCount {
                Logger.success("Synchronisation bidirectionnelle réussie - \(updatedDrivers.count - previousCount) nouveau(x) conducteur(s) ajouté(s) (avant: \(previousCount), après: \(updatedDrivers.count))", category: "Store")
            } else {
                Logger.info("Synchronisation bidirectionnelle complétée - données fusionnées et sauvegardées (local: \(previousCount), distant: \(remoteDrivers.count), fusionné: \(updatedDrivers.count))", category: "Store")
            }
            
            // Notifier les modifications
            NotificationCenter.default.post(
                name: NSNotification.Name("DriversUpdatedFromSharePoint"),
                object: nil
            )
            
            // 6. Synchroniser les modifications locales vers SharePoint
            try await sharePointService.syncDrivers(updatedDrivers)
            Logger.success("Synchronisation bidirectionnelle complète", category: "Store")
            
        } catch {
            Logger.error("Erreur lors de la synchronisation bidirectionnelle: \(error.localizedDescription)", category: "Store")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Chargement des données
    
    /// Charge les données des conducteurs depuis UserDefaults
    private func loadDrivers() {
        guard !driversData.isEmpty else { return }
        do {
            drivers = try jsonDecoder.decode([DriverRecord].self, from: driversData)
        } catch {
            Logger.error("Erreur de décodage des conducteurs: \(error.localizedDescription)", category: "Store")
            // Tentative de récupération : migrer les anciennes données vers la nouvelle structure
            Logger.warning("Tentative de migration des données (ajout du champ checklistDates)...", category: "Store")
            do {
                // Décoder en tant que dictionnaire pour pouvoir ajouter le champ manquant
                if let jsonArray = try JSONSerialization.jsonObject(with: driversData) as? [[String: Any]] {
                    var recoveredDrivers: [DriverRecord] = []
                    for driverDict in jsonArray {
                        var modifiedDict = driverDict
                        // Ajouter checklistDates si manquant (structure vide)
                        if modifiedDict["checklistDates"] == nil {
                            modifiedDict["checklistDates"] = [:] as [String: Any]
                        }
                        
                        // Réencoder en JSON avec le nouveau champ
                        let modifiedData = try JSONSerialization.data(withJSONObject: modifiedDict, options: [.sortedKeys])
                        
                        // Décoder avec la structure complète
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let driver = try decoder.decode(DriverRecord.self, from: modifiedData)
                        recoveredDrivers.append(driver)
                    }
                    drivers = recoveredDrivers
                    // Sauvegarder les données migrées
                    saveDrivers()
                    Logger.success("Données migrées avec succès (\(recoveredDrivers.count) conducteur(s))", category: "Store")
                } else {
                    // Si tout échoue, réinitialiser
                    Logger.warning("Impossible de récupérer les données, réinitialisation...", category: "Store")
                    drivers = []
                    driversData = Data()
                }
            } catch {
                // Si la récupération échoue aussi, réinitialiser
                Logger.error("Échec de la migration, réinitialisation des données: \(error.localizedDescription)", category: "Store")
                drivers = []
                driversData = Data()
            }
        }
    }
    
    /// Charge la checklist depuis UserDefaults
    /// Ne charge que si des données ont été sauvegardées (après un import)
    private func loadChecklist() {
        guard !lastChecklistData.isEmpty else {
            // Aucune checklist sauvegardée - l'application démarre vierge
            checklist = nil
            return
        }
        do {
            let decodedChecklist = try jsonDecoder.decode(Checklist.self, from: lastChecklistData)
            // Ne charger que si la checklist contient des éléments
            if decodedChecklist.items.isEmpty {
                Logger.warning("Checklist vide détectée lors du chargement, réinitialisation", category: "Store")
                checklist = nil
                lastChecklistData = Data()
            } else {
                checklist = decodedChecklist
                Logger.success("Checklist chargée: \(decodedChecklist.title) avec \(decodedChecklist.items.count) éléments", category: "Store")
            }
        } catch {
            Logger.error("Erreur de décodage de la checklist: \(error.localizedDescription)", category: "Store")
            // En cas d'erreur, réinitialiser pour éviter un état corrompu
            checklist = nil
            lastChecklistData = Data()
        }
    }
    
    /// Charge la checklist VP depuis UserDefaults
    private func loadChecklistVP() {
        guard !lastChecklistVPData.isEmpty else {
            checklistVP = nil
            return
        }
        do {
            let decodedChecklist = try jsonDecoder.decode(Checklist.self, from: lastChecklistVPData)
            if decodedChecklist.items.isEmpty {
                Logger.warning("Checklist VP vide détectée lors du chargement, réinitialisation", category: "Store")
                checklistVP = nil
                lastChecklistVPData = Data()
            } else {
                checklistVP = decodedChecklist
                Logger.success("Checklist VP chargée: \(decodedChecklist.title) avec \(decodedChecklist.items.count) éléments", category: "Store")
            }
        } catch {
            Logger.error("Erreur de décodage de la checklist VP: \(error.localizedDescription)", category: "Store")
            checklistVP = nil
            lastChecklistVPData = Data()
        }
    }
    
    /// Charge la checklist TE depuis UserDefaults
    private func loadChecklistTE() {
        guard !lastChecklistTEData.isEmpty else {
            checklistTE = nil
            return
        }
        do {
            let decodedChecklist = try jsonDecoder.decode(Checklist.self, from: lastChecklistTEData)
            if decodedChecklist.items.isEmpty {
                Logger.warning("Checklist TE vide détectée lors du chargement, réinitialisation", category: "Store")
                checklistTE = nil
                lastChecklistTEData = Data()
            } else {
                checklistTE = decodedChecklist
                Logger.success("Checklist TE chargée: \(decodedChecklist.title) avec \(decodedChecklist.items.count) éléments", category: "Store")
            }
        } catch {
            Logger.error("Erreur de décodage de la checklist TE: \(error.localizedDescription)", category: "Store")
            checklistTE = nil
            lastChecklistTEData = Data()
        }
    }
    
    // MARK: - Sauvegarde des données
    
    // Système de débouncing pour éviter les sauvegardes excessives
    private func saveDriversDebounced() {
        isSaving = true
        saveCancellable?.cancel()
        saveCancellable = Just(())
            .delay(for: .seconds(AppConstants.Debounce.saveDelay), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveDrivers()
                self?.isSaving = false
            }
    }
    
    /// Sauvegarde les données des conducteurs dans UserDefaults
    private func saveDrivers() {
        do {
            let data = try jsonEncoder.encode(drivers)
            driversData = data
            Logger.debug("\(drivers.count) conducteur(s) sauvegardé(s) avec succès", category: "Store")
        } catch {
            Logger.error("Erreur d'encodage des conducteurs: \(error.localizedDescription)", category: "Store")
        }
    }
    
    // Système de débouncing pour la sauvegarde de la checklist
    private func saveChecklistDebounced() {
        isSaving = true
        saveCancellable?.cancel()
        saveCancellable = Just(())
            .delay(for: .seconds(AppConstants.Debounce.saveDelay), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveChecklist()
                self?.isSaving = false
            }
    }
    
    /// Sauvegarde la checklist dans UserDefaults
    /// La checklist n'est sauvegardée que si elle a été importée ou créée par l'utilisateur
    private func saveChecklist() {
        guard let checklist = checklist else {
            // Si la checklist est nil, effacer les données sauvegardées
            lastChecklistData = Data()
            return
        }
        do {
            let data = try jsonEncoder.encode(checklist)
            lastChecklistData = data
            Logger.success("Checklist sauvegardée: \(checklist.title) avec \(checklist.items.count) éléments", category: "Store")
        } catch {
            Logger.error("Erreur d'encodage de la checklist: \(error.localizedDescription)", category: "Store")
        }
    }
    
    /// Sauvegarde la checklist VP dans UserDefaults
    private func saveChecklistVP() {
        guard let checklist = checklistVP else {
            lastChecklistVPData = Data()
            return
        }
        do {
            let data = try jsonEncoder.encode(checklist)
            lastChecklistVPData = data
            Logger.success("Checklist VP sauvegardée: \(checklist.title) avec \(checklist.items.count) éléments", category: "Store")
        } catch {
            Logger.error("Erreur d'encodage de la checklist VP: \(error.localizedDescription)", category: "Store")
        }
    }
    
    /// Sauvegarde la checklist TE dans UserDefaults
    private func saveChecklistTE() {
        guard let checklist = checklistTE else {
            lastChecklistTEData = Data()
            return
        }
        do {
            let data = try jsonEncoder.encode(checklist)
            lastChecklistTEData = data
            Logger.success("Checklist TE sauvegardée: \(checklist.title) avec \(checklist.items.count) éléments", category: "Store")
        } catch {
            Logger.error("Erreur d'encodage de la checklist TE: \(error.localizedDescription)", category: "Store")
        }
    }
    
    // Système de débouncing pour la sauvegarde de la checklist VP
    private func saveChecklistVPDebounced() {
        isSaving = true
        saveCancellable?.cancel()
        saveCancellable = Just(())
            .delay(for: .seconds(AppConstants.Debounce.saveDelay), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveChecklistVP()
                self?.isSaving = false
            }
    }
    
    // Système de débouncing pour la sauvegarde de la checklist TE
    private func saveChecklistTEDebounced() {
        isSaving = true
        saveCancellable?.cancel()
        saveCancellable = Just(())
            .delay(for: .seconds(AppConstants.Debounce.saveDelay), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveChecklistTE()
                self?.isSaving = false
            }
    }
    
    // MARK: - Gestion de version
    
    /// Marque la version actuelle de la checklist comme appliquée (pour éviter les migrations futures)
    func markChecklistVersionCurrent() {
        // La version est maintenant gérée dynamiquement via le titre de la checklist
        if let checklist = checklist {
            appliedChecklistVersion = checklist.title
        }
    }
    
    // MARK: - Réinitialisation
    
    /// Réinitialise complètement l'application (supprime toutes les données)
    /// Utile pour tester une première utilisation ou réinitialiser l'application
    func resetAllData() {
        checklist = nil
        checklistVP = nil
        checklistTE = nil
        drivers = []
        lastChecklistData = Data()
        lastChecklistVPData = Data()
        lastChecklistTEData = Data()
        driversData = Data()
        appliedChecklistVersion = ""
    }
    
    /// Désactive temporairement la synchronisation automatique (pour les suppressions)
    /// - Parameter completion: Closure à exécuter pendant que la synchronisation est désactivée
    func withSyncDisabled<T>(_ completion: () throws -> T) rethrows -> T {
        let previousValue = isDeletingDrivers
        isDeletingDrivers = true
        defer {
            isDeletingDrivers = previousValue
        }
        return try completion()
    }
    
    /// Désactive temporairement la synchronisation automatique (version async)
    /// - Parameter completion: Closure async à exécuter pendant que la synchronisation est désactivée
    func withSyncDisabled<T>(_ completion: () async throws -> T) async rethrows -> T {
        let previousValue = isDeletingDrivers
        isDeletingDrivers = true
        defer {
            isDeletingDrivers = previousValue
        }
        return try await completion()
    }
    
    /// Supprime uniquement la checklist (sans supprimer les conducteurs)
    /// Utile pour réimporter une nouvelle checklist
    func removeChecklistOnly() {
        checklist = nil
        lastChecklistData = Data()
    }
    
    // MARK: - Synchronisation SharePoint automatique
    
    /// Synchronise les conducteurs vers SharePoint avec débouncing (utilisé par didSet)
    /// Les erreurs sont loggées silencieusement pour ne pas interrompre l'expérience utilisateur
    private func syncDriversToSharePointDebounced() {
        guard sharePointAutoSyncEnabled && sharePointService.isConfigured && !drivers.isEmpty else { return }
        sharePointSyncCancellable?.cancel()
        sharePointSyncCancellable = Just(())
            .delay(for: .seconds(AppConstants.Debounce.sharePointSyncDelay), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.syncDriversToSharePoint()
                }
            }
    }
    
    /// Synchronise les conducteurs vers SharePoint (méthode interne)
    /// Les erreurs sont loggées mais n'interrompent pas l'expérience utilisateur
    private func syncDriversToSharePoint() async {
        guard sharePointAutoSyncEnabled && sharePointService.isConfigured && !drivers.isEmpty else { return }
        
        // Ne pas synchroniser si une synchronisation est déjà en cours
        guard !sharePointService.isSyncing else {
            Logger.debug("Synchronisation SharePoint déjà en cours, ignorée", category: "Store")
            return
        }
        
        do {
            try await sharePointService.syncDrivers(drivers)
            Logger.success("\(drivers.count) conducteur(s) synchronisé(s) automatiquement vers SharePoint", category: "Store")
        } catch {
            // Logger l'erreur mais ne pas interrompre l'utilisateur
            Logger.warning("Erreur lors de la synchronisation automatique des conducteurs vers SharePoint: \(error.localizedDescription)", category: "Store")
        }
    }
    
    /// Synchronise la checklist vers SharePoint avec débouncing (utilisé par didSet)
    /// Les erreurs sont loggées silencieusement pour ne pas interrompre l'expérience utilisateur
    private func syncChecklistToSharePointDebounced() {
        guard sharePointAutoSyncEnabled && sharePointService.isConfigured && checklist != nil else { return }
        sharePointSyncCancellable?.cancel()
        sharePointSyncCancellable = Just(())
            .delay(for: .seconds(AppConstants.Debounce.sharePointSyncDelay), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.syncChecklistToSharePoint()
                }
            }
    }
    
    /// Synchronise la checklist vers SharePoint (méthode interne)
    /// Les erreurs sont loggées mais n'interrompent pas l'expérience utilisateur
    private func syncChecklistToSharePoint() async {
        guard sharePointAutoSyncEnabled && sharePointService.isConfigured,
              let currentChecklist = checklist else { return }
        
        // Ne pas synchroniser si une synchronisation est déjà en cours
        guard !sharePointService.isSyncing else {
            Logger.debug("Synchronisation SharePoint déjà en cours, ignorée", category: "Store")
            return
        }
        
        do {
            try await sharePointService.syncChecklist(currentChecklist)
            Logger.success("Checklist '\(currentChecklist.title)' synchronisée automatiquement vers SharePoint", category: "Store")
        } catch {
            // Logger l'erreur mais ne pas interrompre l'utilisateur
            Logger.warning("Erreur lors de la synchronisation automatique de la checklist vers SharePoint: \(error.localizedDescription)", category: "Store")
        }
    }
    
    /// Synchronise la checklist VP vers SharePoint avec débouncing
    private func syncChecklistVPToSharePointDebounced() {
        guard sharePointAutoSyncEnabled && sharePointService.isConfigured && checklistVP != nil else { return }
        sharePointSyncCancellable?.cancel()
        sharePointSyncCancellable = Just(())
            .delay(for: .seconds(AppConstants.Debounce.sharePointSyncDelay), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.syncChecklistVPToSharePoint()
                }
            }
    }
    
    /// Synchronise la checklist VP vers SharePoint (méthode interne)
    private func syncChecklistVPToSharePoint() async {
        guard sharePointAutoSyncEnabled && sharePointService.isConfigured,
              let currentChecklist = checklistVP else { return }
        
        guard !sharePointService.isSyncing else {
            Logger.debug("Synchronisation SharePoint déjà en cours, ignorée", category: "Store")
            return
        }
        
        do {
            try await sharePointService.syncChecklist(currentChecklist)
            Logger.success("Checklist VP '\(currentChecklist.title)' synchronisée automatiquement vers SharePoint", category: "Store")
        } catch {
            Logger.warning("Erreur lors de la synchronisation automatique de la checklist VP vers SharePoint: \(error.localizedDescription)", category: "Store")
        }
    }
    
    /// Synchronise la checklist TE vers SharePoint avec débouncing
    private func syncChecklistTEToSharePointDebounced() {
        guard sharePointAutoSyncEnabled && sharePointService.isConfigured && checklistTE != nil else { return }
        sharePointSyncCancellable?.cancel()
        sharePointSyncCancellable = Just(())
            .delay(for: .seconds(AppConstants.Debounce.sharePointSyncDelay), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.syncChecklistTEToSharePoint()
                }
            }
    }
    
    /// Synchronise la checklist TE vers SharePoint (méthode interne)
    private func syncChecklistTEToSharePoint() async {
        guard sharePointAutoSyncEnabled && sharePointService.isConfigured,
              let currentChecklist = checklistTE else { return }
        
        guard !sharePointService.isSyncing else {
            Logger.debug("Synchronisation SharePoint déjà en cours, ignorée", category: "Store")
            return
        }
        
        do {
            try await sharePointService.syncChecklist(currentChecklist)
            Logger.success("Checklist TE '\(currentChecklist.title)' synchronisée automatiquement vers SharePoint", category: "Store")
        } catch {
            Logger.warning("Erreur lors de la synchronisation automatique de la checklist TE vers SharePoint: \(error.localizedDescription)", category: "Store")
        }
    }
}

