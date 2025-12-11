//
//  SharePointSyncService+Backend.swift
//  RailSkills
//
//  Extension du SharePointSyncService pour utiliser le backend
//  Architecture sécurisée V2 : tokens gérés par le serveur
//

import Foundation

extension SharePointSyncService {
    
    // MARK: - Configuration
    
    /// Mode d'authentification SharePoint
    enum AuthMode {
        case backend        // Recommandé : tokens via backend
        case clientSecret   // Fallback : Client Secret manuel
    }
    
    /// Mode d'authentification actuel
    var currentAuthMode: AuthMode {
        // Si le backend est configuré et accessible, l'utiliser
        if BackendTokenService.shared.cachedToken != nil || isBackendAvailable {
            return .backend
        }
        // Sinon, fallback sur Client Secret manuel
        return .clientSecret
    }
    
    /// Vérifie si le backend est disponible
    private var isBackendAvailable: Bool {
        // Vérifier si on a déjà testé récemment
        if let lastCheck = UserDefaults.standard.object(forKey: "lastBackendCheck") as? Date {
            let timeSinceCheck = Date().timeIntervalSince(lastCheck)
            // Rechecken toutes les 5 minutes
            if timeSinceCheck < 300 {
                return UserDefaults.standard.bool(forKey: "backendAvailable")
            }
        }
        return false
    }
    
    // MARK: - Méthodes publiques améliorées
    
    /// Teste la connexion SharePoint avec le mode approprié
    func testConnectionWithBackend() async throws {
        Logger.info("Test de connexion SharePoint (mode: \(currentAuthMode))", category: "SharePointSync")
        
        switch currentAuthMode {
        case .backend:
            try await testConnectionViaBackend()
        case .clientSecret:
            // Mode Client Secret manuel - vérifier la configuration
            guard isConfigured else {
                throw SharePointSyncError.notConfigured
            }
            // Test simple : tenter d'obtenir le site ID
            _ = try await getSiteId()
            Logger.success("Connexion SharePoint réussie via Client Secret", category: "SharePointSync")
        }
    }
    
    /// Synchronise les conducteurs avec le mode approprié
    func syncDriversWithBackend(_ drivers: [DriverRecord]) async throws {
        Logger.info("Synchronisation conducteurs (mode: \(currentAuthMode))", category: "SharePointSync")
        
        switch currentAuthMode {
        case .backend:
            try await syncDriversViaBackend(drivers)
        case .clientSecret:
            try await syncDrivers(drivers)
        }
    }
    
    // MARK: - Backend Mode
    
    /// Teste la connexion via le backend
    private func testConnectionViaBackend() async throws {
        // 1. Vérifier que le backend est accessible
        let backendAccessible = await BackendTokenService.shared.testBackendConnection()
        
        await MainActor.run {
            UserDefaults.standard.set(Date(), forKey: "lastBackendCheck")
            UserDefaults.standard.set(backendAccessible, forKey: "backendAvailable")
        }
        
        guard backendAccessible else {
            throw SharePointSyncError.siteNotFound("Backend RailSkills inaccessible")
        }
        
        // 2. Obtenir un token
        let token = try await BackendTokenService.shared.getValidToken()
        
        // 3. Tester l'accès à SharePoint avec ce token
        try await testSharePointAccessWithToken(token)
        
        Logger.success("Connexion SharePoint réussie via backend", category: "SharePointSync")
    }
    
