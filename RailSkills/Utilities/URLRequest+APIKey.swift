//
//  URLRequest+APIKey.swift
//  RailSkills
//
//  Extension pour ajouter automatiquement la clé API aux requêtes
//

import Foundation

extension URLRequest {
    
    /// Ajoute automatiquement la clé API au header X-API-Key
    mutating func addAPIKey() {
        if let apiKey = APIKeyManager.shared.getAPIKey() {
            setValue(apiKey, forHTTPHeaderField: "X-API-Key")
            Logger.debug("Header X-API-Key ajouté à la requête", category: "URLRequest")
        } else {
            Logger.warning("Clé API non trouvée dans le Keychain", category: "URLRequest")
        }
    }
    
    /// Ajoute la clé API ET l'identité CTT
    mutating func addAPIKeyAndIdentity() {
        addAPIKey()
        
        // Ajouter l'identité CTT si disponible
        if OrganizationIdentityService.shared.isAuthenticated {
            setValue(OrganizationIdentityService.shared.userId, forHTTPHeaderField: "X-CTT-Identity")
        }
    }
}

