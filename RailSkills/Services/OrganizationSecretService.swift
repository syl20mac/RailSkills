//
//  OrganizationSecretService.swift
//  RailSkills
//
//  Service pour gérer le secret organisationnel via le backend
//  Le secret est synchronisé avec le serveur pour tous les CTT de l'organisation
//

import Foundation
import Combine

/// Service de gestion du secret organisationnel via le backend
class OrganizationSecretService: ObservableObject {
    
    static let shared = OrganizationSecretService()
    
    // MARK: - State
    
    @Published var isLoading = false
    @Published var isSynced = false
    @Published var errorMessage: String?
    @Published var organizationName: String?
    
    /// Clé pour stocker le secret en cache local
    private let secretCacheKey = "railskills_org_secret_cache"
    private let lastSyncKey = "railskills_org_secret_last_sync"
    
    // MARK: - Models
    
    /// Réponse du backend pour le secret organisationnel
    private struct OrganizationSecretResponse: Codable {
        let success: Bool?
        let secret: String
        let organizationName: String
        let updatedAt: String
    }
    
    /// Erreurs possibles
    enum SecretError: LocalizedError {
        case backendUnreachable
        case notAuthenticated
        case noOrganization
        case invalidResponse
        case networkError(Error)
        
        var errorDescription: String? {
            switch self {
            case .backendUnreachable:
                return "Impossible de contacter le serveur."
            case .notAuthenticated:
                return "Vous devez être connecté pour synchroniser le secret."
            case .noOrganization:
                return "Aucune organisation associée à votre compte."
            case .invalidResponse:
                return "Réponse invalide du serveur."
            case .networkError(let error):
                return "Erreur réseau : \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Récupère le secret organisationnel depuis le backend
    /// - Parameter forceRefresh: Force la synchronisation même si le cache est récent
    /// - Returns: Le secret organisationnel
    func getOrganizationSecret(forceRefresh: Bool = false) async throws -> String {
        // Vérifier le cache si pas de refresh forcé
        if !forceRefresh, let cachedSecret = getCachedSecret(), !shouldRefreshCache() {
            Logger.debug("Utilisation du secret en cache", category: "OrganizationSecretService")
            return cachedSecret
        }
        
        // Synchroniser avec le backend
        return try await syncSecretFromBackend()
    }
    
    /// Synchronise le secret depuis le backend
    func syncSecretFromBackend() async throws -> String {
        guard BackendConfig.isConfigured else {
            throw SecretError.backendUnreachable
        }
        
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: BackendConfig.organizationSecretEndpoint) else {
            throw SecretError.backendUnreachable
        }
        
        // Créer la requête avec le token d'authentification
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.addAPIKeyAndIdentity() // Ajouter la clé API et l'identité CTT
        
        // Ajouter le token si disponible
        if let token = BackendTokenService.shared.cachedToken?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SecretError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                let secretResponse = try decoder.decode(OrganizationSecretResponse.self, from: data)
                
                // Mettre en cache
                cacheSecret(secretResponse.secret)
                
                // Mettre à jour EncryptionService
                EncryptionService.setOrganizationSecret(secretResponse.secret)
                
                await MainActor.run {
                    self.organizationName = secretResponse.organizationName
                    self.isSynced = true
                    self.errorMessage = nil
                }
                
                Logger.success("Secret organisationnel synchronisé (\(secretResponse.organizationName))", category: "OrganizationSecretService")
                return secretResponse.secret
                
            case 401:
                throw SecretError.notAuthenticated
                
            case 404:
                throw SecretError.noOrganization
                
            default:
                throw SecretError.invalidResponse
            }
            
        } catch let error as SecretError {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
            
        } catch {
            let secretError = SecretError.networkError(error)
            await MainActor.run {
                self.errorMessage = secretError.localizedDescription
            }
            throw secretError
        }
    }
    
    /// Vérifie si le secret est synchronisé
    func checkSyncStatus() async {
        // Vérifier si on a un cache récent
        if getCachedSecret() != nil && !shouldRefreshCache() {
            await MainActor.run {
                self.isSynced = true
            }
            return
        }
        
        // Tenter une synchronisation silencieuse
        do {
            _ = try await syncSecretFromBackend()
        } catch {
            Logger.warning("Impossible de synchroniser le secret: \(error.localizedDescription)", category: "OrganizationSecretService")
        }
    }
    
    /// Retourne le secret actuel (cache ou défaut)
    func getCurrentSecret() -> String {
        if let cached = getCachedSecret() {
            return cached
        }
        return EncryptionService.getOrganizationSecret()
    }
    
    // MARK: - Private Methods
    
    /// Récupère le secret depuis le cache local
    private func getCachedSecret() -> String? {
        return UserDefaults.standard.string(forKey: secretCacheKey)
    }
    
    /// Met en cache le secret
    private func cacheSecret(_ secret: String) {
        UserDefaults.standard.set(secret, forKey: secretCacheKey)
        UserDefaults.standard.set(Date(), forKey: lastSyncKey)
    }
    
    /// Vérifie si le cache doit être rafraîchi (toutes les 24h)
    private func shouldRefreshCache() -> Bool {
        guard let lastSync = UserDefaults.standard.object(forKey: lastSyncKey) as? Date else {
            return true
        }
        
        let timeSinceLastSync = Date().timeIntervalSince(lastSync)
        let oneDayInSeconds: TimeInterval = 24 * 60 * 60
        
        return timeSinceLastSync > oneDayInSeconds
    }
    
    /// Efface le cache local
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: secretCacheKey)
        UserDefaults.standard.removeObject(forKey: lastSyncKey)
        isSynced = false
        Logger.info("Cache du secret organisationnel effacé", category: "OrganizationSecretService")
    }
}

