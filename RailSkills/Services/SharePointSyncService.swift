//
//  SharePointSyncService.swift
//  RailSkills
//
//  Service pour synchroniser les données avec SharePoint via Microsoft Graph API
//

import Foundation
import Combine
import Compression

/// Service pour synchroniser les données avec SharePoint
@MainActor
class SharePointSyncService: ObservableObject {
    static let shared = SharePointSyncService()
    
    private let sitePath = "sncf.sharepoint.com:/sites/railskillsgrpo365"
    private let azureADService = AzureADService.shared
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var siteId: String?
    
    private var cachedSiteId: String?
    
    private init() {}
    
    // MARK: - Helpers JSON
    
    /// Crée un JSONDecoder avec une stratégie de décodage de dates flexible
    /// Accepte plusieurs formats de dates :
    /// - ISO8601 complet ("2025-09-21T11:02:00Z")
    /// - ISO8601 sans fractions ("2025-09-21T11:02:00Z")
    /// - Format date simple YYYY-MM-DD ("1899-12-30", "1900-01-13")
    /// - Format français DD/MM/YYYY ("15/09/2023", "10/03/2024")
    /// - Returns: Un JSONDecoder configuré
    private func createFlexibleJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        
        // Stratégie personnalisée pour accepter plusieurs formats de dates
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Essayer d'abord le format ISO8601 complet (avec heure et timezone)
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            // Essayer le format ISO8601 sans fractions de secondes
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            // Essayer le format date simple (YYYY-MM-DD)
            let dateOnlyFormatter = DateFormatter()
            dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
            dateOnlyFormatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
            dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = dateOnlyFormatter.date(from: dateString) {
                // Rejeter les dates suspectes en 1900 (probablement des erreurs de conversion Excel)
                // Les dates Excel mal converties apparaissent souvent comme "1900-01-XX"
                let calendar = Calendar.current
                let year = calendar.component(.year, from: date)
                if year == 1900 {
                    Logger.warning("Date suspecte rejetée (probable erreur de conversion Excel): '\(dateString)' → \(date)", category: "SharePointSync")
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Date suspecte '\(dateString)' (année 1900) - probablement une erreur de conversion Excel"
                    )
                }
                return date
            }
            
            // Essayer le format français (DD/MM/YYYY) - utilisé dans les fichiers Excel français
            let frenchDateFormatter = DateFormatter()
            frenchDateFormatter.dateFormat = "dd/MM/yyyy"
            frenchDateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
            frenchDateFormatter.locale = Locale(identifier: "fr_FR")
            if let date = frenchDateFormatter.date(from: dateString) {
                return date
            }
            
            // Si aucun format ne fonctionne, lancer une erreur
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Date string '\(dateString)' ne correspond à aucun format attendu (ISO8601, YYYY-MM-DD, ou DD/MM/YYYY)"
            )
        }
        
        return decoder
    }
    
    /// Vérifie si le service est configuré et prêt
    /// Retourne true si le backend est configuré OU si Azure AD est configuré localement
    var isConfigured: Bool {
        // Vérifier d'abord si le backend est configuré
        if BackendConfig.isConfigured {
            return true
        }
        // Sinon, vérifier la configuration locale Azure AD
        return azureADService.isConfigured
    }
    
    /// Indique si on utilise le backend pour l'authentification
    var isUsingBackend: Bool {
        return BackendConfig.isConfigured && BackendTokenService.shared.cachedToken != nil
    }
    
    /// Récupère l'ID du site SharePoint (avec cache)
    /// - Returns: L'ID du site SharePoint
    /// - Throws: SharePointSyncError en cas d'erreur
    func getSiteId() async throws -> String {
        // Utiliser le cache si disponible
        if let cached = cachedSiteId {
            return cached
        }
        
        Logger.info("Récupération de l'ID du site SharePoint", category: "SharePointSync")
        
        let endpoint = "/sites/\(sitePath)"
        
        do {
            let data = try await azureADService.authenticatedRequest(endpoint: endpoint)
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let id = json["id"] as? String else {
                throw SharePointSyncError.invalidResponse("Impossible de récupérer l'ID du site")
            }
            
            cachedSiteId = id
            siteId = id
            Logger.success("ID du site SharePoint récupéré: \(id)", category: "SharePointSync")
            
            return id
        } catch {
            Logger.error("Erreur lors de la récupération de l'ID du site: \(error.localizedDescription)", category: "SharePointSync")
            throw SharePointSyncError.siteNotFound(error.localizedDescription)
        }
    }
    
    /// Synchronise les conducteurs vers SharePoint
    /// Chaque conducteur est sauvegardé dans son propre répertoire global :
    ///   RailSkills/Data/{nom-conducteur}/{nom-conducteur}.json
    ///
    /// Historique :
    /// - Anciennement, la structure était segmentée par CTT via SNCF_ID :
    ///   RailSkills/CTT_{sncfId}/Data/...
    /// - SNCF_ID ayant été supprimé, on unifie désormais la structure dans un espace partagé.
    ///
    /// - Parameter drivers: La liste des conducteurs à synchroniser (jeu global)
    /// - Throws: SharePointSyncError en cas d'erreur
    func syncDrivers(_ drivers: [DriverRecord]) async throws {
        guard isConfigured else {
            throw SharePointSyncError.notConfigured
        }
        
        isSyncing = true
        syncError = nil
        
        defer {
            isSyncing = false
        }
        
        do {
            let siteId = try await getSiteId()
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            // Chemin de base segmenté par CTT (utilise le cttId de l'utilisateur connecté)
            // Structure : RailSkills/CTT_{cttId}/Data/{nom-conducteur}/
            // - Si l'utilisateur est connecté : utilise son cttId
            // - Sinon (mode dev) : utilise "CTT_Shared"
            // Le cttFolder contient déjà "CTT_" donc on l'utilise directement
            let cttFolder = getCTTFolderName()
            let basePath = "RailSkills/\(cttFolder)/Data"
            
            // S'assurer que le dossier parent existe
            try await ensureFolderExists(siteId: siteId, folderPath: basePath)
            
            var successCount = 0
            var errors: [String] = []
            
            // Synchroniser chaque conducteur dans son propre répertoire
            for driver in drivers {
                do {
                    // Utiliser l'ID du conducteur comme nom de dossier pour garantir la cohérence avec le web
                    // Le web utilise également driver.id comme nom de dossier
                    let folderName = driver.id.uuidString
                    let driverFolderPath = "\(basePath)/\(folderName)"
                    
                    Logger.info("Synchronisation du conducteur '\(driver.name)' (ID: \(folderName))", category: "SharePointSync")
                    
                    try await ensureFolderExists(siteId: siteId, folderPath: driverFolderPath)
                    
                    // Convertir UN SEUL conducteur en JSON (pas toute la liste)
                    let data = try encoder.encode(driver)
                    
                    // Nom du fichier basé sur l'ID (cohérent avec le web)
                    let fileName = "\(folderName).json"
                    
                    Logger.debug("Fichier à créer: \(driverFolderPath)/\(fileName)", category: "SharePointSync")
                    
                    // Sauvegarder le fichier principal (toujours écrasé pour avoir la dernière version)
                    try await uploadFile(
                        siteId: siteId,
                        fileName: fileName,
                        data: data,
                        folderPath: driverFolderPath,
                        overwrite: true
                    )
                    
                    // Sauvegarder UNE SEULE archive de backup (écrasée à chaque fois)
                    // Permet de conserver la version précédente en cas de problème
                    let backupFileName = "\(folderName)_backup.json"
                    try await uploadFile(
                        siteId: siteId,
                        fileName: backupFileName,
                        data: data,
                        folderPath: driverFolderPath,
                        overwrite: true
                    )
                    
                    successCount += 1
                    Logger.debug("Conducteur '\(driver.name)' synchronisé vers SharePoint (ID: \(folderName))", category: "SharePointSync")
                } catch {
                    let errorMsg = "Erreur pour '\(driver.name)': \(error.localizedDescription)"
                    errors.append(errorMsg)
                    Logger.warning(errorMsg, category: "SharePointSync")
                }
            }
            
            if !errors.isEmpty {
                syncError = "\(errors.count) erreur(s): \(errors.joined(separator: "; "))"
            } else {
                syncError = nil
            }
            
            lastSyncDate = Date()
            
            Logger.success("\(successCount)/\(drivers.count) conducteur(s) synchronisé(s) vers SharePoint (\(cttFolder))", category: "SharePointSync")
        } catch {
            syncError = error.localizedDescription
            Logger.error("Erreur lors de la synchronisation des conducteurs: \(error.localizedDescription)", category: "SharePointSync")
            throw error
        }
    }
    
    /// Récupère le nom du dossier CTT depuis l'utilisateur connecté
    /// - Returns: Le nom du dossier CTT avec préfixe "CTT_" (ex: "CTT_jean.dupont" ou "CTT_Dev")
    func getCTTFolderName() -> String {
        // 1. Essayer de récupérer depuis WebAuthService (authentification web)
        if let currentUser = WebAuthService.shared.currentUser,
           !currentUser.cttId.isEmpty {
            var cttId = currentUser.cttId
            
            // Normaliser : s'assurer que le cttId contient toujours "CTT_"
            // Si le préfixe n'est pas présent, l'ajouter
            if !cttId.uppercased().hasPrefix("CTT_") {
                cttId = "CTT_\(cttId)"
                Logger.debug("Préfixe CTT_ ajouté : '\(currentUser.cttId)' → '\(cttId)'", category: "SharePointSync")
            }
            
            // Nettoyer et retourner (sans ajouter de préfixe supplémentaire)
            return sanitizeFolderName(cttId)
        }
        
        // 2. Fallback : dossier partagé si non connecté
        #if DEBUG
        Logger.warning("Aucun utilisateur connecté, utilisation du dossier 'CTT_Dev' pour SharePoint", category: "SharePointSync")
        return "CTT_Dev"
        #else
        Logger.warning("Aucun utilisateur connecté, utilisation du dossier 'CTT_Shared' pour SharePoint", category: "SharePointSync")
        return "CTT_Shared"
        #endif
    }
    
    /// Nettoie un nom pour être utilisé comme nom de dossier SharePoint
    /// - Parameter name: Le nom à nettoyer
    /// - Returns: Le nom nettoyé, prêt pour SharePoint
    func sanitizeFolderName(_ name: String) -> String {
        // Utiliser la fonction de sanitisation existante
        var sanitized = ValidationService.sanitizeFileName(name)
        
        // Remplacer les espaces par des underscores pour SharePoint
        sanitized = sanitized.replacingOccurrences(of: " ", with: "_")
        
        // Supprimer les underscores multiples consécutifs
        while sanitized.contains("__") {
            sanitized = sanitized.replacingOccurrences(of: "__", with: "_")
        }
        
        // Supprimer les underscores en début/fin
        sanitized = sanitized.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        
        // Limiter la longueur pour SharePoint (max 255 caractères pour un nom de dossier)
        if sanitized.count > 200 {
            let index = sanitized.index(sanitized.startIndex, offsetBy: 200)
            sanitized = String(sanitized[..<index])
        }
        
        return sanitized
    }
    
    /// Synchronise la checklist vers SharePoint
    /// Structure : RailSkills/Checklists/{titre}_timestamp.json (espace global partagé)
    ///
    /// Historique :
    /// - Anciennement, la structure pouvait être segmentée par CTT :
    ///   RailSkills/CTT_{sncfId}/Checklists/...
    /// - Avec la suppression de SNCF_ID, toutes les checklists sont désormais centralisées.
    ///
    /// - Parameter checklist: La checklist à synchroniser
    /// - Throws: SharePointSyncError en cas d'erreur
    func syncChecklist(_ checklist: Checklist) async throws {
        guard isConfigured else {
            throw SharePointSyncError.notConfigured
        }
        
        isSyncing = true
        syncError = nil
        
        defer {
            isSyncing = false
        }
        
        do {
            let siteId = try await getSiteId()
            
            // Convertir en JSON
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(checklist)
            
            // Chemin segmenté par CTT pour les checklists
            // Le cttFolder contient déjà "CTT_" donc on l'utilise directement
            let cttFolder = getCTTFolderName()
            let checklistsPath = "RailSkills/\(cttFolder)/Checklists"
            
            // Créer le dossier s'il n'existe pas
            try await ensureFolderExists(siteId: siteId, folderPath: checklistsPath)
            
            // Nom de base nettoyé pour la checklist
            let cleanTitle = checklist.title.replacingOccurrences(of: " ", with: "_")
            
            // Uploader le fichier principal (toujours écrasé pour avoir la dernière version)
            let fileName = "\(cleanTitle).json"
            try await uploadFile(
                siteId: siteId,
                fileName: fileName,
                data: data,
                folderPath: checklistsPath,
                overwrite: true
            )
            
            // Sauvegarder UNE SEULE archive de backup (écrasée à chaque fois)
            // Permet de conserver la version précédente en cas de problème
            let backupFileName = "\(cleanTitle)_backup.json"
            try await uploadFile(
                siteId: siteId,
                fileName: backupFileName,
                data: data,
                folderPath: checklistsPath,
                overwrite: true
            )
            
            lastSyncDate = Date()
            syncError = nil
            
            Logger.success("Checklist '\(checklist.title)' synchronisée vers SharePoint (\(cttFolder))", category: "SharePointSync")
        } catch {
            syncError = error.localizedDescription
            Logger.error("Erreur lors de la synchronisation de la checklist: \(error.localizedDescription)", category: "SharePointSync")
            throw error
        }
    }
    
    /// Récupère les conducteurs depuis SharePoint
    /// Lit les conducteurs dans la structure globale :
    ///   RailSkills/Data/{nom-conducteur}/{nom-conducteur}.json
    ///
    /// Historique :
    /// - Anciennement, les données pouvaient être segmentées par CTT via SNCF_ID dans
    ///   RailSkills/CTT_{sncfId}/Data/...
    /// - Avec la suppression de SNCF_ID, tous les conducteurs sont récupérés sans filtrage
    ///   par propriétaire (ownerSNCFId).
    ///
    /// - Returns: La liste de tous les conducteurs présents dans SharePoint (espace global)
    /// - Throws: SharePointSyncError en cas d'erreur
    func fetchDrivers() async throws -> [DriverRecord] {
        guard isConfigured else {
            throw SharePointSyncError.notConfigured
        }
        
        // 🔐 CRITIQUE : Synchroniser le secret organisationnel depuis le backend AVANT le déchiffrement
        // Cela garantit que le secret iOS correspond au secret utilisé par le backend Web
        Logger.info("🔄 Synchronisation du secret organisationnel depuis le backend...", category: "SharePointSync")
        do {
            let syncedSecret = try await OrganizationSecretService.shared.syncSecretFromBackend()
            let maskedSecret = syncedSecret.count > 8 ? 
                "\(syncedSecret.prefix(4))...\(syncedSecret.suffix(4))" : 
                "***"
            Logger.success("✅ Secret organisationnel synchronisé depuis le backend: \(maskedSecret) (longueur: \(syncedSecret.count) caractères)", category: "SharePointSync")
        } catch {
            // Ne pas bloquer si la synchronisation échoue, mais logger l'avertissement
            let currentSecret = EncryptionService.getOrganizationSecret()
            let maskedSecret = currentSecret.count > 8 ? 
                "\(currentSecret.prefix(4))...\(currentSecret.suffix(4))" : 
                "***"
            Logger.warning("⚠️ Impossible de synchroniser le secret depuis le backend: \(error.localizedDescription)", category: "SharePointSync")
            Logger.warning("   Utilisation du secret local: \(maskedSecret) (longueur: \(currentSecret.count) caractères)", category: "SharePointSync")
            Logger.warning("   ⚠️ Si les fichiers chiffrés ne se déchiffrent pas, vérifiez que le secret local correspond au secret backend", category: "SharePointSync")
        }
        
        // Logger le secret organisationnel utilisé (partiellement masqué pour sécurité)
        let orgSecret = EncryptionService.getOrganizationSecret()
        let maskedSecret = orgSecret.count > 8 ? 
            "\(orgSecret.prefix(4))...\(orgSecret.suffix(4))" : 
            "***"
        Logger.debug("🔐 Secret organisationnel utilisé: \(maskedSecret) (longueur: \(orgSecret.count) caractères)", category: "SharePointSync")
        
        // Vérifier la dérivation de la clé pour diagnostic
        EncryptionService.verifyKeyDerivation()
        
        let siteId = try await getSiteId()
        let decoder = createFlexibleJSONDecoder()
        
        // Chemin de base segmenté par CTT (même logique que syncDrivers)
        // Le cttFolder contient déjà "CTT_" donc on l'utilise directement
        let cttFolder = getCTTFolderName()
        let basePath = "RailSkills/\(cttFolder)/Data"
        
        Logger.info("Récupération des conducteurs depuis SharePoint - Chemin: \(basePath), CTT: \(cttFolder)", category: "SharePointSync")
        
        let baseEndpoint = "/sites/\(siteId)/drive/root:/\(basePath):/children"
        
        var drivers: [DriverRecord] = []
        
        // Essayer d'abord la structure isolée par CTT
        do {
            Logger.debug("Tentative de récupération des dossiers depuis: \(baseEndpoint)", category: "SharePointSync")
            let foldersData = try await azureADService.authenticatedRequest(endpoint: baseEndpoint)
            
            guard let foldersJson = try JSONSerialization.jsonObject(with: foldersData) as? [String: Any],
                  let foldersArray = foldersJson["value"] as? [[String: Any]] else {
                Logger.debug("Aucun dossier trouvé dans \(basePath)", category: "SharePointSync")
                // Pas d'erreur, juste aucun dossier trouvé
                return []
            }
            
            // Pour chaque dossier dans le chemin de base
            for folder in foldersArray {
                guard let folderName = folder["name"] as? String,
                      let _ = folder["folder"] as? [String: Any] else {
                    continue // Ignorer les fichiers
                }
                
                // D'abord, lister le contenu du dossier pour voir quels fichiers existent
                // Utiliser l'ID du fichier plutôt que le chemin pour éviter les problèmes de casse
                let folderEndpoint = "/sites/\(siteId)/drive/root:/\(basePath)/\(folderName):/children"
                var foundJsonFiles: [(id: String, name: String)] = []
                
                do {
                    let folderContentData = try await azureADService.authenticatedRequest(endpoint: folderEndpoint)
                    if let folderContentJson = try JSONSerialization.jsonObject(with: folderContentData) as? [String: Any],
                       let filesArray = folderContentJson["value"] as? [[String: Any]] {
                        // Récupérer tous les fichiers JSON avec leur ID et nom exact
                        foundJsonFiles = filesArray.compactMap { file in
                            guard let fileName = file["name"] as? String,
                                  let fileId = file["id"] as? String,
                                  file["folder"] == nil, // Ignorer les sous-dossiers
                                  fileName.hasSuffix(".json") else {
                                return nil
                            }
                            return (id: fileId, name: fileName)
                        }
                        Logger.debug("Dossier '\(folderName)' contient \(foundJsonFiles.count) fichier(s) JSON: \(foundJsonFiles.map { $0.name }.joined(separator: ", "))", category: "SharePointSync")
                    }
                } catch {
                    Logger.debug("Impossible de lister le contenu du dossier '\(folderName)': \(error.localizedDescription)", category: "SharePointSync")
                }
                
                // Essayer d'abord avec l'ID du fichier (plus fiable que le chemin)
                // IMPORTANT : récupérer TOUS les fichiers JSON, pas seulement le premier
                var driversFoundInFolder = 0
                var filesTried = 0
                
                for fileInfo in foundJsonFiles {
                    filesTried += 1
                    
                    // Ignorer les fichiers backup (on préfère le fichier principal)
                    if fileInfo.name.contains("_backup") {
                        Logger.debug("Fichier backup ignoré: \(fileInfo.name)", category: "SharePointSync")
                        continue
                    }
                    
                    Logger.debug("Tentative de téléchargement du fichier '\(fileInfo.name)' (ID: \(fileInfo.id)) depuis le dossier '\(folderName)'", category: "SharePointSync")
                    
                    var driverData: Data?
                    var downloadMethod = ""
                    
                    // Essayer d'abord avec le chemin (plus fiable pour SharePoint)
                    let driverEndpointPath = "/sites/\(siteId)/drive/root:/\(basePath)/\(folderName)/\(fileInfo.name):/content"
                    do {
                        driverData = try await azureADService.authenticatedRequest(endpoint: driverEndpointPath)
                        downloadMethod = "chemin"
                        Logger.debug("Fichier '\(fileInfo.name)' téléchargé avec succès via chemin", category: "SharePointSync")
                } catch {
                        Logger.debug("Échec du téléchargement via chemin pour '\(fileInfo.name)': \(error.localizedDescription), tentative avec ID...", category: "SharePointSync")
                        
                        // Fallback : utiliser l'ID du fichier
                        let driverEndpoint = "/sites/\(siteId)/drive/items/\(fileInfo.id)/content"
                        do {
                            driverData = try await azureADService.authenticatedRequest(endpoint: driverEndpoint)
                            downloadMethod = "ID"
                            Logger.debug("Fichier '\(fileInfo.name)' téléchargé avec succès via ID", category: "SharePointSync")
                        } catch {
                            Logger.error("Impossible de télécharger le fichier '\(fileInfo.name)' via chemin et ID: \(error.localizedDescription)", category: "SharePointSync")
                            continue
                        }
                    }
                    
                    // Décoder les données si elles ont été téléchargées
                    guard let data = driverData, !data.isEmpty else {
                        Logger.warning("Fichier '\(fileInfo.name)' téléchargé mais vide (méthode: \(downloadMethod))", category: "SharePointSync")
                        continue
                    }
                    
                    // Logger les informations de diagnostic
                    Logger.debug("🔍 [SharePointSync] Traitement du fichier '\(fileInfo.name)'", category: "SharePointSync")
                    Logger.debug("   Taille: \(data.count) bytes", category: "SharePointSync")
                    let hexPreview = data.prefix(50).map { String(format: "%02x", $0) }.joined(separator: " ")
                    Logger.debug("   Premiers bytes (hex): \(hexPreview)", category: "SharePointSync")
                    
                    // Vérifier si le fichier est détecté comme chiffré
                    let isEncrypted = EncryptionService.isEncrypted(data)
                    Logger.debug("   Détecté comme chiffré: \(isEncrypted)", category: "SharePointSync")
                    
                    // Traiter les données : décompression et/ou déchiffrement
                    // On essaie plusieurs méthodes dans l'ordre pour gérer tous les formats possibles
                    var jsonData: Data? = nil
                    var processingMethod = ""
                    
                    // Méthode 1: Vérifier si c'est déjà du JSON valide (fichier non chiffré, non compressé)
                    if let _ = try? JSONSerialization.jsonObject(with: data) {
                        jsonData = data
                        processingMethod = "JSON direct"
                        Logger.debug("✅ Fichier '\(fileInfo.name)' est du JSON valide (non chiffré, non compressé)", category: "SharePointSync")
                    }
                    
                    // Méthode 2: Essayer de déchiffrer avec métadonnées (format le plus récent)
                    if jsonData == nil && data.count > 4 + 32 + 28 {
                        Logger.debug("   Tentative de déchiffrement avec métadonnées...", category: "SharePointSync")
                        if let decrypted = EncryptionService.decryptWithMetadata(data) {
                            jsonData = decrypted.data
                            processingMethod = "déchiffré avec métadonnées"
                            Logger.debug("✅ Fichier '\(fileInfo.name)' déchiffré avec métadonnées (version: \(decrypted.metadata["version"] ?? "inconnue"))", category: "SharePointSync")
                        } else {
                            Logger.debug("   ❌ Échec du déchiffrement avec métadonnées", category: "SharePointSync")
                        }
                    }
                    
                    // Méthode 3: Essayer le déchiffrement simple (format sans métadonnées)
                    // Essayer même si isEncrypted() retourne false, car la détection peut échouer
                    if jsonData == nil && data.count >= 28 {
                        Logger.debug("   Tentative de déchiffrement simple (format backend Web)...", category: "SharePointSync")
                        if let decrypted = EncryptionService.decrypt(data) {
                            // Vérifier que les données déchiffrées sont du JSON valide
                            if let _ = try? JSONSerialization.jsonObject(with: decrypted) {
                                jsonData = decrypted
                                processingMethod = "déchiffré (simple)"
                                Logger.debug("✅ Fichier '\(fileInfo.name)' déchiffré (format simple) - JSON valide", category: "SharePointSync")
                            } else {
                                Logger.debug("   ⚠️ Déchiffrement réussi mais données non-JSON valides", category: "SharePointSync")
                            }
                        } else {
                            Logger.debug("   ❌ Échec du déchiffrement simple", category: "SharePointSync")
                            
                            // Si le déchiffrement échoue, essayer de re-synchroniser le secret et réessayer
                            // Cela peut aider si le secret a été mis à jour entre-temps
                            Logger.info("🔄 Tentative de re-synchronisation du secret et nouveau déchiffrement...", category: "SharePointSync")
                            do {
                                let _ = try await OrganizationSecretService.shared.syncSecretFromBackend()
                                Logger.info("✅ Secret re-synchronisé, nouvelle tentative de déchiffrement...", category: "SharePointSync")
                                
                                // Réessayer le déchiffrement avec le nouveau secret
                                if let decrypted = EncryptionService.decrypt(data) {
                                    if let _ = try? JSONSerialization.jsonObject(with: decrypted) {
                                        jsonData = decrypted
                                        processingMethod = "déchiffré (simple, après re-sync)"
                                        Logger.success("✅ Fichier '\(fileInfo.name)' déchiffré après re-synchronisation du secret", category: "SharePointSync")
                                    }
                                }
                            } catch {
                                Logger.debug("   ⚠️ Re-synchronisation du secret échouée: \(error.localizedDescription)", category: "SharePointSync")
                            }
                        }
                    }
                    
                    // Méthode 4: Essayer de décompresser avec différents algorithmes
                    if jsonData == nil {
                        // Essayer LZFSE
                        if let decompressed = try? (data as NSData).decompressed(using: .lzfse) as Data {
                            // Vérifier si les données décompressées sont du JSON valide
                            if (try? JSONSerialization.jsonObject(with: decompressed)) != nil {
                                jsonData = decompressed
                                processingMethod = "décompressé (LZFSE)"
                                Logger.debug("Fichier '\(fileInfo.name)' décompressé (LZFSE) - JSON valide", category: "SharePointSync")
                            } else {
                                // Les données décompressées ne sont pas du JSON, peut-être chiffrées
                                // Essayer de déchiffrer les données décompressées
                                if EncryptionService.isEncrypted(decompressed), let decrypted = EncryptionService.decrypt(decompressed) {
                                    jsonData = decrypted
                                    processingMethod = "décompressé (LZFSE) puis déchiffré"
                                    Logger.debug("Fichier '\(fileInfo.name)' décompressé (LZFSE) puis déchiffré", category: "SharePointSync")
                                }
                            }
                        }
                        
                        // Essayer zlib si LZFSE a échoué
                        if jsonData == nil {
                            if let decompressed = try? (data as NSData).decompressed(using: .zlib) as Data {
                                if (try? JSONSerialization.jsonObject(with: decompressed)) != nil {
                                    jsonData = decompressed
                                    processingMethod = "décompressé (zlib)"
                                    Logger.debug("Fichier '\(fileInfo.name)' décompressé (zlib) - JSON valide", category: "SharePointSync")
                                } else if EncryptionService.isEncrypted(decompressed), let decrypted = EncryptionService.decrypt(decompressed) {
                                    jsonData = decrypted
                                    processingMethod = "décompressé (zlib) puis déchiffré"
                                    Logger.debug("Fichier '\(fileInfo.name)' décompressé (zlib) puis déchiffré", category: "SharePointSync")
                                }
                            }
                        }
                        
                        // Note: gzip utilise zlib en interne, donc .zlib devrait fonctionner pour les fichiers gzip
                    }
                    
                    // Méthode 5: Essayer de déchiffrer PUIS décompresser (ordre inverse)
                    if jsonData == nil {
                        // Essayer de déchiffrer d'abord, puis décompresser
                        if EncryptionService.isEncrypted(data), let decrypted = EncryptionService.decrypt(data) {
                            // Essayer de décompresser les données déchiffrées
                            if let decompressed = try? (decrypted as NSData).decompressed(using: .lzfse) as Data {
                                if (try? JSONSerialization.jsonObject(with: decompressed)) != nil {
                                    jsonData = decompressed
                                    processingMethod = "déchiffré puis décompressé (LZFSE)"
                                    Logger.debug("Fichier '\(fileInfo.name)' déchiffré puis décompressé (LZFSE)", category: "SharePointSync")
                                }
                            } else if let decompressed = try? (decrypted as NSData).decompressed(using: .zlib) as Data {
                                if (try? JSONSerialization.jsonObject(with: decompressed)) != nil {
                                    jsonData = decompressed
                                    processingMethod = "déchiffré puis décompressé (zlib)"
                                    Logger.debug("Fichier '\(fileInfo.name)' déchiffré puis décompressé (zlib)", category: "SharePointSync")
                                }
                            }
                            // Note: gzip utilise zlib en interne, donc .zlib devrait fonctionner pour les fichiers gzip
                        }
                    }
                    
                    // Si aucune méthode n'a fonctionné, essayer une dernière fois avec re-synchronisation du secret
                    if jsonData == nil && isEncrypted && data.count >= 28 {
                        Logger.warning("⚠️ Toutes les méthodes de déchiffrement ont échoué pour '\(fileInfo.name)'", category: "SharePointSync")
                        Logger.warning("   Le secret organisationnel iOS ne correspond probablement pas au secret backend", category: "SharePointSync")
                        
                        // Dernière tentative : re-synchroniser le secret et réessayer
                        Logger.info("🔄 Dernière tentative : re-synchronisation du secret depuis le backend...", category: "SharePointSync")
                        do {
                            let syncedSecret = try await OrganizationSecretService.shared.syncSecretFromBackend()
                            Logger.info("✅ Secret re-synchronisé: \(syncedSecret.count > 8 ? "\(syncedSecret.prefix(4))...\(syncedSecret.suffix(4))" : "***") (longueur: \(syncedSecret.count))", category: "SharePointSync")
                            
                            // Réessayer toutes les méthodes de déchiffrement avec le nouveau secret
                            if let decrypted = EncryptionService.decrypt(data) {
                                if let _ = try? JSONSerialization.jsonObject(with: decrypted) {
                                    jsonData = decrypted
                                    processingMethod = "déchiffré (après re-sync secret)"
                                    Logger.success("✅ Fichier '\(fileInfo.name)' déchiffré avec succès après re-synchronisation du secret !", category: "SharePointSync")
                                }
                            }
                        } catch {
                            Logger.error("❌ Impossible de re-synchroniser le secret: \(error.localizedDescription)", category: "SharePointSync")
                            Logger.error("   Vérifiez que le backend est accessible et que l'endpoint /api/organization/secret existe", category: "SharePointSync")
                        }
                    }
                    
                    // Si aucune méthode n'a fonctionné, utiliser les données brutes comme dernier recours
                    if jsonData == nil {
                        Logger.warning("Fichier '\(fileInfo.name)' : impossible de traiter (taille: \(data.count) bytes). Premiers bytes (hex): \(data.prefix(20).map { String(format: "%02x", $0) }.joined(separator: " "))", category: "SharePointSync")
                        
                        // Afficher un aperçu hexadécimal pour diagnostic
                        let hexPreview = data.prefix(50).map { String(format: "%02x", $0) }.joined(separator: " ")
                        Logger.debug("Aperçu hexadécimal (50 premiers bytes): \(hexPreview)", category: "SharePointSync")
                        
                        // Logger le secret actuel pour diagnostic
                        let currentSecret = EncryptionService.getOrganizationSecret()
                        Logger.debug("   Secret organisationnel actuel: \(currentSecret.count > 8 ? "\(currentSecret.prefix(4))...\(currentSecret.suffix(4))" : "***") (longueur: \(currentSecret.count))", category: "SharePointSync")
                        
                        // Essayer quand même avec les données brutes (au cas où)
                        jsonData = data
                        processingMethod = "données brutes (tentative)"
                    }
                    
                    // Décoder le JSON final
                    // Note: jsonData ne devrait jamais être nil ici car on l'assigne toujours aux données brutes si nécessaire
                    if let finalJsonData = jsonData {
                        do {
                            let driver = try decoder.decode(DriverRecord.self, from: finalJsonData)
                            
                            // SNCF_ID supprimé : on ne filtre plus par ownerSNCFId,
                            // tous les conducteurs présents dans le dossier sont chargés.
                        drivers.append(driver)
                            driversFoundInFolder += 1
                            Logger.success("Conducteur '\(driver.name)' (ID: \(driver.id)) récupéré depuis SharePoint via \(downloadMethod) - Traitement: \(processingMethod) (dossier: \(folderName), fichier: \(fileInfo.name))", category: "SharePointSync")
                        } catch let decodingError as DecodingError {
                            Logger.error("❌ Erreur de décodage JSON pour le fichier '\(fileInfo.name)' (téléchargement: \(downloadMethod), traitement: \(processingMethod)): \(decodingError)", category: "SharePointSync")
                            
                            // Diagnostic détaillé
                            Logger.debug("Taille des données finales: \(finalJsonData.count) bytes", category: "SharePointSync")
                            
                            // Afficher un aperçu des données pour le diagnostic
                            if let dataPreview = String(data: finalJsonData.prefix(200), encoding: .utf8) {
                                Logger.debug("Aperçu texte (200 premiers caractères): \(dataPreview)", category: "SharePointSync")
                            } else {
                                Logger.debug("Impossible d'afficher l'aperçu texte (données binaires ou encodage invalide)", category: "SharePointSync")
                            }
                            
                            // Afficher l'aperçu hexadécimal
                            let hexPreview = finalJsonData.prefix(100).map { String(format: "%02x", $0) }.joined(separator: " ")
                            Logger.debug("Aperçu hexadécimal (100 premiers bytes): \(hexPreview)", category: "SharePointSync")
                            
                            // Vérifier si c'est du JSON valide mais avec un mauvais format
                            if let jsonObject = try? JSONSerialization.jsonObject(with: finalJsonData) {
                                Logger.debug("Les données sont du JSON valide mais ne correspondent pas au format DriverRecord. Structure: \(type(of: jsonObject))", category: "SharePointSync")
                            }
                            
                            // Fallback : essayer de récupérer depuis le backup
                            Logger.info("🔄 Tentative de récupération depuis le backup pour '\(fileInfo.name)'...", category: "SharePointSync")
                            if let backupDriver = try? await tryRecoverFromBackup(
                                driverId: folderName,
                                fileName: fileInfo.name,
                                folderPath: "\(basePath)/\(folderName)",
                                siteId: siteId
                            ) {
                                drivers.append(backupDriver)
                                driversFoundInFolder += 1
                                Logger.success("✅ Conducteur récupéré depuis le backup: '\(backupDriver.name)' (ID: \(backupDriver.id))", category: "SharePointSync")
                            } else {
                                Logger.warning("⚠️ Impossible de récupérer le conducteur depuis le backup", category: "SharePointSync")
                            }
                            
                            continue
                    } catch {
                            Logger.error("Erreur inattendue lors du décodage du fichier '\(fileInfo.name)': \(error.localizedDescription)", category: "SharePointSync")
                            continue
                        }
                    } else {
                        Logger.error("Fichier '\(fileInfo.name)' : jsonData est toujours nil après tous les traitements (cas inattendu)", category: "SharePointSync")
                        continue
                    }
                }
                
                Logger.info("Dossier '\(folderName)': \(filesTried) fichier(s) JSON trouvé(s), \(driversFoundInFolder) conducteur(s) récupéré(s)", category: "SharePointSync")
                
                if driversFoundInFolder == 0 && !foundJsonFiles.isEmpty {
                    Logger.warning("Dossier '\(folderName)' ignoré (aucun fichier JSON valide trouvé). Fichiers JSON présents: \(foundJsonFiles.map { $0.name }.joined(separator: ", "))", category: "SharePointSync")
                } else if driversFoundInFolder > 0 {
                    Logger.info("\(driversFoundInFolder) conducteur(s) récupéré(s) depuis le dossier '\(folderName)'", category: "SharePointSync")
                }
            }
        } catch {
            // Si la structure globale n'existe pas encore, on retourne simplement une liste vide.
            Logger.info("Aucun dossier de conducteurs trouvé dans \(basePath)", category: "SharePointSync")
            return []
        }
        
        // Résumé final de la récupération
        if drivers.isEmpty {
            Logger.info("Aucun conducteur trouvé dans SharePoint pour le CTT actuel", category: "SharePointSync")
            Logger.info("💡 Vérifiez que :", category: "SharePointSync")
            Logger.info("   1. Les fichiers existent dans SharePoint au chemin: \(basePath)", category: "SharePointSync")
            Logger.info("   2. Le secret organisationnel iOS correspond au secret backend", category: "SharePointSync")
            Logger.info("   3. Les fichiers ne sont pas corrompus", category: "SharePointSync")
        } else {
            Logger.success("✅ \(drivers.count) conducteur(s) récupéré(s) depuis SharePoint", category: "SharePointSync")
            
            // Lister les conducteurs récupérés pour faciliter le diagnostic
            let driverNames = drivers.map { "'\($0.name)'" }.joined(separator: ", ")
            Logger.info("   Conducteurs récupérés: \(driverNames)", category: "SharePointSync")
            
            // Avertissement si certains fichiers ont échoué (on ne peut pas les compter facilement ici,
            // mais les logs précédents indiquent les échecs)
            Logger.info("💡 Si certains conducteurs manquent, vérifiez les logs ci-dessus pour les erreurs de déchiffrement", category: "SharePointSync")
        }
        
        return drivers
    }
    
    /// Tente de récupérer un conducteur depuis son fichier backup
    /// - Parameters:
    ///   - driverId: L'ID du conducteur (nom du dossier)
    ///   - fileName: Le nom du fichier principal (pour construire le nom du backup)
    ///   - folderPath: Le chemin du dossier dans SharePoint
    ///   - siteId: L'ID du site SharePoint
    /// - Returns: Le DriverRecord récupéré depuis le backup, ou nil si échec
    private func tryRecoverFromBackup(
        driverId: String,
        fileName: String,
        folderPath: String,
        siteId: String
    ) async throws -> DriverRecord? {
        // Construire le nom du fichier backup
        let backupFileName = fileName.replacingOccurrences(of: ".json", with: "_backup.json")
        
        Logger.debug("Tentative de téléchargement du backup: \(backupFileName)", category: "SharePointSync")
        
        // Télécharger le fichier backup
        let backupEndpoint = "/sites/\(siteId)/drive/root:/\(folderPath)/\(backupFileName):/content"
        let backupData: Data
        
        do {
            backupData = try await azureADService.authenticatedRequest(endpoint: backupEndpoint)
            Logger.debug("Backup téléchargé avec succès (\(backupData.count) bytes)", category: "SharePointSync")
        } catch {
            Logger.warning("Impossible de télécharger le backup: \(error.localizedDescription)", category: "SharePointSync")
            return nil
        }
        
        guard !backupData.isEmpty else {
            Logger.warning("Backup téléchargé mais vide", category: "SharePointSync")
            return nil
        }
        
        // Traiter le backup de la même manière que le fichier principal
        var jsonData: Data? = nil
        
        // Essayer JSON direct
        if let _ = try? JSONSerialization.jsonObject(with: backupData) {
            jsonData = backupData
        }
        
        // Essayer déchiffrement avec métadonnées
        if jsonData == nil && backupData.count > 4 + 32 + 28 {
            if let decrypted = EncryptionService.decryptWithMetadata(backupData) {
                jsonData = decrypted.data
            }
        }
        
        // Essayer déchiffrement simple
        if jsonData == nil && backupData.count >= 28 {
            if let decrypted = EncryptionService.decrypt(backupData) {
                if let _ = try? JSONSerialization.jsonObject(with: decrypted) {
                    jsonData = decrypted
                }
            }
        }
        
        // Essayer décompression puis déchiffrement
        if jsonData == nil {
            if let decompressed = try? (backupData as NSData).decompressed(using: .lzfse) as Data {
                if let _ = try? JSONSerialization.jsonObject(with: decompressed) {
                    jsonData = decompressed
                } else if EncryptionService.isEncrypted(decompressed), let decrypted = EncryptionService.decrypt(decompressed) {
                    jsonData = decrypted
                }
            } else if let decompressed = try? (backupData as NSData).decompressed(using: .zlib) as Data {
                if let _ = try? JSONSerialization.jsonObject(with: decompressed) {
                    jsonData = decompressed
                } else if EncryptionService.isEncrypted(decompressed), let decrypted = EncryptionService.decrypt(decompressed) {
                    jsonData = decrypted
                }
            }
        }
        
        // Essayer déchiffrement puis décompression
        if jsonData == nil && EncryptionService.isEncrypted(backupData), let decrypted = EncryptionService.decrypt(backupData) {
            if let decompressed = try? (decrypted as NSData).decompressed(using: .lzfse) as Data,
               let _ = try? JSONSerialization.jsonObject(with: decompressed) {
                jsonData = decompressed
            } else if let decompressed = try? (decrypted as NSData).decompressed(using: .zlib) as Data,
                      let _ = try? JSONSerialization.jsonObject(with: decompressed) {
                jsonData = decompressed
            }
        }
        
        // Décoder le JSON
        guard let finalJsonData = jsonData else {
            Logger.warning("Impossible de traiter le backup (toutes les méthodes ont échoué)", category: "SharePointSync")
            return nil
        }
        
        do {
            let decoder = createFlexibleJSONDecoder()
            let driver = try decoder.decode(DriverRecord.self, from: finalJsonData)
            Logger.success("✅ Backup décodé avec succès pour '\(driver.name)'", category: "SharePointSync")
            return driver
        } catch {
            Logger.error("Erreur de décodage JSON du backup: \(error.localizedDescription)", category: "SharePointSync")
            return nil
        }
    }
    
    /// Vérifie si un dossier existe et le crée si nécessaire
    /// - Parameters:
    ///   - siteId: L'ID du site SharePoint
    ///   - folderPath: Le chemin du dossier (ex: "RailSkills/Data")
    /// - Throws: SharePointSyncError en cas d'erreur
    private func ensureFolderExists(siteId: String, folderPath: String) async throws {
        let pathComponents = folderPath.split(separator: "/")
        var currentPath = ""
        
        for component in pathComponents {
            let newPath = currentPath.isEmpty ? String(component) : "\(currentPath)/\(component)"
            
            // Vérifier si le dossier existe
            let endpoint = "/sites/\(siteId)/drive/root:/\(newPath):"
            
            do {
                // Tenter de récupérer le dossier
                _ = try await azureADService.authenticatedRequest(endpoint: endpoint)
                // Le dossier existe, continuer
            } catch {
                // Le dossier n'existe pas, le créer
                if currentPath.isEmpty {
                    // Créer à la racine
                    try await createFolder(siteId: siteId, folderName: String(component), parentPath: nil)
                } else {
                    // Créer dans le dossier parent
                    try await createFolder(siteId: siteId, folderName: String(component), parentPath: currentPath)
                }
            }
            
            currentPath = newPath
        }
    }
    
    /// Crée un dossier dans SharePoint
    /// - Parameters:
    ///   - siteId: L'ID du site SharePoint
    ///   - folderName: Le nom du dossier à créer
    ///   - parentPath: Le chemin du dossier parent (nil pour la racine)
    /// - Throws: SharePointSyncError en cas d'erreur
    private func createFolder(siteId: String, folderName: String, parentPath: String?) async throws {
        let endpoint: String
        if let parent = parentPath {
            endpoint = "/sites/\(siteId)/drive/root:/\(parent):/children"
        } else {
            endpoint = "/sites/\(siteId)/drive/root/children"
        }
        
        let body: [String: Any] = [
            "name": folderName,
            "folder": [String: Any](),
            "@microsoft.graph.conflictBehavior": "rename"
        ]
        
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            throw SharePointSyncError.invalidRequest
        }
        
        _ = try await azureADService.authenticatedRequest(endpoint: endpoint, method: "POST", body: bodyData)
        Logger.info("Dossier créé: \(parentPath ?? "root")/\(folderName)", category: "SharePointSync")
    }
    
    /// Téléverse un fichier vers SharePoint
    /// - Parameters:
    ///   - siteId: L'ID du site SharePoint
    ///   - fileName: Le nom du fichier
    ///   - data: Les données du fichier
    ///   - folderPath: Le chemin du dossier de destination
    ///   - overwrite: Si true, écrase le fichier existant
    /// - Throws: SharePointSyncError en cas d'erreur
    private func uploadFile(siteId: String, fileName: String, data: Data, folderPath: String, overwrite: Bool = false) async throws {
        let endpoint: String
        if overwrite {
            // Utiliser PUT pour écraser
            endpoint = "/sites/\(siteId)/drive/root:/\(folderPath)/\(fileName):/content"
        } else {
            // Utiliser PUT pour créer (sera renommé en cas de conflit)
            endpoint = "/sites/\(siteId)/drive/root:/\(folderPath)/\(fileName):/content"
        }
        
        _ = try await azureADService.authenticatedRequest(endpoint: endpoint, method: "PUT", body: data)
        Logger.info("Fichier téléversé: \(folderPath)/\(fileName) (\(data.count) octets)", category: "SharePointSync")
    }
    
    // MARK: - Suppression de conducteurs
    
    /// Supprime un conducteur et son dossier complet sur SharePoint
    /// - Parameter driverId: L'ID du conducteur à supprimer (UUID)
    /// - Throws: SharePointSyncError en cas d'erreur
    func deleteDriver(driverId: UUID) async throws {
        guard isConfigured else {
            Logger.warning("SharePoint non configuré, impossible de supprimer le conducteur", category: "SharePointSync")
            return
        }
        
        Logger.info("Suppression du conducteur (ID: \(driverId.uuidString)) sur SharePoint...", category: "SharePointSync")
        
        do {
            let siteId = try await getSiteId()
            // Le cttFolder contient déjà "CTT_" donc on l'utilise directement
            let cttFolder = getCTTFolderName()
            let basePath = "RailSkills/\(cttFolder)/Data"
            let folderName = driverId.uuidString
            let driverFolderPath = "\(basePath)/\(folderName)"
            
            // Construire l'endpoint pour supprimer le dossier complet
            // Microsoft Graph API permet de supprimer un dossier et tout son contenu
            let endpoint = "/sites/\(siteId)/drive/root:/\(driverFolderPath):"
            
            // Supprimer le dossier (cela supprime automatiquement tous les fichiers à l'intérieur)
            // On ignore la réponse car DELETE ne retourne généralement pas de données utiles
            _ = try await azureADService.authenticatedRequest(endpoint: endpoint, method: "DELETE")
            
            Logger.success("✅ Conducteur supprimé sur SharePoint (dossier: \(driverFolderPath))", category: "SharePointSync")
        } catch {
            Logger.error("❌ Erreur lors de la suppression du conducteur sur SharePoint: \(error.localizedDescription)", category: "SharePointSync")
            // Ne pas lancer d'erreur si le dossier n'existe pas déjà (peut-être déjà supprimé)
            // On log juste un avertissement
            if let azureError = error as? AzureADError,
               case .httpError(let statusCode, _) = azureError,
               statusCode == 404 {
                Logger.warning("Dossier du conducteur non trouvé sur SharePoint (peut-être déjà supprimé)", category: "SharePointSync")
            } else {
                throw error
            }
        }
    }
    
    /// Supprime plusieurs conducteurs sur SharePoint
    /// - Parameter driverIds: Les IDs des conducteurs à supprimer
    /// - Throws: SharePointSyncError en cas d'erreur
    func deleteDrivers(driverIds: [UUID]) async throws {
        guard isConfigured else {
            Logger.warning("SharePoint non configuré, impossible de supprimer les conducteurs", category: "SharePointSync")
            return
        }
        
        Logger.info("Suppression de \(driverIds.count) conducteur(s) sur SharePoint...", category: "SharePointSync")
        
        var successCount = 0
        var errors: [String] = []
        
        for driverId in driverIds {
            do {
                try await deleteDriver(driverId: driverId)
                successCount += 1
            } catch {
                let errorMsg = "Erreur pour le conducteur \(driverId.uuidString): \(error.localizedDescription)"
                errors.append(errorMsg)
                Logger.warning(errorMsg, category: "SharePointSync")
            }
        }
        
        if !errors.isEmpty {
            Logger.warning("\(errors.count) erreur(s) lors de la suppression: \(errors.joined(separator: "; "))", category: "SharePointSync")
        }
        
        Logger.success("✅ \(successCount)/\(driverIds.count) conducteur(s) supprimé(s) sur SharePoint", category: "SharePointSync")
    }
    
    /// Invalide le cache (force la récupération de l'ID du site au prochain appel)
    func invalidateCache() {
        cachedSiteId = nil
        siteId = nil
    }
    
    // MARK: - Téléchargement de checklist par défaut
    
    /// Chemin du fichier checklist par défaut sur SharePoint
    private let defaultChecklistPath = "RailSkills/Checklists/questions_CFL.json"
    private let defaultChecklistVPPath = "RailSkills/Checklists/questions_VP.json"
    private let defaultChecklistTEPath = "RailSkills/Checklists/questions_TE.json"
    
    /// Télécharge la checklist par défaut depuis SharePoint
    /// - Returns: La checklist téléchargée, ou nil si non trouvée
    func downloadDefaultChecklist() async throws -> Checklist? {
        guard isConfigured else {
            Logger.warning("SharePoint non configuré, impossible de télécharger la checklist", category: "SharePointSync")
            return nil
        }
        
        Logger.info("Téléchargement de la checklist par défaut depuis SharePoint...", category: "SharePointSync")
        
        do {
            let siteId = try await getSiteId()
            
            // Télécharger le fichier
            let endpoint = "/sites/\(siteId)/drive/root:/\(defaultChecklistPath):/content"
            let data = try await azureADService.authenticatedRequest(endpoint: endpoint)
            
            // Décoder la checklist
            let decoder = createFlexibleJSONDecoder()
            
            let checklist = try decoder.decode(Checklist.self, from: data)
            
            Logger.success("Checklist téléchargée: \(checklist.title) avec \(checklist.items.count) éléments", category: "SharePointSync")
            
            return checklist
            
        } catch {
            Logger.warning("Checklist par défaut non trouvée sur SharePoint: \(error.localizedDescription)", category: "SharePointSync")
            return nil
        }
    }
    
    /// Télécharge la checklist VP par défaut depuis SharePoint
    /// - Returns: La checklist VP téléchargée, ou nil si non trouvée
    func downloadDefaultChecklistVP() async throws -> Checklist? {
        guard isConfigured else {
            Logger.warning("SharePoint non configuré, impossible de télécharger la checklist VP", category: "SharePointSync")
            return nil
        }
        
        Logger.info("Téléchargement de la checklist VP par défaut depuis SharePoint...", category: "SharePointSync")
        
        do {
            let siteId = try await getSiteId()
            
            // Télécharger le fichier
            let endpoint = "/sites/\(siteId)/drive/root:/\(defaultChecklistVPPath):/content"
            let data = try await azureADService.authenticatedRequest(endpoint: endpoint)
            
            // Décoder la checklist
            let decoder = createFlexibleJSONDecoder()
            
            let checklist = try decoder.decode(Checklist.self, from: data)
            
            Logger.success("Checklist VP téléchargée: \(checklist.title) avec \(checklist.items.count) éléments", category: "SharePointSync")
            
            return checklist
            
        } catch {
            Logger.warning("Checklist VP par défaut non trouvée sur SharePoint: \(error.localizedDescription)", category: "SharePointSync")
            return nil
        }
    }
    
    /// Télécharge la checklist TE par défaut depuis SharePoint
    /// - Returns: La checklist TE téléchargée, ou nil si non trouvée
    func downloadDefaultChecklistTE() async throws -> Checklist? {
        guard isConfigured else {
            Logger.warning("SharePoint non configuré, impossible de télécharger la checklist TE", category: "SharePointSync")
            return nil
        }
        
        Logger.info("Téléchargement de la checklist TE par défaut depuis SharePoint...", category: "SharePointSync")
        
        do {
            let siteId = try await getSiteId()
            
            // Télécharger le fichier
            let endpoint = "/sites/\(siteId)/drive/root:/\(defaultChecklistTEPath):/content"
            let data = try await azureADService.authenticatedRequest(endpoint: endpoint)
            
            // Décoder la checklist
            let decoder = createFlexibleJSONDecoder()
            
            let checklist = try decoder.decode(Checklist.self, from: data)
            
            Logger.success("Checklist TE téléchargée: \(checklist.title) avec \(checklist.items.count) éléments", category: "SharePointSync")
            
            return checklist
            
        } catch {
            Logger.warning("Checklist TE par défaut non trouvée sur SharePoint: \(error.localizedDescription)", category: "SharePointSync")
            return nil
        }
    }
    
    /// Télécharge une checklist depuis un chemin spécifique sur SharePoint
    /// - Parameter path: Le chemin du fichier (ex: "RailSkills/Checklists/ma_checklist.json")
    /// - Returns: La checklist téléchargée
    func downloadChecklist(from path: String) async throws -> Checklist {
        guard isConfigured else {
            throw SharePointSyncError.notConfigured
        }
        
        Logger.info("Téléchargement de la checklist depuis: \(path)", category: "SharePointSync")
        
        let siteId = try await getSiteId()
        
        // Télécharger le fichier
        let endpoint = "/sites/\(siteId)/drive/root:/\(path):/content"
        let data = try await azureADService.authenticatedRequest(endpoint: endpoint)
        
        // Décoder la checklist
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let checklist = try decoder.decode(Checklist.self, from: data)
        
        Logger.success("Checklist téléchargée: \(checklist.title) avec \(checklist.items.count) éléments", category: "SharePointSync")
        
        return checklist
    }
    
    // MARK: - Upload des checklists par défaut
    
    /// Upload les fichiers JSON des checklists VP et TE vers SharePoint
    /// Utilise les fichiers locaux créés dans RailSkills/Checklists/
    /// - Throws: SharePointSyncError en cas d'erreur
    func uploadDefaultChecklistsToSharePoint() async throws {
        guard isConfigured else {
            throw SharePointSyncError.notConfigured
        }
        
        Logger.info("Upload des checklists par défaut (VP et TE) vers SharePoint...", category: "SharePointSync")
        
        let siteId = try await getSiteId()
        let checklistsPath = "RailSkills/Checklists"
        
        // Créer le dossier s'il n'existe pas
        try await ensureFolderExists(siteId: siteId, folderPath: checklistsPath)
        
        // Upload de la checklist VP
        let vpFilePath = "/Users/sylvaingallon/Desktop/Railskills rebuild/RailSkills/RailSkills/Checklists/questions_VP.json"
        if FileManager.default.fileExists(atPath: vpFilePath) {
            do {
                let vpData = try Data(contentsOf: URL(fileURLWithPath: vpFilePath))
                try await uploadFile(
                    siteId: siteId,
                    fileName: "questions_VP.json",
                    data: vpData,
                    folderPath: checklistsPath,
                    overwrite: true
                )
                Logger.success("Checklist VP uploadée vers SharePoint", category: "SharePointSync")
            } catch {
                Logger.error("Erreur lors de l'upload de la checklist VP: \(error.localizedDescription)", category: "SharePointSync")
                throw error
            }
        } else {
            Logger.warning("Fichier questions_VP.json non trouvé à \(vpFilePath)", category: "SharePointSync")
        }
        
        // Upload de la checklist TE
        let teFilePath = "/Users/sylvaingallon/Desktop/Railskills rebuild/RailSkills/RailSkills/Checklists/questions_TE.json"
        if FileManager.default.fileExists(atPath: teFilePath) {
            do {
                let teData = try Data(contentsOf: URL(fileURLWithPath: teFilePath))
                try await uploadFile(
                    siteId: siteId,
                    fileName: "questions_TE.json",
                    data: teData,
                    folderPath: checklistsPath,
                    overwrite: true
                )
                Logger.success("Checklist TE uploadée vers SharePoint", category: "SharePointSync")
            } catch {
                Logger.error("Erreur lors de l'upload de la checklist TE: \(error.localizedDescription)", category: "SharePointSync")
                throw error
            }
        } else {
            Logger.warning("Fichier questions_TE.json non trouvé à \(teFilePath)", category: "SharePointSync")
        }
        
        Logger.success("Upload des checklists par défaut terminé", category: "SharePointSync")
    }
}

