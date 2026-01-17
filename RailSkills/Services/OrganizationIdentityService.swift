//
//  OrganizationIdentityService.swift
//  RailSkills
//
//  Service pour gérer l'identification de l'utilisateur (CTT)
//  Permet l'isolation des données par utilisateur
//  Supporte l'authentification (Mode Entreprise) ou le mode local
//

import Foundation
import SwiftUI
import Combine

/// Service pour gérer l'identité de l'utilisateur
@MainActor
class OrganizationIdentityService: ObservableObject {
    static let shared = OrganizationIdentityService()
    
    // MARK: - Properties
    
    /// Indique si le SDK d'authentification (ex: SNCF_ID) est disponible
    var isSDKAvailable: Bool {
        return false // Pour la version générique, le SDK est désactivé par défaut
    }
    
    /// Indique si l'utilisateur utilise l'authentification via SDK
    @AppStorage("org_using_sdk") var isUsingSDK: Bool = false
    
    /// Identifiant unique de l'utilisateur (ex: email ou matricule)
    @AppStorage("org_user_id") var userId: String = "" {
        didSet { objectWillChange.send() }
    }
    
    /// Nom complet de l'utilisateur
    @AppStorage("org_user_name") var displayName: String = "" {
        didSet { objectWillChange.send() }
    }
    
    /// Date de création du profil
    @AppStorage("org_profile_created_at") private var profileCreatedAtString: String = ""
    
    /// État de l'authentification en cours
    @Published var isAuthenticating: Bool = false
    
    /// Dernière erreur d'authentification
    @Published var lastAuthenticationError: String?
    
    private init() {
        // En mode local, on configure une identité par défaut si nécessaire
        if AppConfigurationService.shared.isLocalMode && userId.isEmpty {
            setupLocalIdentity()
        }
    }
    
    // MARK: - Computed Properties
    
    /// Vérifie si un utilisateur est identifié
    var isAuthenticated: Bool {
        !userId.isEmpty && !displayName.isEmpty
    }
    
    /// Récupère l'identifiant normalisé pour les noms de dossiers
    /// Ex: sylvain.gallon@sncf.fr -> SYLVAIN_GALLON_SNCF_FR
    var normalizedUserId: String {
        guard !userId.isEmpty else { return "" }
        if AppConfigurationService.shared.isLocalMode {
            return "LOCAL_USER"
        }
        
        var normalized = userId
            .replacingOccurrences(of: "@", with: "_")
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        
        normalized = normalized.components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_")).inverted).joined()
        return normalized.uppercased()
    }
    
    // MARK: - Methods
    
    /// Configure une identité locale par défaut
    func setupLocalIdentity() {
        self.userId = "local_user"
        self.displayName = "Utilisateur Local"
        if self.profileCreatedAtString.isEmpty {
            self.profileCreatedAtString = ISO8601DateFormatter().string(from: Date())
        }
        Logger.info("Identité locale configurée", category: "Identity")
    }
    
    /// Configure l'identité manuellement (ex: après scan QR Code ou Login)
    func setIdentity(userId: String, name: String) {
        let trimmedId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedId.isEmpty && !trimmedName.isEmpty else {
            Logger.warning("Tentative de configuration d'identité invalide", category: "Identity")
            return
        }
        
        self.userId = trimmedId
        self.displayName = trimmedName
        
        if self.profileCreatedAtString.isEmpty {
            self.profileCreatedAtString = ISO8601DateFormatter().string(from: Date())
        }
        
        Logger.info("Identité configurée: \(trimmedName) (\(trimmedId))", category: "Identity")
    }
    
    /// Authentifie l'utilisateur via le SDK
    func authenticateWithSDK(completion: @escaping (Result<Void, Error>) -> Void) {
        // Implémentation bouchon - le SDK n'est pas disponible dans la version générique
        completion(.failure(NSError(domain: "OrganizationIdentityService", code: 404, userInfo: [NSLocalizedDescriptionKey: "SDK non disponible"])))
    }

    /// Déconnecte l'utilisateur
    func clearIdentity() {
        self.userId = ""
        self.displayName = ""
        self.profileCreatedAtString = ""
        self.lastAuthenticationError = nil
        self.isUsingSDK = false
        
        Logger.info("Identité effacée", category: "Identity")
        
        // Si on déconnecte, on repasse peut-être en mode non configuré ou local ?
        // Pour l'instant on garde le mode actuel
    }
    
    /// Récupère la date de création du profil
    var profileCreatedAt: Date? {
        guard !profileCreatedAtString.isEmpty else { return nil }
        return ISO8601DateFormatter().date(from: profileCreatedAtString)
    }
}

// MARK: - Compatibility Aliases
// Pour la migration progressive, on garde les anciens noms si nécessaire
extension OrganizationIdentityService {
    var sncfIdentity: String {
        get { userId }
        set { userId = newValue }
    }
    
    var sncfName: String {
        get { displayName }
        set { displayName = newValue }
    }
    
    var normalizedSNCFId: String {
        normalizedUserId
    }
}
