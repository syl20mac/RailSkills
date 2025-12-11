//
//  WebAuthService.swift
//  RailSkills
//
//  Service pour l'authentification web (email/mot de passe)
//  Permet la connexion à l'API web RailSkills-Web
//

import Foundation
import Combine
import Security

/// Service pour l'authentification web via email/mot de passe
@MainActor
class WebAuthService: ObservableObject {
    static let shared = WebAuthService()
    
    /// URL de base de l'API web (configurable)
    var baseURL: String {
        // Récupérer depuis UserDefaults ou utiliser la valeur par défaut
        if let savedURL = UserDefaults.standard.string(forKey: "web_api_base_url"), !savedURL.isEmpty {
            return savedURL
        }
        
        // Utiliser le serveur de production (railskills.syl20.org)
        return "https://railskills.syl20.org/api"
    }
    
    /// Configure l'URL de base de l'API web
    /// - Parameter url: L'URL de base (ex: "https://railskills.syl20.org/api")
    func setBaseURL(_ url: String) {
        UserDefaults.standard.set(url, forKey: "web_api_base_url")
        Logger.info("URL de l'API web configurée: \(url)", category: "WebAuth")
    }
    
    /// Token JWT actuel (stocké dans Keychain)
    @Published private(set) var authToken: String?
    
    /// Informations de l'utilisateur connecté
    @Published private(set) var currentUser: UserProfile?
    
    /// Indique si l'utilisateur est connecté
    var isAuthenticated: Bool {
        // Vérifier le mode démo de manière synchrone (UserDefaults est thread-safe)
        let isDemoModeEnabled = UserDefaults.standard.bool(forKey: "demo_mode_enabled")
        
        // En mode démo, considérer comme authentifié
        if isDemoModeEnabled {
            return true
        }
        return authToken != nil && currentUser != nil
    }
    
    /// Rôle de l'utilisateur connecté (par défaut 'user')
    var userRole: UserRole {
        let isDemoModeEnabled = UserDefaults.standard.bool(forKey: "demo_mode_enabled")
        if isDemoModeEnabled {
            return .admin
        }
        return currentUser?.effectiveRole ?? .user
    }
    
    /// Indique si l'utilisateur peut voir tous les CTT (superviseur ou admin)
    var canViewAllCTT: Bool {
        let isDemoModeEnabled = UserDefaults.standard.bool(forKey: "demo_mode_enabled")
        if isDemoModeEnabled {
            return true
        }
        return currentUser?.canViewAllCTT ?? false
    }
    
    /// Indique si l'utilisateur est administrateur
    var isAdmin: Bool {
        let isDemoModeEnabled = UserDefaults.standard.bool(forKey: "demo_mode_enabled")
        if isDemoModeEnabled {
            return true
        }
        return currentUser?.isAdmin ?? false
    }
    
    /// Indique si l'utilisateur est superviseur
    var isSupervisor: Bool {
        let isDemoModeEnabled = UserDefaults.standard.bool(forKey: "demo_mode_enabled")
        if isDemoModeEnabled {
            return true
        }
        return currentUser?.isSupervisor ?? false
    }
    
    /// État de chargement
    @Published var isLoading: Bool = false
    
    /// Dernière erreur
    @Published var lastError: String?
    
    private let keychainService = "com.railskills.auth"
    private let keychainAccount = "jwt_token"
    private let userDefaults = UserDefaults.standard
    private let userProfileKey = "web_auth_user_profile"
    
    private init() {
        // Charger le token depuis Keychain au démarrage
        loadTokenFromKeychain()
        
        // Vérifier le mode démo de manière synchrone (UserDefaults est thread-safe)
        let isDemoModeEnabled = UserDefaults.standard.bool(forKey: "demo_mode_enabled")
        
        // Si le mode démo est activé, configurer le profil de démo
        if isDemoModeEnabled {
            currentUser = UserProfile(
                id: UUID().uuidString,
                email: "demo.reviewer@sncf.fr",
                cttId: "demo.reviewer@sncf.fr",
                role: .admin,
                hasGlobalView: true,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                lastLogin: ISO8601DateFormatter().string(from: Date())
            )
            authToken = "demo_token_\(UUID().uuidString)" // Token factice pour le mode démo
            Logger.info("Mode démo activé - profil de démonstration configuré", category: "WebAuth")
        }
    }
    
    // MARK: - Authentification
    
