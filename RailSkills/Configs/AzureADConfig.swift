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
    static let clientSecret: String? = nil  // ← Ne JAMAIS hardcoder ici pour soumission App Store
    
    /// Tenant ID Azure AD (déjà configuré)
    static let tenantId = "4a7c8238-5799-4b16-9fc6-9ad8fce5a7d9"
    
    /// App ID (Client ID) Azure AD (déjà configuré)
    static let clientId = "bd394412-97bf-4513-a59f-e023b010dff7"
    
    /// Site SharePoint (déjà configuré)
    static let sharePointSite = "sncf.sharepoint.com:/sites/railskillsgrpo365"
}