// MARK: - Gestion des conflits

/// Stratégie de résolution des conflits de synchronisation
enum SyncConflictResolution {
    case useLocal      // Version iPad prioritaire
    case useRemote     // Version SharePoint prioritaire
    case merge         // Fusion intelligente (recommandé)
    case askUser       // Intervention manuelle
}

/// Représente un conflit entre version locale et distante
struct SyncConflict: Identifiable {
    let id = UUID()
    let driverName: String
    let driverId: UUID
    let localVersion: DriverRecord
    let remoteVersion: DriverRecord
    let localModifiedDate: Date
    let remoteModifiedDate: Date
    
    /// Détermine si la version locale est plus récente
    var localIsNewer: Bool {
        localModifiedDate > remoteModifiedDate
    }
}

extension SharePointSyncService {
    /// Synchronise avec détection et résolution automatique des conflits
    /// - Parameters:
    ///   - drivers: Conducteurs locaux à synchroniser
    ///   - resolution: Stratégie de résolution des conflits
    /// - Returns: Liste des conflits détectés (vide si tout s'est bien passé ou si résolution auto)
    func syncWithConflictResolution(
        _ drivers: [DriverRecord],
        resolution: SyncConflictResolution = .merge
    ) async throws -> [SyncConflict] {
        guard isConfigured else {
            throw SharePointSyncError.notConfigured
        }
        
        isSyncing = true
        syncError = nil
        
        defer {
            isSyncing = false
        }
        
        do {
            // 1. Récupérer les conducteurs distants
            let remoteDrivers = try await fetchDrivers()
            
            // 2. Détecter les conflits
            let conflicts = detectConflicts(local: drivers, remote: remoteDrivers)
            
            if conflicts.isEmpty {
                // Pas de conflits, sync normale
                try await syncDrivers(drivers)
                Logger.success("Synchronisation sans conflits réussie", category: "SharePointSync")
                return []
            }
            
            // 3. Résoudre les conflits selon la stratégie
            switch resolution {
            case .useLocal:
                // Écraser les versions distantes avec les locales
                try await syncDrivers(drivers)
                Logger.info("Conflits résolus: version locale prioritaire", category: "SharePointSync")
                return []
                
            case .useRemote:
                // Ne rien faire, garder les versions distantes
                Logger.info("Conflits résolus: version distante prioritaire", category: "SharePointSync")
                return []
                
            case .merge:
                // Fusion intelligente
                let mergedDrivers = conflicts.map { conflict in
                    mergeDriverRecords(local: conflict.localVersion, remote: conflict.remoteVersion)
                }
                try await syncDrivers(mergedDrivers)
                Logger.success("Conflits résolus: fusion intelligente appliquée", category: "SharePointSync")
                return []
                
            case .askUser:
                // Retourner les conflits pour intervention manuelle
                Logger.info("\(conflicts.count) conflit(s) détecté(s), intervention manuelle requise", category: "SharePointSync")
                return conflicts
            }
        } catch {
            syncError = error.localizedDescription
            Logger.error("Erreur lors de la synchronisation avec gestion des conflits: \(error.localizedDescription)", category: "SharePointSync")
            throw error
        }
    }
    
