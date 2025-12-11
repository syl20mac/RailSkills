//
//  BackendConfig.swift
//  RailSkills
//
//  Configuration du backend RailSkills
//  Le backend gère l'authentification Azure AD de manière sécurisée
//

import Foundation

/// Configuration centralisée du backend RailSkills
struct BackendConfig {
    
    // MARK: - URL du backend
    
    /// URL du backend RailSkills
    /// Stockée dans UserDefaults pour permettre la configuration dynamique
    static var backendURL: String {
        get {
            // Vérifier d'abord UserDefaults (configuration manuelle)
            if let savedURL = UserDefaults.standard.string(forKey: "railskills_backend_url"), !savedURL.isEmpty {
                return savedURL
            }
            
            // Sinon, utiliser la valeur par défaut
            // URL du serveur RailSkills (accessible partout)
            return "https://railskills.syl20.org"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "railskills_backend_url")
            Logger.info("URL du backend configurée: \(newValue)", category: "BackendConfig")
        }
    }
    
    /// Vérifie si une URL de backend est configurée
    static var isConfigured: Bool {
        return !backendURL.isEmpty
    }
    
    /// Réinitialise l'URL du backend à la valeur par défaut
    static func resetToDefault() {
        UserDefaults.standard.removeObject(forKey: "railskills_backend_url")
        Logger.info("URL du backend réinitialisée", category: "BackendConfig")
    }
    
    // MARK: - Endpoints
    
    /// Endpoint pour vérifier la santé du backend
    static var healthEndpoint: String {
        "\(backendURL)/api/health"
    }
    
    /// Endpoint pour obtenir un token SharePoint
    static var tokenEndpoint: String {
        "\(backendURL)/api/sharepoint/token"
    }
    
    /// Endpoint pour synchroniser les conducteurs
    static var driversEndpoint: String {
        "\(backendURL)/api/sharepoint/drivers"
    }
    
    /// Endpoint pour synchroniser les checklists
    static var checklistsEndpoint: String {
        "\(backendURL)/api/sharepoint/checklists"
    }
    
    /// Endpoint pour récupérer le secret organisationnel
    static var organizationSecretEndpoint: String {
        "\(backendURL)/api/organization/secret"
    }
    
    /// Endpoint pour vérifier l'appartenance à une organisation
    static var organizationEndpoint: String {
        "\(backendURL)/api/organization"
    }
}

