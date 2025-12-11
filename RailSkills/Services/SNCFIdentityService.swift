//
//  SNCFIdentityService.swift
//  RailSkills
//
//  Service pour gérer l'identification du CTT via son identifiant SNCF
//  Permet l'isolation des données par CTT (conducteurs et checklists)
//  Supporte l'authentification via SDK SNCF_ID avec fallback vers saisie manuelle
//

import Foundation
import SwiftUI
import Combine

/// Service pour gérer l'identité du CTT (Cadre Transport Traction)
@MainActor
class SNCFIdentityService: ObservableObject {
    static let shared = SNCFIdentityService()
    
    /// Gestionnaire de session SNCF_ID (utilise l'implémentation par défaut jusqu'à ce que le SDK soit intégré)
    /// TODO: Remplacer par SNCFIDSessionManagerImpl() une fois le SDK SNCF_ID ajouté au projet
    var sessionManager: SNCFIDSessionManager = DefaultSNCFIDSessionManager()
    
    /// Identifiant SNCF du CTT (email ou ID interne)
    @AppStorage("sncfIdentity") var sncfIdentity: String = "" {
        didSet {
            objectWillChange.send()
        }
    }
    
    /// Nom complet du CTT
    @AppStorage("sncfName") var sncfName: String = "" {
        didSet {
            objectWillChange.send()
        }
    }
    
    /// Date de création du profil
    @AppStorage("sncfProfileCreatedAt") private var profileCreatedAtString: String = ""
    
    /// Indique si l'identité provient du SDK SNCF_ID (true) ou d'une saisie manuelle (false)
    @AppStorage("sncfIdentityFromSDK") private var identityFromSDK: Bool = false
    
    /// État de l'authentification en cours
    @Published var isAuthenticating: Bool = false
    
    /// Dernière erreur d'authentification (si applicable)
    @Published var lastAuthenticationError: String?
    
    private init() {
        // Vérifier si une session SNCF_ID est déjà active au démarrage
        checkSDKSession()
    }
    
    /// Vérifie si un CTT est identifié
    var isAuthenticated: Bool {
        !sncfIdentity.isEmpty && !sncfName.isEmpty
    }
    
    /// Vérifie si l'identité provient du SDK SNCF_ID
    var isUsingSDK: Bool {
        identityFromSDK && sessionManager.isSessionActive
    }
    
    /// Vérifie si le SDK SNCF_ID est disponible
    var isSDKAvailable: Bool {
        // Si le sessionManager est une instance par défaut, le SDK n'est pas implémenté
        return !(sessionManager is DefaultSNCFIDSessionManager) || sessionManager.isSessionActive
    }
    
    /// Récupère l'identifiant SNCF actuel (normalisé pour les noms de dossiers)
    var normalizedSNCFId: String {
        guard !sncfIdentity.isEmpty else { return "" }
        // Normaliser l'identifiant pour les noms de dossiers (remplacer @ par _, supprimer caractères spéciaux)
        var normalized = sncfIdentity
            .replacingOccurrences(of: "@", with: "_")
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        // Supprimer les caractères non alphanumériques sauf underscore
        normalized = normalized.components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_")).inverted).joined()
        return normalized.uppercased()
    }
    
    /// Authentifie le CTT via le SDK SNCF_ID
    /// - Parameter completion: Callback appelé avec le résultat de l'authentification
    func authenticateWithSDK(completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard !isAuthenticating else {
            Logger.warning("Authentification SNCF_ID déjà en cours", category: "SNCFIdentity")
            completion?(.failure(SNCFIDError.authenticationFailed("Authentification déjà en cours")))
            return
        }
        
        isAuthenticating = true
        lastAuthenticationError = nil
        
        sessionManager.authenticate { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isAuthenticating = false
                
                switch result {
                case .success(let session):
                    // Sauvegarder l'identité depuis la session SDK
                    self.sncfIdentity = session.sncfIdentity
                    self.sncfName = session.displayName
                    self.identityFromSDK = true
                    
                    if self.profileCreatedAtString.isEmpty {
                        self.profileCreatedAtString = ISO8601DateFormatter().string(from: Date())
                    }
                    
                    Logger.success("Authentification SNCF_ID réussie: \(session.displayName) (\(session.sncfIdentity))", category: "SNCFIdentity")
                    completion?(.success(()))
                    
                case .failure(let error):
                    self.lastAuthenticationError = error.localizedDescription
                    Logger.error("Échec de l'authentification SNCF_ID: \(error.localizedDescription)", category: "SNCFIdentity")
                    completion?(.failure(error))
                }
            }
        }
    }
    
    /// Configure l'identité du CTT manuellement (saisie manuelle)
    /// - Parameters:
    ///   - identity: Identifiant SNCF (email ou ID interne)
    ///   - name: Nom complet du CTT
    func setIdentity(identity: String, name: String) {
        let trimmedIdentity = identity.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedIdentity.isEmpty && !trimmedName.isEmpty else {
            Logger.warning("Tentative de configuration d'identité SNCF invalide (identité ou nom vide)", category: "SNCFIdentity")
            return
        }
        
        sncfIdentity = trimmedIdentity
        sncfName = trimmedName
        identityFromSDK = false // Marquer comme saisie manuelle
        
        if profileCreatedAtString.isEmpty {
            profileCreatedAtString = ISO8601DateFormatter().string(from: Date())
        }
        
        Logger.info("Identité SNCF configurée manuellement: \(trimmedName) (\(trimmedIdentity))", category: "SNCFIdentity")
    }
    
    /// Vérifie si une session SDK est active et met à jour l'identité si nécessaire
    private func checkSDKSession() {
        guard sessionManager.isSessionActive,
              let session = sessionManager.currentSession else {
            return
        }
        
        // Si une session SDK est active, mettre à jour l'identité
        if identityFromSDK || sncfIdentity.isEmpty {
            sncfIdentity = session.sncfIdentity
            sncfName = session.displayName
            identityFromSDK = true
            
            Logger.info("Session SNCF_ID détectée: \(session.displayName)", category: "SNCFIdentity")
        }
    }
    
    /// Déconnecte le CTT (efface l'identité)
    func clearIdentity() {
        // Si l'identité provient du SDK, déconnecter la session SDK
        if identityFromSDK {
            sessionManager.signOut()
        }
        
        sncfIdentity = ""
        sncfName = ""
        profileCreatedAtString = ""
        identityFromSDK = false
        lastAuthenticationError = nil
        
        Logger.info("Identité SNCF effacée", category: "SNCFIdentity")
    }
    
    /// Rafraîchit la session SNCF_ID si elle est active
    func refreshSDKSession() {
        guard identityFromSDK else { return }
        
        sessionManager.refreshSession { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                switch result {
                case .success(let session):
                    self.sncfIdentity = session.sncfIdentity
                    self.sncfName = session.displayName
                    Logger.info("Session SNCF_ID rafraîchie", category: "SNCFIdentity")
                    
                case .failure(let error):
                    Logger.warning("Échec du rafraîchissement de la session SNCF_ID: \(error.localizedDescription)", category: "SNCFIdentity")
                    // En cas d'échec, ne pas déconnecter automatiquement, mais signaler l'erreur
                    self.lastAuthenticationError = error.localizedDescription
                }
            }
        }
    }
    
    /// Récupère la date de création du profil
    var profileCreatedAt: Date? {
        guard !profileCreatedAtString.isEmpty else { return nil }
        return ISO8601DateFormatter().date(from: profileCreatedAtString)
    }
}

