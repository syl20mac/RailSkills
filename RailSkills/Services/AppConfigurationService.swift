//
//  AppConfigurationService.swift
//  RailSkills
//
//  Service de configuration centralisé.
//  Gère le stockage sécurisé des identifiants et le mode de l'application.
//

import Foundation
import Combine
import SwiftUI

class AppConfigurationService: ObservableObject {
    
    static let shared = AppConfigurationService()
    
    // MARK: - App Mode
    
    @AppStorage("app_mode") private var appModeRaw: String = AppMode.setup.rawValue
    
    var appMode: AppMode {
        get { AppMode(rawValue: appModeRaw) ?? .setup }
        set { appModeRaw = newValue.rawValue }
    }
    
    var isLocalMode: Bool {
        return appMode == .local
    }
    
    // MARK: - Configuration Keys
    
    private let kAzureTenantID = "config_azure_tenant_id"
    private let kAzureClientID = "config_azure_client_id"
    private let kBackendURL = "config_backend_url"
    private let kOrganizationName = "config_org_name"
    private let kOrganizationSecret = "config_org_secret"
    private let kAllowChecklistUpload = "config_allow_checklist_upload"
    
    // MARK: - Properties
    
    @Published var isConfigured: Bool = false
    @AppStorage("config_allow_checklist_upload") var allowChecklistUpload: Bool = true
    
    init() {
        self.isConfigured = checkConfiguration()
    }
    
    // MARK: - Accessors
    
    var azureTenantId: String? {
        // En mode local, on n'a pas besoin de Tenant ID
        if isLocalMode { return nil }
        return UserDefaults.standard.string(forKey: kAzureTenantID)
    }
    
    var azureClientId: String? {
        if isLocalMode { return nil }
        return UserDefaults.standard.string(forKey: kAzureClientID)
    }
    
    var backendURL: String? {
        if isLocalMode { return nil }
        return UserDefaults.standard.string(forKey: kBackendURL)
    }
    
    var organizationName: String {
        if isLocalMode { return "Mon Compte Local" }
        return UserDefaults.standard.string(forKey: kOrganizationName) ?? "Organisation Inconnue"
    }
    
    var organizationSecret: String? {
        if isLocalMode { return nil }
        // TODO: Devrait être stocké dans le Keychain pour plus de sécurité
        return UserDefaults.standard.string(forKey: kOrganizationSecret)
    }
    
    // MARK: - Configuration Methods
    
    /// Configure l'application avec les paramètres fournis
    func configure(tenantId: String, clientId: String, backendUrl: String, orgName: String, orgSecret: String?) {
        UserDefaults.standard.set(tenantId, forKey: kAzureTenantID)
        UserDefaults.standard.set(clientId, forKey: kAzureClientID)
        UserDefaults.standard.set(backendUrl, forKey: kBackendURL)
        UserDefaults.standard.set(orgName, forKey: kOrganizationName)
        if let secret = orgSecret {
            UserDefaults.standard.set(secret, forKey: kOrganizationSecret)
        }
        
        // Bascule automatique en mode entreprise
        self.appMode = .enterprise
        self.isConfigured = true
        
        Logger.info("Application configurée pour \(orgName)", category: "AppConfig")
    }
    
    /// Passe l'application en mode local
    func enableLocalMode() {
        self.appMode = .local
        self.isConfigured = true
        Logger.info("Passage en mode Local", category: "AppConfig")
    }
    
    /// Vérifie si la configuration minimale est présente
    private func checkConfiguration() -> Bool {
        if appMode == .setup { return false }
        if isLocalMode { return true }
        
        // En mode entreprise, il faut les IDs Azure
        guard let _ = azureTenantId, let _ = azureClientId else {
            return false
        }
        return true
    }
    
    /// Réinitialise toute la configuration
    func resetConfiguration() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: kAzureTenantID)
        defaults.removeObject(forKey: kAzureClientID)
        defaults.removeObject(forKey: kBackendURL)
        defaults.removeObject(forKey: kOrganizationName)
        defaults.removeObject(forKey: kOrganizationSecret)
        defaults.removeObject(forKey: kAllowChecklistUpload)
        
        // Retour au mode par défaut (setup) ou non configuré
        self.appMode = .setup
        self.isConfigured = false
        
        Logger.info("Configuration réinitialisée", category: "AppConfig")
    }
}
