//
//  APIKeyManager.swift
//  RailSkills
//
//  Gestionnaire sécurisé de la clé API backend
//  Stocke la clé dans le Keychain iOS pour une sécurité maximale
//

import Foundation
import Security

/// Gestionnaire de la clé API backend
/// Stocke de manière sécurisée la clé dans le Keychain
class APIKeyManager {
    static let shared = APIKeyManager()
    
    private let service = "com.railskills.apikey"
    private let account = "backend-api-key"
    
    // Clé API du backend (stockée dans le Keychain au premier lancement)
    private let hardcodedAPIKey = "7ad6b5c0592d82af63c28259a49452d7abfe458dabc8f4c58772459cf87ff3f9"
    
    private init() {
        // Au premier lancement, sauvegarder la clé dans le Keychain
        if getAPIKey() == nil {
            saveAPIKey(hardcodedAPIKey)
            Logger.info("Clé API initialisée dans le Keychain", category: "APIKeyManager")
        }
    }
    
    /// Récupère la clé API depuis le Keychain
    func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    /// Sauvegarde la clé API dans le Keychain
    private func saveAPIKey(_ key: String) {
        guard let data = key.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Supprimer l'ancienne clé si elle existe
        SecItemDelete(query as CFDictionary)
        
        // Ajouter la nouvelle clé
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            Logger.success("Clé API sauvegardée dans le Keychain", category: "APIKeyManager")
        } else {
            Logger.error("Erreur lors de la sauvegarde de la clé API: \(status)", category: "APIKeyManager")
        }
    }
    
    /// Met à jour la clé API (si elle change)
    func updateAPIKey(_ newKey: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        guard let data = newKey.data(using: .utf8) else { return }
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        if status == errSecSuccess {
            Logger.success("Clé API mise à jour dans le Keychain", category: "APIKeyManager")
        } else {
            // Si pas trouvé, la sauvegarder
            saveAPIKey(newKey)
        }
    }
    
    /// Supprime la clé API du Keychain
    func deleteAPIKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
        Logger.info("Clé API supprimée du Keychain", category: "APIKeyManager")
    }
}

