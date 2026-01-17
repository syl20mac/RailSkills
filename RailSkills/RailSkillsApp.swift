//
//  RailSkillsApp.swift
//  RailSkills
//
//  Application principale - Point d'entrée de l'application
//  Architecture MVVM avec persistance UserDefaults
//

import SwiftUI

// TODO: Décommenter une fois le SDK SNCF_ID ajouté au projet
// import SNCFID

@main
struct RailSkillsApp: App {
    @StateObject private var toastManager = ToastNotificationManager()
    @StateObject private var authService = WebAuthService.shared
    @StateObject private var appConfig = AppConfigurationService.shared
    
    init() {
        // Utilisation des polices système iOS (SF Pro Rounded)
        // pour garantir la conformité App Store
        
        // TODO: Décommenter une fois le SDK SNCF_ID ajouté au projet
        // initializeSNCFIDSDK()
    }
    
    var body: some Scene {
        WindowGroup {
            // 1. Choix du mode au premier lancement
            if appConfig.appMode == .setup {
                ModeSelectionView()
                    .environmentObject(toastManager)
            }
            // 2. Mode Local : Accès direct à l'application
            else if appConfig.isLocalMode {
                ContentView()
                    .environmentObject(toastManager)
                    .toastNotifications(manager: toastManager)
                    .onOpenURL { url in
                        handleOpenURL(url)
                    }
            }
            // 3. Mode Entreprise : Authentification requise
            else {
                if authService.isAuthenticated {
                    ContentView()
                        .environmentObject(toastManager)
                        .toastNotifications(manager: toastManager)
                        .onOpenURL { url in
                            handleOpenURL(url)
                        }
                } else {
                    LoginView()
                        .environmentObject(toastManager)
                        .toastNotifications(manager: toastManager)
                }
            }
        }
    }
    
    // MARK: - Initialisation du SDK SNCF_ID
    
    /// Initialise le SDK SNCF_ID
    /// TODO: Décommenter et configurer une fois le SDK SNCF_ID ajouté au projet
    private func initializeSNCFIDSDK() {
        /*
        // Activation des logs (uniquement en développement)
        #if DEBUG
        SNCFIDLog.setTraceLevel(.debug)
        #else
        SNCFIDLog.setTraceLevel(.error)
        #endif
        
        // Définition des scopes à utiliser
        let scopes: [SNCFIDScope] = [.profile, .email, .department]
        
        // Mode Sandbox pour les tests (uniquement en DEBUG)
        #if DEBUG
        SNCFIDService.initSandbox(
            withRedirectUrl: .uri1,
            scopes: scopes,
            environment: .development
        )
        #else
        // Mode Production - Remplacez par vos identifiants réels
        // IMPORTANT: Ne pas commiter les identifiants dans le dépôt Git
        // Utilisez un fichier de configuration non versionné ou Keychain
        let clientId = "VOTRE_CLIENT_ID"
        let clientSecret = "VOTRE_CLIENT_SECRET"
        let redirectUrl = URL(string: "railskills://sncfid")!
        
        SNCFIDService.initServiceWith(
            withClientId: clientId,
            clientSecret: clientSecret,
            redirectUrl: redirectUrl,
            scopes: scopes,
            environment: .production
        )
        #endif
        
        // Configurer OrganizationIdentityService pour utiliser l'implémentation réelle du SDK
        // Note: OrganizationIdentityService est l'ancien SNCFIdentityService renommé
        // OrganizationIdentityService.shared.sessionManager = SNCFIDSessionManagerImpl()
        */
    }
    
    // MARK: - Gestion des URLs de redirection SNCF_ID
    
    /// Gère l'ouverture d'URL (pour SNCF_ID et autres)
    private func handleOpenURL(_ url: URL) {
        // TODO: Décommenter une fois le SDK SNCF_ID ajouté au projet
        /*
        // Vérifier si c'est une URL SNCF_ID
        if url.scheme == "railskills" && url.host == "sncfid" {
            SNCFIDService.sharedInstance?.processRedirectUrl(
                url,
                success: {
                    Logger.success("Authentification SNCF_ID réussie via URL", category: "SNCFID")
                    // La notification SNCFIDNotificationUserAuthenticated sera envoyée
                    // et traitée dans SNCFIDSessionManagerImpl
                },
                failure: { error in
                    Logger.error("Erreur lors du traitement de l'URL SNCF_ID: \(error?.localizedDescription ?? "Inconnue")", category: "SNCFID")
                    error?.log()
                }
            )
            return
        }
        */
        
        Logger.debug("URL ouverte: \(url.absoluteString)", category: "RailSkillsApp")
    }
}