    /// Détecte les conflits entre versions locales et distantes
    private func detectConflicts(local: [DriverRecord], remote: [DriverRecord]) -> [SyncConflict] {
        var conflicts: [SyncConflict] = []
        
        // Créer un dictionnaire des conducteurs distants par ID
        let remoteDict = Dictionary(uniqueKeysWithValues: remote.map { ($0.id, $0) })
        
        for localDriver in local {
            guard let remoteDriver = remoteDict[localDriver.id] else {
                // Pas de version distante, pas de conflit
                continue
            }
            
            // Comparer les dates de modification
            let localDate = localDriver.lastEvaluation ?? Date.distantPast
            let remoteDate = remoteDriver.lastEvaluation ?? Date.distantPast
            
            // Si les dates sont identiques, pas de conflit
            guard localDate != remoteDate else { continue }
            
            // Vérifier s'il y a vraiment des différences significatives
            if hasSignificantDifferences(local: localDriver, remote: remoteDriver) {
                conflicts.append(SyncConflict(
                    driverName: localDriver.name,
                    driverId: localDriver.id,
                    localVersion: localDriver,
                    remoteVersion: remoteDriver,
                    localModifiedDate: localDate,
                    remoteModifiedDate: remoteDate
                ))
            }
        }
        
        return conflicts
    }
    
