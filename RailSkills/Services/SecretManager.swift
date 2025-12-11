//
//  SecretManager.swift
//  RailSkills
//
//  Gestion sécurisée des secrets (Client Secret Azure AD) via Keychain
//

import Foundation
import Security

/// Gestion sécurisée des secrets dans la Keychain iOS
class SecretManager {
    static let shared = SecretManager()
    
    private let service = "com.railskills.azuread"
    private let account = "clientSecret"
    
    private init() {}
    
    /// Sauvegarde le Client Secret Azure AD dans la Keychain
    /// - Parameter secret: Le client secret à sauvegarder
    /// - Throws: SecretManagerError si la sauvegarde échoue
    func saveClientSecret(_ secret: String) throws {
        guard !secret.isEmpty else {
            throw SecretManagerError.invalidData
        }
        
        guard let data = secret.data(using: .utf8) else {
            throw SecretManagerError.invalidData
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Supprimer l'ancien secret s'il existe
        SecItemDelete(query as CFDictionary)
        
        // Ajouter le nouveau secret
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            Logger.error("Échec de la sauvegarde du Client Secret: \(status)", category: "SecretManager")
            throw SecretManagerError.saveFailed
        }
        
        Logger.success("Client Secret sauvegardé dans la Keychain", category: "SecretManager")
    }
    
    /// Récupère le Client Secret Azure AD
    /// Priorité : 1) Configuration intégrée (AzureADConfig), 2) Keychain (saisie manuelle)
    /// - Returns: Le client secret ou nil s'il n'existe pas
    func getClientSecret() -> String? {
        // 1. Essayer depuis la configuration intégrée (fichier AzureADConfig.swift)
        if let configSecret = AzureADConfig.clientSecret, !configSecret.isEmpty {
            Logger.info("Client Secret récupéré depuis la configuration intégrée", category: "SecretManager")
            return configSecret
        }
        
        // 2. Sinon, essayer depuis la Keychain (saisie manuelle par l'utilisateur)
        return getClientSecretFromKeychain()
    }
    
    /// Récupère le Client Secret depuis la Keychain uniquement
    /// - Returns: Le client secret de la Keychain ou nil s'il n'existe pas
    private func getClientSecretFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let secret = String(data: data, encoding: .utf8) else {
            if status == errSecItemNotFound {
                Logger.info("Client Secret non trouvé dans la Keychain", category: "SecretManager")
            } else {
                Logger.warning("Erreur lors de la récupération du Client Secret: \(status)", category: "SecretManager")
            }
            return nil
        }
        
        Logger.info("Client Secret récupéré depuis la Keychain", category: "SecretManager")
        return secret
    }
    
    /// Supprime le Client Secret de la Keychain
    func deleteClientSecret() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            Logger.error("Échec de la suppression du Client Secret: \(status)", category: "SecretManager")
            throw SecretManagerError.deleteFailed
        }
        
        Logger.success("Client Secret supprimé de la Keychain", category: "SecretManager")
    }
    
    /// Vérifie si un Client Secret est configuré
    /// Retourne true si le secret est dans la config intégrée OU dans la Keychain
    var hasClientSecret: Bool {
        // Vérifier la configuration intégrée
        if let configSecret = AzureADConfig.clientSecret, !configSecret.isEmpty {
            return true
        }
        
        // Sinon vérifier la Keychain
        return getClientSecretFromKeychain() != nil
    }
    
    /// Vérifie si le Client Secret est dans la configuration intégrée
    var hasConfigClientSecret: Bool {
        if let configSecret = AzureADConfig.clientSecret, !configSecret.isEmpty {
            return true
        }
        return false
    }
    
    /// Vérifie si le Client Secret est dans la Keychain (saisie manuelle)
    var hasKeychainClientSecret: Bool {
        return getClientSecretFromKeychain() != nil
    }
}

enum SecretManagerError: Error, LocalizedError {
    case invalidData
    case saveFailed
    case deleteFailed
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Données invalides"
        case .saveFailed:
            return "Échec de la sauvegarde dans la Keychain"
        case .deleteFailed:
            return "Échec de la suppression de la Keychain"
        case .notFound:
            return "Secret non trouvé dans la Keychain"
        }
    }
}

