//
//  BackendTokenService.swift
//  RailSkills
//
//  Service pour obtenir des tokens SharePoint via le backend
//  Architecture sécurisée : le Client Secret reste sur le serveur
//

import Foundation
import Combine

/// Service de gestion des tokens via le backend
/// Le Client Secret ne transite jamais par l'app, il reste sur le serveur
class BackendTokenService: ObservableObject {
    
    static let shared = BackendTokenService()
    
    // MARK: - Configuration
    
    /// URL du backend RailSkills (depuis BackendConfig)
    private var backendURL: String {
        BackendConfig.backendURL
    }
    
    /// Endpoint pour obtenir un token SharePoint
    private var tokenEndpoint: String {
        BackendConfig.tokenEndpoint
    }
    
    // MARK: - State
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var cachedToken: SharePointToken?
    
    // MARK: - Models
    
    /// Token SharePoint avec métadonnées
    struct SharePointToken: Codable {
        let accessToken: String
        let expiresIn: Int
        let tokenType: String
        let obtainedAt: Date
        
        /// Vérifie si le token est encore valide (avec marge de sécurité de 5 minutes)
        var isValid: Bool {
            let expirationDate = obtainedAt.addingTimeInterval(TimeInterval(expiresIn))
            let now = Date()
            let marginDate = now.addingTimeInterval(300) // 5 minutes de marge
            return marginDate < expirationDate
        }
        
        /// Temps restant avant expiration (en secondes)
        var timeUntilExpiration: TimeInterval {
            let expirationDate = obtainedAt.addingTimeInterval(TimeInterval(expiresIn))
            return expirationDate.timeIntervalSince(Date())
        }
    }
    
    /// Réponse du backend
    private struct TokenResponse: Codable {
        let success: Bool?
        let accessToken: String
        let expiresIn: Int
        let tokenType: String
        let cached: Bool?
    }
    
    /// Erreurs possibles
    enum TokenError: LocalizedError {
        case backendUnreachable
        case invalidResponse
        case tokenExpired
        case authenticationFailed(String)
        case networkError(Error)
        
        var errorDescription: String? {
            switch self {
            case .backendUnreachable:
                return "Impossible de contacter le serveur RailSkills. Vérifiez votre connexion Internet."
            case .invalidResponse:
                return "Réponse invalide du serveur."
            case .tokenExpired:
                return "Le token a expiré. Une nouvelle demande est en cours."
            case .authenticationFailed(let message):
                return "Authentification échouée : \(message)"
            case .networkError(let error):
                return "Erreur réseau : \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Obtient un token SharePoint valide (depuis le cache ou en demandant un nouveau)
    /// - Parameter forceRefresh: Force la demande d'un nouveau token même si celui en cache est valide
    /// - Returns: Token d'accès SharePoint
    /// - Throws: TokenError en cas d'erreur
    func getValidToken(forceRefresh: Bool = false) async throws -> String {
        // Vérifier le cache si pas de refresh forcé
        if !forceRefresh, let token = cachedToken, token.isValid {
            Logger.debug("Utilisation du token en cache (expire dans \(Int(token.timeUntilExpiration))s)", category: "BackendTokenService")
            return token.accessToken
        }
        
        // Demander un nouveau token
        Logger.info("Demande d'un nouveau token au backend", category: "BackendTokenService")
        return try await requestNewToken()
    }
    
    /// Invalide le token en cache (utile en cas d'erreur 401)
    func invalidateToken() {
        cachedToken = nil
        Logger.info("Token invalidé", category: "BackendTokenService")
    }
    
    /// Teste la connexion au backend
    /// - Returns: true si le backend est accessible
    func testBackendConnection() async -> Bool {
        guard let url = URL(string: BackendConfig.healthEndpoint) else {
            return false
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            return httpResponse.statusCode == 200
        } catch {
            Logger.warning("Backend inaccessible: \(error.localizedDescription)", category: "BackendTokenService")
            return false
        }
    }
    
    // MARK: - Private Methods
    
    /// Demande un nouveau token au backend
    private func requestNewToken() async throws -> String {
        guard let url = URL(string: tokenEndpoint) else {
            throw TokenError.backendUnreachable
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Créer la requête
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.addAPIKeyAndIdentity() // Ajouter la clé API et l'identité CTT
        
        // Corps de la requête (peut contenir des infos d'authentification)
        let body: [String: Any] = [
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0",
            "platform": "iOS",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            // Effectuer la requête
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Vérifier la réponse HTTP
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TokenError.invalidResponse
            }
            
            // Gérer les différents codes de statut
            switch httpResponse.statusCode {
            case 200:
                // Succès - décoder le token
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                let tokenResponse = try decoder.decode(TokenResponse.self, from: data)
                
                // Mettre en cache
                let token = SharePointToken(
                    accessToken: tokenResponse.accessToken,
                    expiresIn: tokenResponse.expiresIn,
                    tokenType: tokenResponse.tokenType,
                    obtainedAt: Date()
                )
                
                await MainActor.run {
                    self.cachedToken = token
                    self.errorMessage = nil
                }
                
                Logger.success("Token obtenu avec succès (expire dans \(tokenResponse.expiresIn)s)", category: "BackendTokenService")
                return token.accessToken
                
            case 401:
                throw TokenError.authenticationFailed("Non autorisé")
                
            case 500...599:
                throw TokenError.authenticationFailed("Erreur serveur (code \(httpResponse.statusCode))")
                
            default:
                throw TokenError.invalidResponse
            }
            
        } catch let error as TokenError {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
            
        } catch {
            let tokenError = TokenError.networkError(error)
            await MainActor.run {
                self.errorMessage = tokenError.localizedDescription
            }
            throw tokenError
        }
    }
}

// MARK: - Extensions pour faciliter l'utilisation

extension BackendTokenService {
    
    /// Obtient un token de manière synchrone (pour compatibilité avec code existant)
    /// ⚠️ À utiliser uniquement si nécessaire, préférer la version async
    @available(*, deprecated, message: "Utilisez getValidToken() async à la place")
    func getValidTokenSync(completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                let token = try await getValidToken()
                completion(.success(token))
            } catch {
                completion(.failure(error))
            }
        }
    }
}


