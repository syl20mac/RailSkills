//
//  SNCFIDSession.swift
//  RailSkills
//
//  Abstraction pour le SDK SNCF_ID
//  Interface permettant d'intégrer le SDK SNCF_ID pour l'authentification automatique des CTT
//

import Foundation

/// Représente une session SNCF_ID authentifiée
struct SNCFIDSession {
    /// Identifiant SNCF unique (UPN, email ou ID interne)
    let sncfIdentity: String
    
    /// Nom complet de l'utilisateur
    let displayName: String
    
    /// Email de l'utilisateur (si disponible)
    let email: String?
    
    /// Token d'authentification (si nécessaire pour les appels API)
    let accessToken: String?
    
    /// Date d'expiration de la session
    let expiresAt: Date?
    
    /// Informations supplémentaires sur l'utilisateur (optionnel)
    let additionalInfo: [String: Any]?
}

/// Protocole pour le gestionnaire de session SNCF_ID
/// À implémenter avec le SDK SNCF_ID réel
protocol SNCFIDSessionManager {
    /// Vérifie si une session SNCF_ID est active
    var isSessionActive: Bool { get }
    
    /// Récupère la session actuelle (si authentifiée)
    var currentSession: SNCFIDSession? { get }
    
    /// Lance le processus d'authentification SNCF_ID
    /// - Parameter completion: Callback appelé avec le résultat de l'authentification
    func authenticate(completion: @escaping (Result<SNCFIDSession, SNCFIDError>) -> Void)
    
    /// Déconnecte la session SNCF_ID actuelle
    func signOut()
    
    /// Rafraîchit la session si nécessaire
    /// - Parameter completion: Callback appelé avec le résultat
    func refreshSession(completion: @escaping (Result<SNCFIDSession, SNCFIDError>) -> Void)
}

/// Erreurs possibles lors de l'authentification SNCF_ID
enum SNCFIDError: Error, LocalizedError {
    case sdkNotAvailable
    case authenticationCancelled
    case authenticationFailed(String)
    case sessionExpired
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .sdkNotAvailable:
            return "Le SDK SNCF_ID n'est pas disponible. Veuillez configurer votre identité manuellement."
        case .authenticationCancelled:
            return "Authentification annulée par l'utilisateur"
        case .authenticationFailed(let message):
            return "Échec de l'authentification : \(message)"
        case .sessionExpired:
            return "La session SNCF_ID a expiré. Veuillez vous reconnecter."
        case .invalidConfiguration:
            return "Configuration du SDK SNCF_ID invalide"
        }
    }
}

/// Implémentation par défaut du gestionnaire SNCF_ID
/// À remplacer par l'implémentation réelle du SDK SNCF_ID
/// Note: Une fois le SDK SNCF_ID intégré, utilisez SNCFIDSessionManagerImpl à la place
class DefaultSNCFIDSessionManager: SNCFIDSessionManager {
    var isSessionActive: Bool {
        // TODO: Implémenter avec le SDK SNCF_ID réel
        // Retourne false par défaut pour forcer la saisie manuelle
        return false
    }
    
    var currentSession: SNCFIDSession? {
        // TODO: Implémenter avec le SDK SNCF_ID réel
        // Retourne nil par défaut pour forcer la saisie manuelle
        return nil
    }
    
    func authenticate(completion: @escaping (Result<SNCFIDSession, SNCFIDError>) -> Void) {
        // TODO: Implémenter avec le SDK SNCF_ID réel
        // Pour l'instant, retourne une erreur indiquant que le SDK n'est pas disponible
        Logger.warning("SDK SNCF_ID non implémenté - utilisation de la saisie manuelle", category: "SNCFID")
        completion(.failure(.sdkNotAvailable))
    }
    
    func signOut() {
        // TODO: Implémenter avec le SDK SNCF_ID réel
        Logger.info("Déconnexion SNCF_ID (SDK non implémenté)", category: "SNCFID")
    }
    
    func refreshSession(completion: @escaping (Result<SNCFIDSession, SNCFIDError>) -> Void) {
        // TODO: Implémenter avec le SDK SNCF_ID réel
        completion(.failure(.sdkNotAvailable))
    }
}

