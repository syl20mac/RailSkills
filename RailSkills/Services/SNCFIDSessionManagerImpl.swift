//
//  SNCFIDSessionManagerImpl.swift
//  RailSkills
//
//  Implémentation du gestionnaire de session SNCF_ID utilisant le SDK réel
//

import Foundation
import UIKit

// TODO: Décommenter une fois le SDK SNCF_ID ajouté au projet
// import SNCFID

/// Implémentation du gestionnaire de session SNCF_ID utilisant le SDK réel
class SNCFIDSessionManagerImpl: NSObject, SNCFIDSessionManager {
    
    // MARK: - Propriétés
    
    /// Indique si une session SNCF_ID est active
    var isSessionActive: Bool {
        // TODO: Décommenter une fois le SDK SNCF_ID ajouté
        // return SNCFIDService.sharedInstance?.isConnected ?? false
        return false
    }
    
    /// Récupère la session SNCF_ID actuelle (si authentifiée)
    var currentSession: SNCFIDSession? {
        guard isSessionActive else { return nil }
        
        // TODO: Décommenter une fois le SDK SNCF_ID ajouté
        // return getCurrentSessionFromSDK()
        return nil
    }
    
    // MARK: - Initialisation
    
    override init() {
        super.init()
        
        // Observer les notifications du SDK SNCF_ID
        setupNotificationObservers()
        
        // TODO: Initialiser le SDK SNCF_ID
        // Voir RailSkillsApp.swift pour l'initialisation complète
    }
    
    // MARK: - Configuration des notifications
    