    /// Vérifie s'il y a des différences significatives entre deux versions
    private func hasSignificantDifferences(local: DriverRecord, remote: DriverRecord) -> Bool {
        // Comparer les états des questions
        if local.checklistStates != remote.checklistStates {
            return true
        }
        
        // Comparer les notes
        if local.checklistNotes != remote.checklistNotes {
            return true
        }
        
        // Comparer les dates triennales
        if local.triennialStart != remote.triennialStart {
            return true
        }
        
        return false
    }
    
    /// Fusionne intelligemment deux versions d'un conducteur
    /// - Logique de fusion:
    ///   - Dates d'évaluation: prendre la plus récente
    ///   - Date triennale: conserver la plus ancienne (référence)
    ///   - États des questions: privilégier les plus avancés (2 > 1 > 0)
    ///   - Notes: concaténer si différentes
    ///   - Dates de suivi: prendre les plus récentes
    func mergeDriverRecords(local: DriverRecord, remote: DriverRecord) -> DriverRecord {
        var merged = local
        
        // 1. Date d'évaluation: prendre la plus récente
        if let remoteEval = remote.lastEvaluation,
           let localEval = local.lastEvaluation {
            merged.lastEvaluation = max(localEval, remoteEval)
        } else {
            merged.lastEvaluation = remote.lastEvaluation ?? local.lastEvaluation
        }
        
        // 2. Date triennale: conserver la plus ancienne (référence initiale)
        if let remoteTriennal = remote.triennialStart,
           let localTriennal = local.triennialStart {
            merged.triennialStart = min(localTriennal, remoteTriennal)
        } else {
            merged.triennialStart = remote.triennialStart ?? local.triennialStart
        }
        
        // 3. États des questions: privilégier les plus avancés
        merged.checklistStates = mergeChecklistStates(
            local: local.checklistStates,
            remote: remote.checklistStates
        )
        
        // 4. Notes: concaténer si différentes
        merged.checklistNotes = mergeNotes(
            local: local.checklistNotes,
            remote: remote.checklistNotes
        )
        
        // 5. Dates de suivi: prendre les plus récentes
        merged.checklistDates = mergeDates(
            local: local.checklistDates,
            remote: remote.checklistDates
        )
        
        Logger.info("Fusion intelligente appliquée pour '\(merged.name)'", category: "SharePointSync")
        return merged
    }
    
