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
    
    // MARK: - Azure AD Configuration
    
    /// ID du locataire Azure AD (Tenant ID)
    static var azureTenantId: String {
        AppConfigurationService.shared.azureTenantId ?? ""
    }
    
    /// ID du client Azure AD (Application ID)
    static var azureClientId: String {
        AppConfigurationService.shared.azureClientId ?? ""
    }
    
    // MARK: - URL du backend
    
    /// URL du backend RailSkills
    /// Stockée dans UserDefaults pour permettre la configuration dynamique
    static var backendURL: String {
        get {
            // Utiliser la configuration service
            if let configuredURL = AppConfigurationService.shared.backendURL, !configuredURL.isEmpty {
                return configuredURL
            }
            
            // Si pas configuré (ou mode local), on n'a pas de backend
            return ""
        }
        set {
            // Cette méthode ne devrait plus être utilisée directement, passer par AppConfigurationService
            // Mais pour compatibilité :
            // (Note: AppConfigurationService stocke le backend séparément)
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