    private func setupNotificationObservers() {
        // Observer l'authentification réussie
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserAuthenticated),
            name: Notification.Name("SNCFIDNotificationUserAuthenticated"),
            object: nil
        )
        
        // Observer la déconnexion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserDisconnected),
            name: Notification.Name("SNCFIDNotificationUserDisconnected"),
            object: nil
        )
        
        // Observer l'erreur d'authentification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthenticationError),
            name: Notification.Name("SNCFIDNotificationUserAuthenticationError"),
            object: nil
        )
        
        // Observer l'annulation de l'authentification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthenticationCancelled),
            name: Notification.Name("SNCFIDNotificationUserCancelAuthentification"),
            object: nil
        )
    }
    
    // MARK: - Gestion des notifications
    
    @objc private func handleUserAuthenticated() {
        Logger.info("Notification SNCF_ID: utilisateur authentifié", category: "SNCFID")
    }
    
    @objc private func handleUserDisconnected() {
        Logger.info("Notification SNCF_ID: utilisateur déconnecté", category: "SNCFID")
    }
    
    @objc private func handleAuthenticationError(_ notification: Notification) {
        if let error = notification.userInfo?["error"] as? Error {
            Logger.error("Erreur d'authentification SNCF_ID: \(error.localizedDescription)", category: "SNCFID")
        }
    }
    
    @objc private func handleAuthenticationCancelled() {
        Logger.info("Authentification SNCF_ID annulée par l'utilisateur", category: "SNCFID")
    }
    
    // MARK: - Implémentation du protocole SNCFIDSessionManager
    
    func authenticate(completion: @escaping (Result<SNCFIDSession, SNCFIDError>) -> Void) {
        // Obtenir le rootViewController de manière compatible iOS 15+
        let rootViewController: UIViewController? = {
            if #available(iOS 15.0, *) {
                // Méthode moderne pour iOS 15+
                return UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }?
                    .rootViewController
            } else {
                // Méthode legacy pour iOS < 15
                return UIApplication.shared.windows.first?.rootViewController
            }
        }()
        
        guard rootViewController != nil else {
            completion(.failure(.authenticationFailed("Impossible de trouver le view controller racine")))
            return
        }
        
        // TODO: Décommenter une fois le SDK SNCF_ID ajouté
        /*
        guard let rootViewController = rootViewController else {
            completion(.failure(.authenticationFailed("Impossible de trouver le view controller racine")))
            return
        }
        
        do {
            try SNCFIDService.sharedInstance?.connectWith(rootViewController)
            // Le résultat sera traité via les notifications et les callbacks dans l'AppDelegate
            // Pour l'instant, on attend la notification ou le callback
        } catch {
            completion(.failure(.authenticationFailed(error.localizedDescription)))
        }
        */
        
        // Pour l'instant, retourner une erreur indiquant que le SDK n'est pas encore intégré
        completion(.failure(.sdkNotAvailable))
    }
    
    func signOut() {
        // TODO: Décommenter une fois le SDK SNCF_ID ajouté
        /*
        // Obtenir le rootViewController de manière compatible iOS 15+
        let rootViewController: UIViewController? = {
            if #available(iOS 15.0, *) {
                return UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }?
                    .rootViewController
            } else {
                return UIApplication.shared.windows.first?.rootViewController
            }
        }()
        
        guard let rootViewController = rootViewController else {
            Logger.error("Impossible de trouver le view controller racine pour la déconnexion", category: "SNCFID")
            return
        }
        
        SNCFIDService.sharedInstance?.logout(with: rootViewController)
        */
        
        Logger.info("Déconnexion SNCF_ID (SDK non encore intégré)", category: "SNCFID")
    }
    
    func refreshSession(completion: @escaping (Result<SNCFIDSession, SNCFIDError>) -> Void) {
        // TODO: Décommenter une fois le SDK SNCF_ID ajouté
        /*
        SNCFIDService.sharedInstance?.authWithRefreshToken(
            withSuccess: { accessToken in
                if let session = self.getCurrentSessionFromSDK() {
                    completion(.success(session))
                } else {
                    completion(.failure(.authenticationFailed("Impossible de récupérer la session après rafraîchissement")))
                }
            },
            failure: { error in
                if let error = error {
                    completion(.failure(.authenticationFailed(error.localizedDescription)))
                } else {
                    completion(.failure(.authenticationFailed("Erreur inconnue lors du rafraîchissement")))
                }
            }
        )
        */
        
        completion(.failure(.sdkNotAvailable))
    }
    
    // MARK: - Méthodes helper
    
    /// Récupère la session actuelle depuis le SDK SNCF_ID
    private func getCurrentSessionFromSDK() -> SNCFIDSession? {
        // TODO: Décommenter et implémenter une fois le SDK SNCF_ID ajouté
        /*
        guard let sncfIDService = SNCFIDService.sharedInstance,
              sncfIDService.isConnected else {
            return nil
        }
        
        // Récupérer les informations de l'utilisateur
        var session: SNCFIDSession?
        let semaphore = DispatchSemaphore(value: 0)
        
        sncfIDService.userInfo(
            withSuccess: { userInfo in
                guard let userInfo = userInfo as? NSDictionary else {
                    semaphore.signal()
                    return
                }
                
                // Extraire les informations de l'utilisateur
                let sncfIdentity = userInfo["sub"] as? String ?? userInfo["email"] as? String ?? ""
                let displayName = "\(userInfo["given_name"] as? String ?? "") \(userInfo["family_name"] as? String ?? "")".trimmingCharacters(in: .whitespaces)
                
                // Récupérer l'access token
                var accessToken: String? = nil
                var expiresAt: Date? = nil
                
                sncfIDService.accessToken(
                    withSuccess: { token in
                        accessToken = token
                        semaphore.signal()
                    },
                    failure: { _ in
                        semaphore.signal()
                    }
                )
                
                // Créer la session
                session = SNCFIDSession(
                    sncfIdentity: sncfIdentity,
                    displayName: displayName.isEmpty ? sncfIdentity : displayName,
                    email: userInfo["email"] as? String,
                    accessToken: accessToken,
                    expiresAt: expiresAt,
                    additionalInfo: userInfo as? [String: Any]
                )
            },
            failure: { error in
                Logger.error("Erreur lors de la récupération des informations utilisateur: \(error?.localizedDescription ?? "Inconnue")", category: "SNCFID")
                semaphore.signal()
            }
        )
        
        // Attendre la réponse (avec timeout de 5 secondes)
        if semaphore.wait(timeout: .now() + 5) == .timedOut {
            Logger.warning("Timeout lors de la récupération de la session SNCF_ID", category: "SNCFID")
            return nil
        }
        
        return session
        */
        
        return nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