    /// Connecte un utilisateur avec email et mot de passe
    /// - Parameters:
    ///   - email: Email de l'utilisateur
    ///   - password: Mot de passe
    /// - Returns: Le profil utilisateur
    /// - Throws: WebAuthError en cas d'erreur
    func login(email: String, password: String) async throws -> UserProfile {
        isLoading = true
        lastError = nil
        
        defer { isLoading = false }
        
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw WebAuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WebAuthError.networkError("Réponse invalide du serveur")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw WebAuthError.authenticationFailed(errorMessage?.error ?? "Erreur de connexion")
            }
            
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            
            guard let token = authResponse.token,
                  let user = authResponse.user else {
                throw WebAuthError.authenticationFailed("Réponse invalide")
            }
            
            // Sauvegarder le token et le profil
            await saveTokenToKeychain(token)
            await saveUserProfile(user)
            
            self.authToken = token
            self.currentUser = user
            
            Logger.success("Connexion réussie: \(user.email)", category: "WebAuth")
            
            return user
        } catch let error as WebAuthError {
            lastError = error.localizedDescription
            throw error
        } catch let urlError as URLError {
            // Gestion spécifique des erreurs URL
            let message: String
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                message = "Connexion au serveur impossible. Vérifiez votre connexion Internet."
            case .cannotFindHost, .cannotConnectToHost:
                message = "Serveur inaccessible. Vérifiez que le serveur est démarré et que l'URL est correcte."
            case .timedOut:
                message = "Délai d'attente dépassé. Le serveur ne répond pas."
            default:
                message = "Erreur réseau: \(urlError.localizedDescription)"
            }
            let webError = WebAuthError.networkError(message)
            lastError = webError.localizedDescription
            throw webError
        } catch {
            let webError = WebAuthError.networkError("Connexion au serveur impossible: \(error.localizedDescription)")
            lastError = webError.localizedDescription
            throw webError
        }
    }
    
    /// Crée un nouveau compte utilisateur
    /// - Parameter email: Email de l'utilisateur
    /// - Returns: Message de succès
    /// - Throws: WebAuthError en cas d'erreur
    func register(email: String, cttId: String? = nil) async throws -> String {
        isLoading = true
        lastError = nil
        
        defer { isLoading = false }
        
        guard let url = URL(string: "\(baseURL)/auth/register") else {
            throw WebAuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = ["email": email]
        if let cttId = cttId {
            body["cttId"] = cttId
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WebAuthError.networkError("Réponse invalide")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw WebAuthError.registrationFailed(errorMessage?.error ?? "Erreur lors de l'inscription")
            }
            
            let result = try JSONDecoder().decode(RegisterResponse.self, from: data)
            
            Logger.success("Inscription réussie: \(email)", category: "WebAuth")
            
            return result.message ?? "Code de vérification envoyé par email"
        } catch let error as WebAuthError {
            lastError = error.localizedDescription
            throw error
        } catch let urlError as URLError {
            // Gestion spécifique des erreurs URL
            let message: String
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                message = "Connexion au serveur impossible. Vérifiez votre connexion Internet."
            case .cannotFindHost, .cannotConnectToHost:
                message = "Serveur inaccessible. Vérifiez que le serveur est démarré et que l'URL est correcte."
            case .timedOut:
                message = "Délai d'attente dépassé. Le serveur ne répond pas."
            default:
                message = "Erreur réseau: \(urlError.localizedDescription)"
            }
            let webError = WebAuthError.networkError(message)
            lastError = webError.localizedDescription
            throw webError
        } catch {
            let webError = WebAuthError.networkError("Connexion au serveur impossible: \(error.localizedDescription)")
            lastError = webError.localizedDescription
            throw webError
        }
    }
    
    /// Vérifie le code de vérification
    /// - Parameters:
    ///   - email: Email de l'utilisateur
    ///   - code: Code de vérification à 6 chiffres
    /// - Throws: WebAuthError en cas d'erreur
    func verifyCode(email: String, code: String) async throws {
        isLoading = true
        lastError = nil
        
        defer { isLoading = false }
        
        guard let url = URL(string: "\(baseURL)/auth/verify-code") else {
            throw WebAuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email,
            "code": code
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WebAuthError.networkError("Réponse invalide")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw WebAuthError.verificationFailed(errorMessage?.error ?? "Code invalide")
            }
            
            Logger.success("Code vérifié avec succès", category: "WebAuth")
        } catch let error as WebAuthError {
            lastError = error.localizedDescription
            throw error
        } catch let urlError as URLError {
            // Gestion spécifique des erreurs URL
            let message: String
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                message = "Connexion au serveur impossible. Vérifiez votre connexion Internet."
            case .cannotFindHost, .cannotConnectToHost:
                message = "Serveur inaccessible. Vérifiez que le serveur est démarré et que l'URL est correcte."
            case .timedOut:
                message = "Délai d'attente dépassé. Le serveur ne répond pas."
            default:
                message = "Erreur réseau: \(urlError.localizedDescription)"
            }
            let webError = WebAuthError.networkError(message)
            lastError = webError.localizedDescription
            throw webError
        } catch {
            let webError = WebAuthError.networkError("Connexion au serveur impossible: \(error.localizedDescription)")
            lastError = webError.localizedDescription
            throw webError
        }
    }
    
    /// Définit le mot de passe après vérification du code
    /// - Parameters:
    ///   - email: Email de l'utilisateur
    ///   - code: Code de vérification
    ///   - password: Nouveau mot de passe
    /// - Returns: Le profil utilisateur
    /// - Throws: WebAuthError en cas d'erreur
    func setPassword(email: String, code: String, password: String) async throws -> UserProfile {
        isLoading = true
        lastError = nil
        
        defer { isLoading = false }
        
        guard let url = URL(string: "\(baseURL)/auth/set-password") else {
            throw WebAuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email,
            "code": code,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WebAuthError.networkError("Réponse invalide")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw WebAuthError.passwordSetFailed(errorMessage?.error ?? "Erreur lors de la définition du mot de passe")
            }
            
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            
            guard let token = authResponse.token,
                  let user = authResponse.user else {
                throw WebAuthError.passwordSetFailed("Réponse invalide")
            }
            
            // Sauvegarder le token et le profil
            await saveTokenToKeychain(token)
            await saveUserProfile(user)
            
            self.authToken = token
            self.currentUser = user
            
            Logger.success("Mot de passe défini et connexion réussie: \(user.email)", category: "WebAuth")
            
            return user
        } catch let error as WebAuthError {
            lastError = error.localizedDescription
            throw error
        } catch let urlError as URLError {
            // Gestion spécifique des erreurs URL
            let message: String
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                message = "Connexion au serveur impossible. Vérifiez votre connexion Internet."
            case .cannotFindHost, .cannotConnectToHost:
                message = "Serveur inaccessible. Vérifiez que le serveur est démarré et que l'URL est correcte."
            case .timedOut:
                message = "Délai d'attente dépassé. Le serveur ne répond pas."
            default:
                message = "Erreur réseau: \(urlError.localizedDescription)"
            }
            let webError = WebAuthError.networkError(message)
            lastError = webError.localizedDescription
            throw webError
        } catch {
            let webError = WebAuthError.networkError("Connexion au serveur impossible: \(error.localizedDescription)")
            lastError = webError.localizedDescription
            throw webError
        }
    }
    
    /// Demande un code de réinitialisation de mot de passe
    /// - Parameter email: Email de l'utilisateur
    /// - Throws: WebAuthError en cas d'erreur
    func forgotPassword(email: String) async throws {
        isLoading = true
        lastError = nil
        
        defer { isLoading = false }
        
        guard let url = URL(string: "\(baseURL)/auth/forgot-password") else {
            throw WebAuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["email": email]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WebAuthError.networkError("Réponse invalide")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw WebAuthError.networkError(errorMessage?.error ?? "Erreur lors de la demande de réinitialisation")
            }
            
            Logger.success("Code de réinitialisation envoyé à \(email)", category: "WebAuth")
        } catch let error as WebAuthError {
            lastError = error.localizedDescription
            throw error
        } catch let urlError as URLError {
            // Gestion spécifique des erreurs URL
            let message: String
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                message = "Connexion au serveur impossible. Vérifiez votre connexion Internet."
            case .cannotFindHost, .cannotConnectToHost:
                message = "Serveur inaccessible. Vérifiez que le serveur est démarré et que l'URL est correcte."
            case .timedOut:
                message = "Délai d'attente dépassé. Le serveur ne répond pas."
            default:
                message = "Erreur réseau: \(urlError.localizedDescription)"
            }
            let webError = WebAuthError.networkError(message)
            lastError = webError.localizedDescription
            throw webError
        } catch {
            let webError = WebAuthError.networkError("Connexion au serveur impossible: \(error.localizedDescription)")
            lastError = webError.localizedDescription
            throw webError
        }
    }
    
    /// Récupère les informations de l'utilisateur connecté
    /// - Throws: WebAuthError en cas d'erreur
    func getCurrentUser() async throws -> UserProfile {
        guard let token = authToken else {
            throw WebAuthError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/auth/me") else {
            throw WebAuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WebAuthError.networkError("Réponse invalide")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    // Token invalide, déconnecter
                    await logout()
                    throw WebAuthError.notAuthenticated
                }
                throw WebAuthError.networkError("Erreur lors de la récupération du profil")
            }
            
            let user = try JSONDecoder().decode(UserProfile.self, from: data)
            await saveUserProfile(user)
            self.currentUser = user
            
            return user
        } catch let error as WebAuthError {
            throw error
        } catch {
            throw WebAuthError.networkError(error.localizedDescription)
        }
    }
    
    /// Déconnecte l'utilisateur
    func logout() async {
        // Ne pas déconnecter en mode démo
        let isDemoModeEnabled = UserDefaults.standard.bool(forKey: "demo_mode_enabled")
        if isDemoModeEnabled {
            Logger.info("Mode démo actif - déconnexion ignorée", category: "WebAuth")
            return
        }
        
        // Supprimer le token et le profil
        await deleteTokenFromKeychain()
        userDefaults.removeObject(forKey: userProfileKey)
        
        self.authToken = nil
        self.currentUser = nil
        
        Logger.info("Déconnexion réussie", category: "WebAuth")
    }
    
    /// Active le mode démonstration (pour les reviewers Apple)
    func enableDemoMode() async {
        // Activer le mode démo dans UserDefaults
        UserDefaults.standard.set(true, forKey: "demo_mode_enabled")
        
        // Configurer le profil de démo
        self.currentUser = UserProfile(
            id: UUID().uuidString,
            email: "demo.reviewer@sncf.fr",
            cttId: "demo.reviewer@sncf.fr",
            role: .admin,
            hasGlobalView: true,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            lastLogin: ISO8601DateFormatter().string(from: Date())
        )
        self.authToken = "demo_token_\(UUID().uuidString)"
        
        Logger.success("Mode démonstration activé", category: "WebAuth")
    }
    
    /// Vérifie si le token JWT est valide (non expiré)
    /// - Returns: true si le token est valide, false sinon
    func isTokenValid() -> Bool {
        guard let token = authToken else {
            return false
        }
        
        // Décoder le JWT pour vérifier l'expiration
        // Format JWT: header.payload.signature
        let parts = token.split(separator: ".")
        guard parts.count == 3 else {
            Logger.warning("Token JWT invalide (format incorrect)", category: "WebAuth")
            return false
        }
        
        // Décoder le payload (base64url)
        guard let payloadData = base64URLDecode(String(parts[1])) else {
            Logger.warning("Impossible de décoder le payload JWT", category: "WebAuth")
            return false
        }
        
        do {
            if let payload = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
               let exp = payload["exp"] as? TimeInterval {
                let expirationDate = Date(timeIntervalSince1970: exp)
                let isValid = expirationDate > Date()
                
                if !isValid {
                    Logger.warning("Token JWT expiré (expire le \(expirationDate))", category: "WebAuth")
                }
                
                return isValid
            }
        } catch {
            Logger.error("Erreur lors du décodage du payload JWT: \(error.localizedDescription)", category: "WebAuth")
        }
        
        // Si pas de date d'expiration, considérer comme valide (mais avec avertissement)
        Logger.warning("Token JWT sans date d'expiration, considéré comme valide", category: "WebAuth")
        return true
    }
    
    /// Décode une chaîne base64url (JWT utilise base64url, pas base64 standard)
    private func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Ajouter le padding si nécessaire
        let remainder = base64.count % 4
        if remainder > 0 {
            base64.append(String(repeating: "=", count: 4 - remainder))
        }
        
        return Data(base64Encoded: base64)
    }
    
    /// Récupère un token valide ou nil si expiré
    /// - Returns: Le token JWT si valide, nil sinon
    func getValidToken() -> String? {
        if isTokenValid() {
            return authToken
        }
        
        // Token expiré, nettoyer et retourner nil
        Logger.warning("Token JWT expiré, déconnexion automatique", category: "WebAuth")
        Task {
            await logout()
            // Notifier que le token a expiré
            await MainActor.run {
                NotificationCenter.default.post(name: NSNotification.Name("TokenExpired"), object: nil)
            }
        }
        return nil
    }
    
    /// Récupère le token d'authentification pour les requêtes API
    /// - Returns: Le token JWT ou nil si non authentifié
    func getAuthToken() -> String? {
        return authToken
    }
    
    // MARK: - Keychain Management
    
    /// Charge le token depuis Keychain
    private func loadTokenFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let token = String(data: data, encoding: .utf8) {
            self.authToken = token
            
            // Charger aussi le profil utilisateur
            if let profileData = userDefaults.data(forKey: userProfileKey),
               let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
                self.currentUser = profile
            }
            
            Logger.info("Token chargé depuis Keychain", category: "WebAuth")
        }
    }
    
    /// Sauvegarde le token dans Keychain
    private func saveTokenToKeychain(_ token: String) async {
        // Supprimer l'ancien token s'il existe
        await deleteTokenFromKeychain()
        
        guard let data = token.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            Logger.info("Token sauvegardé dans Keychain", category: "WebAuth")
        } else {
            Logger.error("Erreur lors de la sauvegarde du token: \(status)", category: "WebAuth")
        }
    }
    
    /// Supprime le token de Keychain
    private func deleteTokenFromKeychain() async {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    /// Sauvegarde le profil utilisateur
    private func saveUserProfile(_ profile: UserProfile) async {
        if let data = try? JSONEncoder().encode(profile) {
            userDefaults.set(data, forKey: userProfileKey)
        }
    }
}

