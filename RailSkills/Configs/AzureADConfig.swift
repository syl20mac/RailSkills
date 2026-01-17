//
//  AzureADConfig.swift
//  RailSkills
//
//  Configuration Azure AD - Client Secret
//  ⚠️ NE VERSIONNEZ PAS CE FICHIER DANS GIT !
//  Ce fichier est exclu de Git via .gitignore
//

import Foundation
import Combine

/// Configuration Azure AD pour l'accès à SharePoint
struct AzureADConfig {
    /// Client Secret Azure AD
    /// ⚠️ SÉCURITÉ : Le Client Secret ne doit JAMAIS être hardcodé dans l'application
    /// Les utilisateurs doivent le configurer manuellement via :
    /// Réglages → Synchronisation SharePoint → Configuration Azure AD
    /// 
    /// Cela garantit :
    /// - ✅ Conformité Apple App Store (Guideline 5.1.1)
    /// - ✅ Sécurité des secrets organisationnels
    /// - ✅ Possibilité de rotation des secrets sans recompilation
    static var clientSecret: String? {
        AppConfigurationService.shared.organizationSecret
    }
    
    /// Tenant ID Azure AD
    static var tenantId: String {
        AppConfigurationService.shared.azureTenantId ?? ""
    }
    
    /// App ID (Client ID) Azure AD
    static var clientId: String {
        AppConfigurationService.shared.azureClientId ?? ""
    }
    
    /// Site SharePoint (Configuration optionnelle ou par défaut)
    static var sharePointSite: String {
        // Pour l'instant on garde une valeur par défaut ou on pourrait l'ajouter à la config
        return "sncf.sharepoint.com:/sites/railskillsgrpo365"
    }
}