    /// Synchronise les conducteurs via le backend
    private func syncDriversViaBackend(_ drivers: [DriverRecord]) async throws {
        guard !drivers.isEmpty else {
            throw SharePointSyncError.invalidRequest
        }
        
        isSyncing = true
        syncError = nil
        
        defer {
            isSyncing = false
        }
        
        do {
            // 1. Obtenir un token valide
            let token = try await BackendTokenService.shared.getValidToken()
            
            // 2. Obtenir le site ID
            let siteId = try await getSiteIdWithToken(token)
            
            // 3. Synchroniser chaque conducteur
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let cttFolder = getCTTFolderName()
            let basePath = "RailSkills/CTT_\(cttFolder)/Data"
            
            try await ensureFolderExistsWithToken(token, siteId: siteId, folderPath: basePath)
            
            var successCount = 0
            var errors: [String] = []
            
            for driver in drivers {
                do {
                    // Utiliser l'ID du conducteur comme nom de dossier pour garantir la cohérence avec le web
                    let folderName = driver.id.uuidString
                    let driverFolderPath = "\(basePath)/\(folderName)"
                    
                    try await ensureFolderExistsWithToken(token, siteId: siteId, folderPath: driverFolderPath)
                    
                    let data = try encoder.encode(driver)
                    let fileName = "\(folderName).json"
                    
                    try await uploadFileWithToken(
                        token,
                        siteId: siteId,
                        fileName: fileName,
                        data: data,
                        folderPath: driverFolderPath,
                        overwrite: true
                    )
                    
                    successCount += 1
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
            Logger.success("\(successCount)/\(drivers.count) conducteur(s) synchronisé(s) via backend", category: "SharePointSync")
            
        } catch {
            // Si erreur 401, invalider le token et réessayer une fois
            if (error as NSError).code == 401 {
                BackendTokenService.shared.invalidateToken()
                Logger.warning("Token expiré, nouvelle tentative...", category: "SharePointSync")
                
                // Une seule retry pour éviter les boucles infinies
                try await syncDriversViaBackend(drivers)
            } else {
                syncError = error.localizedDescription
                Logger.error("Erreur synchronisation via backend: \(error.localizedDescription)", category: "SharePointSync")
                throw error
            }
        }
    }
    
    // MARK: - Méthodes utilitaires avec token
    
    /// Teste l'accès SharePoint avec un token
    private func testSharePointAccessWithToken(_ token: String) async throws {
        let siteId = try await getSiteIdWithToken(token)
        Logger.debug("Site ID obtenu: \(siteId)", category: "SharePointSync")
    }
    
    /// Obtient le site ID avec un token
    private func getSiteIdWithToken(_ token: String) async throws -> String {
        let siteEndpoint = "/sites/root:\(AzureADConfig.sharePointSite)"
        
        var request = URLRequest(url: URL(string: "https://graph.microsoft.com/v1.0\(siteEndpoint)")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let siteId = json["id"] as? String else {
            throw SharePointSyncError.invalidResponse("Site ID non trouvé dans la réponse")
        }
        
        return siteId
    }
    
    /// Crée un dossier avec un token
    private func ensureFolderExistsWithToken(_ token: String, siteId: String, folderPath: String) async throws {
        let pathComponents = folderPath.split(separator: "/")
        var currentPath = ""
        
        for component in pathComponents {
            let newPath = currentPath.isEmpty ? String(component) : "\(currentPath)/\(component)"
            let endpoint = "/sites/\(siteId)/drive/root:/\(newPath):"
            
            var request = URLRequest(url: URL(string: "https://graph.microsoft.com/v1.0\(endpoint)")!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            do {
                _ = try await URLSession.shared.data(for: request)
            } catch {
                // Dossier n'existe pas, le créer
                try await createFolderWithToken(token, siteId: siteId, folderName: String(component), parentPath: currentPath)
            }
            
            currentPath = newPath
        }
    }
    
    /// Crée un dossier avec un token
    private func createFolderWithToken(_ token: String, siteId: String, folderName: String, parentPath: String) async throws {
        let endpoint: String
        if parentPath.isEmpty {
            endpoint = "/sites/\(siteId)/drive/root/children"
        } else {
            endpoint = "/sites/\(siteId)/drive/root:/\(parentPath):/children"
        }
        
        var request = URLRequest(url: URL(string: "https://graph.microsoft.com/v1.0\(endpoint)")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "name": folderName,
            "folder": [:],
            "@microsoft.graph.conflictBehavior": "rename"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        _ = try await URLSession.shared.data(for: request)
    }
    
    /// Upload un fichier avec un token
    private func uploadFileWithToken(_ token: String, siteId: String, fileName: String, data: Data, folderPath: String, overwrite: Bool) async throws {
        let endpoint = "/sites/\(siteId)/drive/root:/\(folderPath)/\(fileName):/content"
        
        var request = URLRequest(url: URL(string: "https://graph.microsoft.com/v1.0\(endpoint)")!)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if overwrite {
            request.setValue("replace", forHTTPHeaderField: "@microsoft.graph.conflictBehavior")
        }
        
        request.httpBody = data
        _ = try await URLSession.shared.data(for: request)
    }
}


