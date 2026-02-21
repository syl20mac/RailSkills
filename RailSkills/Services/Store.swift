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
    @AppStorage("personalChecklistItemIDs") private var personalChecklistItemIDsData: Data = Data()
    
    // Service SharePoint pour la synchronisation automatique
    private let sharePointService = SharePointSyncService.shared
    
    // Progression de la synchronisation
    @Published var isSyncing: Bool = false
    @Published var syncProgress: Double = 0.0
    @Published var syncStatusMessage: String = ""
    
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
            updateSearchIndex()
        }
    }
    
    // Checklists séparées par type
    @Published var checklistTriennale: Checklist? {
        didSet { 
            saveChecklistDebounced()
            if sharePointAutoSyncEnabled && sharePointService.isConfigured, checklistTriennale != nil {
                syncChecklistToSharePointDebounced()
            }
            updateSearchIndex()
        }
    }
    
    @Published var checklistVP: Checklist? {
        didSet { 
            saveChecklistDebounced()
            updateSearchIndex()
        }
    }
    
    @Published var checklistTE: Checklist? {
        didSet { 
            saveChecklistDebounced()
            updateSearchIndex()
        }
    }
    
    // Checklists Suivi disponibles (pour sélection)
    @Published var availableSuiviChecklists: [Checklist] = []
    @AppStorage("preferredSuiviChecklistTitle") private var preferredSuiviChecklistTitle: String = ""
    
    /// Type de checklist actuellement sélectionné pour l'édition/affichage
    @Published var selectedChecklistType: ChecklistType = .triennale
    
    /// Propriété de compatibilité - retourne la checklist active selon le type sélectionné
    var checklist: Checklist? {
        get {
            switch selectedChecklistType {
            case .triennale: return checklistTriennale
            case .vp: return checklistVP
            case .te: return checklistTE
            }
        }
        set {
            switch selectedChecklistType {
            case .triennale: checklistTriennale = newValue
            case .vp: checklistVP = newValue
            case .te: checklistTE = newValue
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
    // - Ces propriétés filtraient auparavant les données par identité via OrganizationIdentityService
    // - L'application fonctionne désormais sur un jeu de données global pour l'utilisateur courant (Local ou Entreprise)
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
    
    private var saveDriversCancellable: AnyCancellable?
    private var saveChecklistCancellable: AnyCancellable?
    private var sharePointSyncCancellable: AnyCancellable?
    
    init() {
        // Charger les données depuis UserDefaults
        loadDrivers()
        loadChecklist()
        
        // Si pas de checklists locales, essayer d'abord de charger depuis le Bundle (Mode Local)
        loadBundledChecklists()
        
        // Si toujours manquantes et SharePoint configuré, tenter de télécharger
        // Toujours tenter de mettre à jour les checklists au démarrage si SharePoint est configuré
        if SharePointSyncService.shared.isConfigured {
            Logger.info("Mise à jour des checklists au démarrage...", category: "Store")
            Task {
                await self.downloadAllChecklistsIfNeeded()
            }
        } else {
            Logger.info("Mode Local : utilisation des checklists locales", category: "Store")
        }
        
        Logger.info("\(drivers.count) conducteur(s) présent(s) localement", category: "Store")
        
        // Synchroniser les conducteurs au démarrage si SharePoint est configuré
        // On force la synchronisation pour être sûr d'avoir les dernières modifications
        if SharePointSyncService.shared.isConfigured {
            Task {
                _ = try? await self.syncDriversBidirectional()
            }
        }
    }
    
    // MARK: - Téléchargement automatique des checklists
    
    /// Télécharge toutes les checklists manquantes depuis SharePoint
    /// Appelé automatiquement au démarrage si des checklists sont manquantes
    @MainActor
    func downloadAllChecklistsIfNeeded() async {
        // Attendre un peu que l'app soit complètement initialisée
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
        
        // Vérifier si SharePoint est configuré
        guard SharePointSyncService.shared.isConfigured else {
            Logger.info("SharePoint non configuré, checklists ne seront pas téléchargées automatiquement", category: "Store")
            return
        }
        
        // Check SharePoint configuration
        // Note: We don't check BackendTokenService.shared.testBackendConnection() here anymore
        // because SharePoint access (via generic Graph API) should not be blocked by custom backend availability.
        
        Logger.info("Téléchargement des checklists (globales + locales) depuis SharePoint...", category: "Store")
        
        do {
            let mergedChecklists = try await SharePointSyncService.shared.fetchAllChecklists()
            applyMergedChecklists(mergedChecklists)
            saveChecklists()
            NotificationCenter.default.post(name: NSNotification.Name("ChecklistDownloaded"), object: nil)
        } catch {
            Logger.error("Erreur lors du téléchargement des checklists: \(error)", category: "Store")
        }
    }
    
    /// Charge les checklists depuis le Bundle (fichiers inclus dans l'app)
    /// Utilisé comme fallback pour le mode local
    private func loadBundledChecklists() {
        Logger.info("Tentative de chargement des checklists incluses (Bundle)...", category: "Store")
        
        // Helper pour charger un fichier
        func loadFromBundle(filename: String) -> Checklist? {
            guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
                Logger.warning("Fichier \(filename).json non trouvé dans le Bundle", category: "Store")
                return nil
            }
            
            do {
                let data = try Data(contentsOf: url)
                var checklist = try jsonDecoder.decode(Checklist.self, from: data)
                checklist = markChecklistReadOnly(checklist)
                Logger.success("Checklist bundle chargée: \(checklist.title)", category: "Store")
                return checklist
            } catch {
                Logger.error("Erreur chargement bundle \(filename): \(error)", category: "Store")
                return nil
            }
        }
        
        // 1. Checklist VP
        if checklistVP == nil {
            checklistVP = loadFromBundle(filename: "questions_VP")
        }
        
        // 2. Checklist TE
        if checklistTE == nil {
            checklistTE = loadFromBundle(filename: "questions_TE")
        }
        
        // 3. Checklist Triennale (CFL)
        // Note: Le fichier s'appelle souvent questions_CFL sur SharePoint
        if checklistTriennale == nil {
            checklistTriennale = loadFromBundle(filename: "questions_TE") // Fallback temporaire ou chercher questions_CFL
            // On essaie de charger TE faute de mieux si CFL n'est pas là, ou on laisse nil
        }
        
        saveChecklists()
    }
    
    /// Force le téléchargement de la checklist depuis SharePoint
    /// Appelé manuellement par l'utilisateur si besoin
    @MainActor
    func forceDownloadChecklist() async -> Bool {
        Logger.info("Téléchargement forcé des checklists depuis SharePoint...", category: "Store")
        
        guard SharePointSyncService.shared.isConfigured else {
            Logger.error("SharePoint non configuré", category: "Store")
            return false
        }
        
        do {
            let mergedChecklists = try await SharePointSyncService.shared.fetchAllChecklists()
            applyMergedChecklists(mergedChecklists)
            saveChecklists()
            Logger.success("Checklists téléchargées: \(mergedChecklists.count)", category: "Store")
            return !mergedChecklists.isEmpty
        } catch {
            Logger.error("Erreur: \(error.localizedDescription)", category: "Store")
            return false
        }
    }

    // MARK: - Helpers Checklists (Global + Local)

    private func applyMergedChecklists(_ checklists: [Checklist]) {
        var triennale: Checklist?
        var vp: Checklist?
        var te: Checklist?

        // 1. Priorité aux checklists avec type explicite
        for checklist in checklists where !(checklist.type?.isEmpty ?? true) {
            switch resolveChecklistType(for: checklist) {
            case .triennale where triennale == nil:
                triennale = checklist
            case .vp where vp == nil:
                vp = checklist
            case .te where te == nil:
                te = checklist
            default:
                continue
            }
        }

        // 2. Fallback par titre si un type manque
        for checklist in checklists {
            switch resolveChecklistType(for: checklist) {
            case .triennale where triennale == nil:
                triennale = checklist
            case .vp where vp == nil:
                vp = checklist
            case .te where te == nil:
                te = checklist
            default:
                continue
            }
        }

        if let triennale {
            checklistTriennale = triennale
        }
        if let vp {
            checklistVP = vp
        }
        if let te {
            checklistTE = te
        }
    }

    private func resolveChecklistType(for checklist: Checklist) -> ChecklistType? {
        if let rawType = checklist.type?.lowercased() {
            if rawType.contains("triennale") || rawType.contains("cfl") {
                return .triennale
            }
            if rawType.contains("vp") {
                return .vp
            }
            if rawType.contains("te") {
                return .te
            }
        }

        let title = checklist.title.lowercased()

        if title.contains("validation périodique") || title.contains("validation periodique") || title.contains("visite périodique") || title.contains("visite periodique") || title == "vp" || title.contains(" vp ") || title.hasPrefix("vp ") || title.hasSuffix(" vp") {
            return .vp
        }

        if title.contains("train d'essai") || title.contains("train d’essai") || title.contains("triennale elargie") || title.contains("triennale élargie") || title == "te" || title.contains(" te ") || title.hasPrefix("te ") || title.hasSuffix(" te") {
            return .te
        }

        // 3. Triennale / Suivi / CFL
        // Note: Accepte aussi "Checklist Importée" (généré par l'import Excel)
        if title.contains("triennale") || title.contains("cfl") || title.contains("suivi") || title.contains("importée") || title.contains("classification") {
            return .triennale
        }

        return nil
    }

    private func markChecklistReadOnly(_ checklist: Checklist) -> Checklist {
        var updated = checklist
        updated.items = checklist.items.map { item in
            var mutable = item
            mutable.readOnly = true
            return mutable
        }
        return updated
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
                saveDrivers()
                Logger.success("\(downloadedDrivers.count) conducteur(s) téléchargé(s) depuis SharePoint", category: "Store")
                
                // Notifier que les conducteurs ont été téléchargés
                NotificationCenter.default.post(name: NSNotification.Name("DriversDownloaded"), object: nil)
            } else {
                Logger.info("Aucun conducteur trouvé sur SharePoint", category: "Store")
            }
        } catch {
            Logger.error("Erreur lors du téléchargement des conducteurs: \(error.localizedDescription)", category: "Store")
        }
    }
    
    /// Sélectionne une checklist Suivi spécifique par son titre
    /// - Parameter title: Le titre de la checklist à sélectionner
    func selectSuiviChecklist(_ title: String) {
        if let found = availableSuiviChecklists.first(where: { $0.title == title }) {
            self.checklistTriennale = found
            self.preferredSuiviChecklistTitle = title
            Logger.info("Utilisateur a changé le suivi actif pour : \(title)", category: "Store")
        }
    }
    
    /// Synchronise bidirectionnellement avec SharePoint pour récupérer les modifications depuis le site web
    /// Fusionne intelligemment les modifications locales et distantes
    /// - Returns: Une chaîne de caractères détaillant le résultat de la synchronisation (debug info)
    @MainActor
    @discardableResult
    func syncDriversBidirectional() async throws -> String {
        guard sharePointService.isConfigured else {
            Logger.info("SharePoint non configuré, synchronisation impossible", category: "Store")
            throw SharePointSyncError.notConfigured
        }
        
        guard !sharePointService.isSyncing else {
            Logger.debug("Synchronisation déjà en cours", category: "Store")
            return "Synchronisation déjà en cours"
        }
        
        // Démarrer la synchronisation
        await MainActor.run {
            isSyncing = true
            syncProgress = 0.0
            syncStatusMessage = "Connexion à SharePoint..."
        }
        
        Logger.info("Synchronisation bidirectionnelle avec SharePoint...", category: "Store")
        
        // RECUPERATION DU DOSSIER CIBLE (DEBUG)
        // On récupère le chemin que le service va utiliser pour le debug
        let _ = sharePointService.getCTTFolderName() // Appel pour vérification de l'état (optionnel)
        // Note: Si getCTTFolderName n'est pas accessible ici, on se fiera au résultat.
        
        // 1. Récupérer les conducteurs depuis SharePoint
        await MainActor.run {
            syncProgress = 0.2
            syncStatusMessage = "Récupération des conducteurs..."
        }
        let remoteDrivers = try await sharePointService.fetchDrivers()

        
        // 2. Créer un dictionnaire des conducteurs distants par ID (gère les doublons)
        var remoteDict: [UUID: DriverRecord] = [:]
        for driver in remoteDrivers {
            remoteDict[driver.id] = driver
        }
        
        // 3. Fusionner avec les conducteurs locaux
        var updatedDrivers: [DriverRecord] = []
        var hasUpdates = false
        var needsUpload = false
        
        // Créer un dictionnaire des conducteurs locaux par ID pour vérification rapide (gère les doublons)
        var localDict: [UUID: DriverRecord] = [:]
        for driver in drivers {
            localDict[driver.id] = driver
        }
        
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
                    needsUpload = true
                } else {
                    // Dates identiques, fusionner quand même pour s'assurer que tout est à jour
                    let merged = sharePointService.mergeDriverRecords(local: localDriver, remote: remoteDriver)
                    updatedDrivers.append(merged)
                }
            } else {
                // Conducteur local n'existe pas sur SharePoint, garder local
                updatedDrivers.append(localDriver)
                needsUpload = true
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
        if hasUpdates || updatedDrivers.count != drivers.count {
            let previousCount = drivers.count
            self.drivers = updatedDrivers
            saveDrivers()
            Logger.success("Synchronisation bidirectionnelle réussie - \(updatedDrivers.count - previousCount) nouveau(x) conducteur(s) ajouté(s) (avant: \(previousCount), après: \(updatedDrivers.count))", category: "Store")
            
            // Notifier les modifications
            NotificationCenter.default.post(
                name: NSNotification.Name("DriversUpdatedFromSharePoint"),
                object: nil
            )
        } else {
            Logger.info("Aucune modification détectée depuis SharePoint (local: \(drivers.count), distant: \(remoteDrivers.count), fusionné: \(updatedDrivers.count))", category: "Store")
        }
        
        // 6. Synchroniser les modifications locales vers SharePoint (uniquement si nécessaire)
        if needsUpload {
            await MainActor.run {
                syncProgress = 0.9
                syncStatusMessage = "Envoi vers SharePoint..."
            }
            try await sharePointService.syncDrivers(updatedDrivers)
            Logger.success("Synchronisation bidirectionnelle complète", category: "Store")
        } else {
            Logger.info("Aucune modification locale à envoyer vers SharePoint", category: "Store")
        }
        
        // Terminer la synchronisation
        await MainActor.run {
            syncProgress = 1.0
            syncStatusMessage = "Synchronisation terminée !"
            sharePointService.lastSyncDate = Date()
            // Réinitialiser après un court délai
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes
                await MainActor.run {
                    isSyncing = false
                    syncProgress = 0.0
                    syncStatusMessage = ""
                }
            }
        }
        
        return "Succès !\nRemote trouvés: \(remoteDrivers.count)\nNouveaux ajoutés: \(newDriversCount)\nTotal final: \(updatedDrivers.count)\nDossier CTT visé: \(sharePointService.getCTTFolderName())"
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
    
    /// Charge les checklists depuis UserDefaults
    /// Charge les trois types de checklists séparément
    private func loadChecklist() {
        // Charger la checklist Triennale
        if !lastChecklistData.isEmpty {
            do {
                let decodedChecklist = try jsonDecoder.decode(Checklist.self, from: lastChecklistData)
                if decodedChecklist.items.isEmpty {
                    Logger.warning("Checklist Triennale vide détectée lors du chargement", category: "Store")
                    checklistTriennale = nil
                    lastChecklistData = Data()
                } else {
                    checklistTriennale = decodedChecklist
                    Logger.success("Checklist Triennale chargée: \(decodedChecklist.title) avec \(decodedChecklist.items.count) éléments", category: "Store")
                }
            } catch {
                Logger.error("Erreur de décodage de la checklist Triennale: \(error.localizedDescription)", category: "Store")
                checklistTriennale = nil
                lastChecklistData = Data()
            }
        }
        
        // Charger la checklist VP
        if !lastChecklistVPData.isEmpty {
            do {
                let decodedChecklist = try jsonDecoder.decode(Checklist.self, from: lastChecklistVPData)
                if decodedChecklist.items.isEmpty {
                    Logger.warning("Checklist VP vide détectée lors du chargement", category: "Store")
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
        
        // Charger la checklist TE
        if !lastChecklistTEData.isEmpty {
            do {
                let decodedChecklist = try jsonDecoder.decode(Checklist.self, from: lastChecklistTEData)
                if decodedChecklist.items.isEmpty {
                    Logger.warning("Checklist TE vide détectée lors du chargement", category: "Store")
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

        // Migration readOnly: utiliser les checklists du Bundle comme référence
        // pour verrouiller les questions d'origine sans toucher aux questions personnelles.
        applyReadOnlyFromBundleReferenceIfNeeded()
        
        // Si des items n'ont toujours pas de readOnly, tenter un refresh depuis SharePoint
        // pour récupérer la version fusionnée avec readOnly.
        if needsReadOnlyMigrationFromSharePoint(), SharePointSyncService.shared.isConfigured {
            Task {
                await refreshMergedChecklistsForReadOnlyMigration()
            }
        }
    }

    /// Marque en readOnly les items qui existent dans les checklists du Bundle.
    /// Utile pour les données historiques où readOnly n'était pas stocké.
    private func applyReadOnlyFromBundleReferenceIfNeeded() {
        // Charger les checklists de référence depuis le bundle
        func loadBundleChecklist(filename: String) -> Checklist? {
            guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
                return nil
            }
            return try? jsonDecoder.decode(Checklist.self, from: Data(contentsOf: url))
        }
        
        let bundleVP = loadBundleChecklist(filename: "questions_VP")
        let bundleTE = loadBundleChecklist(filename: "questions_TE")
        let bundleTriennale = loadBundleChecklist(filename: "questions_CFL") ?? loadBundleChecklist(filename: "questions_TE")
        
        let vpTitles = Set((bundleVP?.items ?? []).map { normalizeTitle($0.title) })
        let teTitles = Set((bundleTE?.items ?? []).map { normalizeTitle($0.title) })
        let triennaleTitles = Set((bundleTriennale?.items ?? []).map { normalizeTitle($0.title) })
        
        var didChange = false
        
        if var checklist = checklistVP {
            let newItems = checklist.items.map { item -> ChecklistItem in
                var updated = item
                if updated.readOnly == nil {
                    updated.readOnly = vpTitles.contains(normalizeTitle(updated.title))
                    if updated.readOnly != item.readOnly { didChange = true }
                }
                return updated
            }
            checklist.items = newItems
            checklistVP = checklist
        }
        
        if var checklist = checklistTE {
            let newItems = checklist.items.map { item -> ChecklistItem in
                var updated = item
                if updated.readOnly == nil {
                    updated.readOnly = teTitles.contains(normalizeTitle(updated.title))
                    if updated.readOnly != item.readOnly { didChange = true }
                }
                return updated
            }
            checklist.items = newItems
            checklistTE = checklist
        }
        
        if var checklist = checklistTriennale {
            let newItems = checklist.items.map { item -> ChecklistItem in
                var updated = item
                if updated.readOnly == nil {
                    updated.readOnly = triennaleTitles.contains(normalizeTitle(updated.title))
                    if updated.readOnly != item.readOnly { didChange = true }
                }
                return updated
            }
            checklist.items = newItems
            checklistTriennale = checklist
        }
        
        if didChange {
            saveChecklists()
            Logger.info("Migration readOnly appliquée via références Bundle", category: "Store")
        }
    }
    
    private func normalizeTitle(_ title: String) -> String {
        let folded = title.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let cleaned = folded.replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var bundleTitlesCache: (vp: Set<String>, te: Set<String>, triennale: Set<String>)?
    private var personalChecklistItemIDs: Set<UUID> = []
    
    private func loadBundleTitlesCache() -> (vp: Set<String>, te: Set<String>, triennale: Set<String>) {
        if let cached = bundleTitlesCache {
            return cached
        }
        
        func loadBundleChecklist(filename: String) -> Checklist? {
            guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
                return nil
            }
            return try? jsonDecoder.decode(Checklist.self, from: Data(contentsOf: url))
        }
        
        let bundleVP = loadBundleChecklist(filename: "questions_VP")
        let bundleTE = loadBundleChecklist(filename: "questions_TE")
        let bundleTriennale = loadBundleChecklist(filename: "questions_CFL") ?? loadBundleChecklist(filename: "questions_TE")
        
        let cache = (
            vp: Set((bundleVP?.items ?? []).map { normalizeTitle($0.title) }),
            te: Set((bundleTE?.items ?? []).map { normalizeTitle($0.title) }),
            triennale: Set((bundleTriennale?.items ?? []).map { normalizeTitle($0.title) })
        )
        
        bundleTitlesCache = cache
        return cache
    }
    
    /// Détermine si un item doit être traité en lecture seule (fallback basé sur le bundle).
    func isItemReadOnly(_ item: ChecklistItem) -> Bool {
        if item.readOnly == true {
            return true
        }
        if personalChecklistItemIDs.isEmpty && !personalChecklistItemIDsData.isEmpty {
            personalChecklistItemIDs = loadPersonalChecklistItemIDs()
        }
        if item.readOnly == false || personalChecklistItemIDs.contains(item.id) {
            return false
        }
        return true
    }

    func registerPersonalChecklistItem(_ id: UUID) {
        if personalChecklistItemIDs.isEmpty {
            personalChecklistItemIDs = loadPersonalChecklistItemIDs()
        }
        personalChecklistItemIDs.insert(id)
        savePersonalChecklistItemIDs()
    }

    /// Reset local des checklists (sans toucher aux conducteurs),
    /// puis recharge depuis Bundle/SharePoint.
    @MainActor
    func resetChecklistsPreservingPersonalItems() async {
        Logger.warning("Reset local des checklists demandé", category: "Store")
        
        // 1) Sauvegarder les items personnels
        let personalIds = personalChecklistItemIDs.isEmpty ? loadPersonalChecklistItemIDs() : personalChecklistItemIDs
        let currentItems = [checklistTriennale, checklistVP, checklistTE].compactMap { $0 }.flatMap { $0.items }
        let personalItems = currentItems.filter { personalIds.contains($0.id) }
        
        // 2) Reset des checklists locales
        lastChecklistData = Data()
        lastChecklistVPData = Data()
        lastChecklistTEData = Data()
        checklistTriennale = nil
        checklistVP = nil
        checklistTE = nil
        
        // 3) Recharger depuis Bundle (fallback local)
        loadBundledChecklists()
        
        // 4) Si SharePoint configuré, recharger la version fusionnée
        if sharePointService.isConfigured {
            do {
                let merged = try await SharePointSyncService.shared.fetchAllChecklists()
                applyMergedChecklists(merged)
            } catch {
                Logger.warning("Reset checklists: échec refresh SharePoint - \(error.localizedDescription)", category: "Store")
            }
        }
        
        // 5) Forcer un téléchargement si nécessaire (backend OK)
        await downloadAllChecklistsIfNeeded()
        
        // 6) Réinjecter les items personnels dans la checklist active (triennale/VP/TE)
        if !personalItems.isEmpty {
            if var checklist = checklistTriennale {
                checklist.items.append(contentsOf: personalItems)
                checklistTriennale = checklist
            }
            if var checklist = checklistVP {
                checklist.items.append(contentsOf: personalItems)
                checklistVP = checklist
            }
            if var checklist = checklistTE {
                checklist.items.append(contentsOf: personalItems)
                checklistTE = checklist
            }
        }
        
        saveChecklists()
        Logger.success("Reset local des checklists terminé", category: "Store")
    }
    
    private func loadPersonalChecklistItemIDs() -> Set<UUID> {
        guard !personalChecklistItemIDsData.isEmpty else { return [] }
        do {
            let decoded = try jsonDecoder.decode([UUID].self, from: personalChecklistItemIDsData)
            return Set(decoded)
        } catch {
            Logger.warning("Impossible de décoder personalChecklistItemIDs: \(error.localizedDescription)", category: "Store")
            return []
        }
    }
    
    private func savePersonalChecklistItemIDs() {
        do {
            let data = try jsonEncoder.encode(Array(personalChecklistItemIDs))
            personalChecklistItemIDsData = data
        } catch {
            Logger.error("Erreur d'encodage personalChecklistItemIDs: \(error.localizedDescription)", category: "Store")
        }
    }
    
    private func needsReadOnlyMigrationFromSharePoint() -> Bool {
        let checklists = [checklistTriennale, checklistVP, checklistTE].compactMap { $0 }
        for checklist in checklists {
            if checklist.items.contains(where: { $0.readOnly == nil }) {
                return true
            }
        }
        return false
    }
    
    @MainActor
    private func refreshMergedChecklistsForReadOnlyMigration() async {
        Logger.info("Migration readOnly: rafraîchissement depuis SharePoint", category: "Store")
        do {
            let merged = try await SharePointSyncService.shared.fetchAllChecklists()
            applyMergedChecklists(merged)
            saveChecklists()
            Logger.success("Migration readOnly: checklists fusionnées appliquées", category: "Store")
        } catch {
            Logger.warning("Migration readOnly: échec refresh SharePoint - \(error.localizedDescription)", category: "Store")
        }
    }
    
    // MARK: - Sauvegarde des données
    
    // Système de débouncing pour éviter les sauvegardes excessives
    private func saveDriversDebounced() {
        isSaving = true
        saveDriversCancellable?.cancel()
        saveDriversCancellable = Just(())
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
        } catch {
            Logger.error("Erreur d'encodage des conducteurs: \(error.localizedDescription)", category: "Store")
        }
    }
    
    // Système de débouncing pour la sauvegarde de la checklist
    private func saveChecklistDebounced() {
        saveChecklistCancellable?.cancel()
        saveChecklistCancellable = Just(())
            .delay(for: .seconds(AppConstants.Debounce.saveDelay), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveChecklists()
            }
    }
    
    /// Sauvegarde les trois checklists dans UserDefaults
    private func saveChecklists() {
        // Sauvegarder la checklist Triennale
        if let checklistTriennale = checklistTriennale {
            do {
                let data = try jsonEncoder.encode(checklistTriennale)
                lastChecklistData = data
            } catch {
                Logger.error("Erreur d'encodage de la checklist Triennale: \(error.localizedDescription)", category: "Store")
            }
        }
        
        // Sauvegarder la checklist VP
        if let checklistVP = checklistVP {
            do {
                let data = try jsonEncoder.encode(checklistVP)
                lastChecklistVPData = data
            } catch {
                Logger.error("Erreur d'encodage de la checklist VP: \(error.localizedDescription)", category: "Store")
            }
        }
        
        // Sauvegarder la checklist TE
        if let checklistTE = checklistTE {
            do {
                let data = try jsonEncoder.encode(checklistTE)
                lastChecklistTEData = data
            } catch {
                Logger.error("Erreur d'encodage de la checklist TE: \(error.localizedDescription)", category: "Store")
            }
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
        drivers = []
        lastChecklistData = Data()
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
    /// En cas d'échec réseau, les opérations sont mises en file d'attente pour retry automatique
    private func syncDriversToSharePoint() async {
        guard sharePointAutoSyncEnabled && sharePointService.isConfigured && !drivers.isEmpty else { return }

        guard !sharePointService.isSyncing else {
            Logger.debug("Synchronisation SharePoint déjà en cours, ignorée", category: "Store")
            return
        }

        do {
            try await sharePointService.syncDrivers(drivers)
            Logger.success("\(drivers.count) conducteur(s) synchronisé(s) automatiquement vers SharePoint", category: "Store")
        } catch {
            Logger.warning("Erreur lors de la synchronisation automatique des conducteurs: \(error.localizedDescription) — mise en file d'attente offline", category: "Store")
            // Mettre chaque conducteur modifié en file d'attente pour retry
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            for driver in drivers {
                if let data = try? encoder.encode(driver) {
                    OfflineQueue.shared.queueOperation(
                        .driverUpdate,
                        data: data,
                        metadata: ["driverName": driver.name, "driverId": driver.id.uuidString]
                    )
                }
            }
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
    /// En cas d'échec réseau, l'opération est mise en file d'attente pour retry automatique
    private func syncChecklistToSharePoint() async {
        guard sharePointAutoSyncEnabled && sharePointService.isConfigured,
              let currentChecklist = checklist else { return }

        guard !sharePointService.isSyncing else {
            Logger.debug("Synchronisation SharePoint déjà en cours, ignorée", category: "Store")
            return
        }

        do {
            try await sharePointService.syncChecklist(currentChecklist)
            Logger.success("Checklist '\(currentChecklist.title)' synchronisée automatiquement vers SharePoint", category: "Store")
        } catch {
            Logger.error("Erreur lors de la synchronisation de la checklist: \(error) — mise en file d'attente offline", category: "Store")
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(currentChecklist) {
                OfflineQueue.shared.queueOperation(
                    .checklistUpdate,
                    data: data,
                    metadata: ["checklistTitle": currentChecklist.title]
                )
            }
        }
    }
    
    // MARK: - Search Index Helper
    
    /// Met à jour l'index de recherche avec les checklists actives
    private func updateSearchIndex() {
        // Utiliser la checklist Triennale comme référence principale pour l'index de recherche
        if let checklist = checklistTriennale {
            SearchService.updateNotesSearchIndex(drivers: drivers, checklistTitle: checklist.title)
        } else {
            SearchService.resetSearchIndex()
        }
    }
}