    /// Fusionne les états des questions en privilégiant l'état le plus avancé
    private func mergeChecklistStates(
        local: [String: [UUID: Int]],
        remote: [String: [UUID: Int]]
    ) -> [String: [UUID: Int]] {
        var merged: [String: [UUID: Int]] = local
        
        for (checklistKey, remoteStates) in remote {
            if var localStates = merged[checklistKey] {
                // Fusionner question par question
                for (questionId, remoteState) in remoteStates {
                    let localState = localStates[questionId] ?? 0
                    // Privilégier l'état le plus avancé (2 > 1 > 0, sauf 3 = N/A)
                    if remoteState == 3 || localState == 3 {
                        // N/A: garder la valeur locale
                        continue
                    }
                    localStates[questionId] = max(localState, remoteState)
                }
                merged[checklistKey] = localStates
            } else {
                // Checklist pas présente localement, prendre la distante
                merged[checklistKey] = remoteStates
            }
        }
        
        return merged
    }
    
    /// Fusionne les notes en concaténant si différentes
    private func mergeNotes(
        local: [String: [UUID: String]],
        remote: [String: [UUID: String]]
    ) -> [String: [UUID: String]] {
        var merged: [String: [UUID: String]] = local
        
        for (checklistKey, remoteNotes) in remote {
            if var localNotes = merged[checklistKey] {
                // Fusionner note par note
                for (questionId, remoteNote) in remoteNotes {
                    if let localNote = localNotes[questionId] {
                        // Si les notes sont différentes, les concaténer
                        if localNote != remoteNote {
                            localNotes[questionId] = "\(localNote)\n\n--- Fusion ---\n\n\(remoteNote)"
                        }
                    } else {
                        // Pas de note locale, prendre la distante
                        localNotes[questionId] = remoteNote
                    }
                }
                merged[checklistKey] = localNotes
            } else {
                // Checklist pas présente localement, prendre la distante
                merged[checklistKey] = remoteNotes
            }
        }
        
        return merged
    }
    
