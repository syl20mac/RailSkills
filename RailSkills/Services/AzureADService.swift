//
//  AzureADService.swift
//  RailSkills
//
//  Service pour l'authentification Azure AD (Client Credential Flow)
//  Permet l'accès automatique à SharePoint sans authentification utilisateur
//

import Foundation

/// Service pour l'authentification Azure AD via Client Credential Flow
class AzureADService {
    static let shared = AzureADService()
    
    // Configuration Azure AD (Client Credential Flow)
    // Ces identifiants permettent l'accès automatique à SharePoint
    private let tenantId = "4a7c8238-5799-4b16-9fc6-9ad8fce5a7d9"
    private let clientId = "bd394412-97bf-4513-a59f-e023b010dff7"
    
    private var accessToken: String?
    private var tokenExpiryDate: Date?
    
    /// Endpoint pour obtenir le token Azure AD (propriété calculée)
    private var tokenEndpoint: String {
        "https://login.microsoftonline.com/\(tenantId)/oauth2/v2.0/token"
    }
    
    private let graphEndpoint = "https://graph.microsoft.com/v1.0"
    
    private let secretManager = SecretManager.shared
    
    private init() {}
    
    /// Vérifie si l'authentification Azure AD est disponible
    /// Retourne true si le backend est configuré OU si un Client Secret local existe
    var isConfigured: Bool {
        // Backend configuré = on peut obtenir des tokens
        if BackendConfig.isConfigured {
            return true
        }
        // Sinon, fallback sur Client Secret local
        return secretManager.hasClientSecret
    }
    
    /// Récupère un access token Azure AD (Client Credential)
    /// Utilise le backend si configuré, sinon fallback sur Client Secret local
    /// - Returns: L'access token pour les appels API
    /// - Throws: AzureADError en cas d'erreur
    func getAccessToken() async throws -> String {
        // Vérifier si le token est encore valide (avec 5 min de marge)
        if let token = accessToken,
           let expiry = tokenExpiryDate,
           expiry > Date().addingTimeInterval(300) {
            return token
        }
        
        // PRIORITÉ 1 : Utiliser le backend si configuré
        if BackendConfig.isConfigured {
            Logger.info("Obtention du token via le backend", category: "AzureADService")
            do {
                let token = try await BackendTokenService.shared.getValidToken()
                // Mettre en cache le token
                self.accessToken = token
                self.tokenExpiryDate = Date().addingTimeInterval(3600) // 1 heure par défaut
                Logger.success("Token obtenu via backend", category: "AzureADService")
                return token
            } catch {
                Logger.warning("Échec du backend, tentative avec Client Secret local: \(error.localizedDescription)", category: "AzureADService")
                // Fallback sur la méthode locale si le backend échoue
            }
        }
        
        // PRIORITÉ 2 : Utiliser le Client Secret local (fallback)
        guard let clientSecret = secretManager.getClientSecret() else {
            throw AzureADError.clientSecretNotConfigured
        }
        
        // Demander un nouveau token directement à Azure AD
        guard let url = URL(string: tokenEndpoint) else {
            throw AzureADError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParams = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "scope": "https://graph.microsoft.com/.default",
            "grant_type": "client_credentials"
        ]
        
        let bodyString = bodyParams
            .map { (key, value) -> String in
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                return "\(key)=\(encodedValue)"
            }
            .joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        
        Logger.info("Demande d'access token Azure AD (mode local)", category: "AzureADService")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AzureADError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Erreur inconnue"
            Logger.error("Échec de l'authentification Azure AD: \(httpResponse.statusCode) - \(errorMessage)", category: "AzureADService")
            throw AzureADError.authenticationFailed(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["access_token"] as? String,
              let expiresIn = json["expires_in"] as? Int else {
            Logger.error("Réponse Azure AD invalide", category: "AzureADService")
            throw AzureADError.invalidResponse
        }
        
        accessToken = token
        tokenExpiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        
        Logger.success("Access token Azure AD obtenu (expire dans \(expiresIn)s)", category: "AzureADService")
        
        return token
    }
    
    /// Effectue une requête authentifiée vers Microsoft Graph API
    /// - Parameters:
    ///   - endpoint: L'endpoint Graph API (ex: "/sites/...")
    ///   - method: La méthode HTTP (GET, POST, PUT, DELETE)
    ///   - body: Les données à envoyer dans le corps de la requête (optionnel)
    /// - Returns: Les données de la réponse
    /// - Throws: AzureADError en cas d'erreur
    func authenticatedRequest(endpoint: String, method: String = "GET", body: Data? = nil) async throws -> Data {
        let token = try await getAccessToken()
        
        // Encoder le chemin pour SharePoint (les chemins avec ":" doivent être encodés)
        let encodedEndpoint: String
        if endpoint.contains("drive/root:") {
            // Pour les chemins SharePoint, encoder les caractères spéciaux sauf ":" qui est utilisé comme séparateur
            // Microsoft Graph API utilise ":" comme séparateur de chemin, donc on doit encoder le reste
            let parts = endpoint.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                let pathPart = String(parts[1])
                // Encoder les caractères spéciaux dans le chemin (sauf "/" et ":")
                let encodedPath = pathPart.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed.union(CharacterSet(charactersIn: ":"))) ?? pathPart
                encodedEndpoint = "\(parts[0]):\(encodedPath)"
            } else {
                encodedEndpoint = endpoint
            }
        } else {
            encodedEndpoint = endpoint
        }
        
        let fullEndpoint = encodedEndpoint.hasPrefix("http") ? encodedEndpoint : "\(graphEndpoint)\(encodedEndpoint)"
        
        guard let url = URL(string: fullEndpoint) else {
            Logger.error("URL invalide: \(fullEndpoint)", category: "AzureADService")
            throw AzureADError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        
        Logger.info("Requête Graph API: \(method) \(endpoint)", category: "AzureADService")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AzureADError.networkError
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Erreur inconnue"
            Logger.error("Erreur HTTP \(httpResponse.statusCode): \(errorMessage)", category: "AzureADService")
            throw AzureADError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        return data
    }
    
    /// Invalide le token actuel (force un nouveau token au prochain appel)
    func invalidateToken() {
        accessToken = nil
        tokenExpiryDate = nil
        Logger.info("Token Azure AD invalidé", category: "AzureADService")
    }
}

enum AzureADError: Error, LocalizedError {
    case invalidURL
    case clientSecretNotConfigured
    case authenticationFailed(statusCode: Int, message: String)
    case invalidResponse
    case networkError
    case httpError(statusCode: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .clientSecretNotConfigured:
            return "Client Secret Azure AD non configuré. Veuillez le configurer dans les paramètres."
        case .authenticationFailed(let code, let message):
            return "Échec de l'authentification Azure AD (\(code)): \(message)"
        case .invalidResponse:
            return "Réponse invalide du serveur Azure AD"
        case .networkError:
            return "Erreur réseau lors de la communication avec Azure AD"
        case .httpError(let code, let message):
            return "Erreur HTTP \(code): \(message)"
        }
    }
}