// MARK: - Models

/// Rôle de l'utilisateur dans le système RailSkills
/// - user: Accès limité à son propre CTT
/// - supervisor: Vue globale de tous les CTT (lecture seule)
/// - admin: Accès complet à tous les CTT + gestion des utilisateurs
enum UserRole: String, Codable {
    case user = "user"
    case supervisor = "supervisor"
    case admin = "admin"
    
    /// Libellé localisé du rôle
    var displayName: String {
        switch self {
        case .user:
            return "Utilisateur"
        case .supervisor:
            return "Superviseur"
        case .admin:
            return "Administrateur"
        }
    }
}

/// Profil utilisateur
struct UserProfile: Codable {
    let id: String
    let email: String
    let cttId: String
    let role: UserRole?          // Rôle de l'utilisateur (optionnel pour compatibilité)
    let hasGlobalView: Bool?     // Indique si l'utilisateur peut voir tous les CTT
    let createdAt: String?
    let lastLogin: String?
    
    /// Vérifie si l'utilisateur peut voir tous les CTT (superviseur ou admin)
    var canViewAllCTT: Bool {
        return hasGlobalView == true || role == .supervisor || role == .admin
    }
    
    /// Vérifie si l'utilisateur est administrateur
    var isAdmin: Bool {
        return role == .admin
    }
    