    /// Fusionne les dates en prenant les plus récentes
    private func mergeDates(
        local: [String: [UUID: Date]],
        remote: [String: [UUID: Date]]
    ) -> [String: [UUID: Date]] {
        var merged: [String: [UUID: Date]] = local
        
        for (checklistKey, remoteDates) in remote {
            if var localDates = merged[checklistKey] {
                // Fusionner date par date
                for (questionId, remoteDate) in remoteDates {
                    if let localDate = localDates[questionId] {
                        // Prendre la date la plus récente
                        localDates[questionId] = max(localDate, remoteDate)
                    } else {
                        // Pas de date locale, prendre la distante
                        localDates[questionId] = remoteDate
                    }
                }
                merged[checklistKey] = localDates
            } else {
                // Checklist pas présente localement, prendre la distante
                merged[checklistKey] = remoteDates
            }
        }
        
        return merged
    }
    
    /// Teste l'accès au dossier SharePoint
    func testFolderAccess() async throws -> Bool {
        guard isConfigured else {
            throw SharePointSyncError.notConfigured
        }
        
        do {
            let siteId = try await getSiteId()
            let basePath = "RailSkills/Data"
            let endpoint = "/sites/\(siteId)/drive/root:/\(basePath):"
            
            _ = try await azureADService.authenticatedRequest(endpoint: endpoint)
            Logger.success("Accès au dossier SharePoint validé", category: "SharePointSync")
            return true
        } catch {
            Logger.error("Échec de l'accès au dossier SharePoint: \(error.localizedDescription)", category: "SharePointSync")
            throw error
        }
    }
}

enum SharePointSyncError: Error, LocalizedError {
    case notConfigured
    case siteNotFound(String)
    case invalidResponse(String)
    case invalidRequest
    case uploadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Service SharePoint non configuré. Veuillez configurer le Client Secret Azure AD dans les paramètres."
        case .siteNotFound(let message):
            return "Site SharePoint introuvable: \(message)"
        case .invalidResponse(let message):
            return "Réponse invalide: \(message)"
        case .invalidRequest:
            return "Requête invalide"
        case .uploadFailed(let message):
            return "Échec du téléversement: \(message)"
        }
    }
}

