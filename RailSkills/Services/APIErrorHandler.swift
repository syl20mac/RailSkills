//
//  APIErrorHandler.swift
//  RailSkills
//
//  Helper pour gérer les erreurs API de manière centralisée
//  Gère spécifiquement l'erreur 401 (token expiré)
//

import Foundation

/// Helper pour gérer les erreurs API de manière centralisée
@MainActor
class APIErrorHandler {
    
    /// Gère les erreurs HTTP de manière centralisée
    /// - Parameters:
    ///   - statusCode: Code de statut HTTP
    ///   - data: Données de la réponse (pour extraire le message d'erreur)
    /// - Returns: Message d'erreur formaté pour l'utilisateur
    /// - Throws: APIError si c'est une erreur d'authentification (401)
    static func handleHTTPError(statusCode: Int, data: Data?) async throws -> String {
        switch statusCode {
        case 401:
            // Token expiré ou invalide
            Logger.warning("Erreur HTTP 401 - Token expiré ou invalide", category: "APIErrorHandler")
            
            // Nettoyer le token et déconnecter l'utilisateur
            await WebAuthService.shared.logout()
            
            // Notifier que le token a expiré
            await MainActor.run {
                NotificationCenter.default.post(name: NSNotification.Name("TokenExpired"), object: nil)
            }
            
            throw APIError.authenticationRequired("Votre session a expiré. Veuillez vous reconnecter.")
            
        case 400...499:
            // Erreur client
            let errorMessage = extractErrorMessage(from: data) ?? "Erreur de requête"
            return errorMessage
            
        case 500...599:
            // Erreur serveur
            let errorMessage = extractErrorMessage(from: data) ?? "Erreur serveur"
            return "Erreur serveur : \(errorMessage)"
            
        default:
            // Autre erreur
            let errorMessage = extractErrorMessage(from: data) ?? "Erreur inconnue"
            return "Erreur HTTP \(statusCode): \(errorMessage)"
        }
    }
    
    /// Extrait le message d'erreur depuis les données JSON
    /// - Parameter data: Données de la réponse
    /// - Returns: Message d'erreur extrait ou nil
    private static func extractErrorMessage(from data: Data?) -> String? {
        guard let data = data else { return nil }
        
        // Essayer de parser le JSON
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Chercher différents champs possibles pour le message d'erreur
            if let error = json["error"] as? String {
                return error
            }
            if let message = json["message"] as? String {
                return message
            }
            if let errorMessage = json["errorMessage"] as? String {
                return errorMessage
            }
        }
        
        // Si ce n'est pas du JSON, essayer de le lire comme string
        if let string = String(data: data, encoding: .utf8), !string.isEmpty {
            // Nettoyer le message (enlever les accolades JSON si présentes)
            let cleaned = string
                .replacingOccurrences(of: #"\{[^}]*"error"[^}]*"([^"]+)"[^}]*\}"#, with: "$1", options: .regularExpression)
                .replacingOccurrences(of: #"\{[^}]*"message"[^}]*"([^"]+)"[^}]*\}"#, with: "$1", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !cleaned.isEmpty && cleaned != string {
                return cleaned
            }
            
            return string
        }
        
        return nil
    }
    
    /// Formate un message d'erreur pour l'utilisateur
    /// - Parameter error: Message d'erreur brut
    /// - Returns: Message formaté et clair pour l'utilisateur
    nonisolated static func formatErrorMessage(_ error: String) -> String {
        let message = error
        
        // Remplacer les messages techniques par des messages clairs
        if message.localizedCaseInsensitiveContains("401") ||
           message.localizedCaseInsensitiveContains("token invalide") ||
           message.localizedCaseInsensitiveContains("token expiré") ||
           message.localizedCaseInsensitiveContains("unauthorized") {
            return "Votre session a expiré. Veuillez vous reconnecter pour continuer."
        }
        
        // Nettoyer les messages JSON bruts
        if message.contains("{") && message.contains("error") {
            if let jsonData = message.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let errorMessage = json["error"] as? String {
                return errorMessage
            }
        }
        
        return message
    }
}

/// Erreurs API spécifiques
enum APIError: LocalizedError {
    case authenticationRequired(String)
    case httpError(Int, String)
    case invalidResponse
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .authenticationRequired(let message):
            return message
        case .httpError(let code, let message):
            return "Erreur HTTP \(code): \(message)"
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .networkError(let error):
            return "Erreur réseau : \(error.localizedDescription)"
        }
    }
}