    /// Vérifie si l'utilisateur est superviseur
    var isSupervisor: Bool {
        return role == .supervisor
    }
    
    /// Rôle effectif (par défaut 'user' si non spécifié)
    var effectiveRole: UserRole {
        return role ?? .user
    }
}

/// Réponse d'authentification
struct AuthResponse: Codable {
    let success: Bool
    let token: String?
    let user: UserProfile?
    let error: String?
    let message: String?
}

/// Réponse d'inscription
struct RegisterResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}

/// Réponse d'erreur
struct ErrorResponse: Codable {
    let error: String
}

// MARK: - Errors

enum WebAuthError: LocalizedError {
    case invalidURL
    case networkError(String)
    case authenticationFailed(String)
    case registrationFailed(String)
    case verificationFailed(String)
    case passwordSetFailed(String)
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .networkError(let message):
            return "Erreur réseau: \(message)"
        case .authenticationFailed(let message):
            return "Échec de l'authentification: \(message)"
        case .registrationFailed(let message):
            return "Échec de l'inscription: \(message)"
        case .verificationFailed(let message):
            return "Échec de la vérification: \(message)"
        case .passwordSetFailed(let message):
            return "Échec de la définition du mot de passe: \(message)"
        case .notAuthenticated:
            return "Non authentifié"
        }
    }
}

