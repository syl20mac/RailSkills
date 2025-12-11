//
//  RailSkillsError.swift
//  RailSkills
//
//  Système de gestion d'erreurs centralisé avec messages utilisateur et suggestions de récupération
//

import Foundation
// Logger est disponible globalement dans le projet

/// Erreurs centralisées de l'application RailSkills
enum RailSkillsError: LocalizedError {
    // Erreurs réseau
    case networkUnavailable
    case networkTimeout
    case serverError(statusCode: Int, message: String?)
    
    // Erreurs d'authentification
    case authenticationFailed(reason: String)
    case sessionExpired
    case unauthorizedAccess
    
    // Erreurs de synchronisation
    case syncConflict(localVersion: Date, remoteVersion: Date)
    case syncFailed(reason: String)
    case syncPartialSuccess(succeeded: Int, failed: Int)
    
    // Erreurs de données
    case invalidData(field: String, reason: String)
    case dataNotFound(resource: String)
    case dataCorrupted(resource: String)
    
    // Erreurs de validation
    case validationFailed(field: String, message: String)
    case invalidFormat(field: String, expected: String)
    
    // Erreurs de fichiers
    case fileNotFound(path: String)
    case fileReadError(path: String)
    case fileWriteError(path: String)
    
    // Erreurs SharePoint
    case sharePointConnectionFailed
    case sharePointUploadFailed(file: String)
    case sharePointDownloadFailed(file: String)
    case sharePointPermissionDenied
    
    // Erreurs de chiffrement
    case encryptionFailed
    case decryptionFailed
    case encryptionKeyMissing
    
    // Erreurs génériques
    case unknownError(message: String)
    case operationCancelled
    
    // MARK: - Messages d'erreur utilisateur
    
    var errorDescription: String? {
        switch self {
        // Réseau
        case .networkUnavailable:
            return "Connexion réseau indisponible"
        case .networkTimeout:
            return "La connexion a expiré"
        case .serverError(let statusCode, let message):
            return message ?? "Erreur serveur (\(statusCode))"
        
        // Authentification
        case .authenticationFailed(let reason):
            return "Échec de l'authentification: \(reason)"
        case .sessionExpired:
            return "Votre session a expiré"
        case .unauthorizedAccess:
            return "Accès non autorisé"
        
        // Synchronisation
        case .syncConflict(_, _):
            return "Conflit de synchronisation détecté"
        case .syncFailed(let reason):
            return "Échec de la synchronisation: \(reason)"
        case .syncPartialSuccess(let succeeded, let failed):
            return "Synchronisation partielle: \(succeeded) réussie(s), \(failed) échouée(s)"
        
        // Données
        case .invalidData(let field, let reason):
            return "Données invalides pour '\(field)': \(reason)"
        case .dataNotFound(let resource):
            return "\(resource) introuvable"
        case .dataCorrupted(let resource):
            return "\(resource) corrompu"
        
        // Validation
        case .validationFailed(let field, let message):
            return "Validation échouée pour '\(field)': \(message)"
        case .invalidFormat(let field, let expected):
            return "Format invalide pour '\(field)'. Attendu: \(expected)"
        
        // Fichiers
        case .fileNotFound(let path):
            return "Fichier introuvable: \(path)"
        case .fileReadError(let path):
            return "Impossible de lire le fichier: \(path)"
        case .fileWriteError(let path):
            return "Impossible d'écrire le fichier: \(path)"
        
        // SharePoint
        case .sharePointConnectionFailed:
            return "Impossible de se connecter à SharePoint"
        case .sharePointUploadFailed(let file):
            return "Échec du téléversement: \(file)"
        case .sharePointDownloadFailed(let file):
            return "Échec du téléchargement: \(file)"
        case .sharePointPermissionDenied:
            return "Permissions SharePoint insuffisantes"
        
        // Chiffrement
        case .encryptionFailed:
            return "Échec du chiffrement"
        case .decryptionFailed:
            return "Échec du déchiffrement"
        case .encryptionKeyMissing:
            return "Clé de chiffrement manquante"
        
        // Génériques
        case .unknownError(let message):
            return message
        case .operationCancelled:
            return "Opération annulée"
        }
    }
    
    // MARK: - Suggestions de récupération
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Vérifiez votre connexion Internet et réessayez. Les modifications seront synchronisées automatiquement."
        case .networkTimeout:
            return "Vérifiez votre connexion et réessayez."
        case .serverError:
            return "Le serveur rencontre des difficultés. Réessayez dans quelques instants."
        
        case .authenticationFailed:
            return "Vérifiez vos identifiants et réessayez."
        case .sessionExpired:
            return "Veuillez vous reconnecter."
        case .unauthorizedAccess:
            return "Vous n'avez pas les permissions nécessaires."
        
        case .syncConflict:
            return "Choisissez la version à conserver ou fusionnez les modifications."
        case .syncFailed:
            return "Les modifications sont sauvegardées localement et seront synchronisées automatiquement."
        case .syncPartialSuccess:
            return "Certaines données ont été synchronisées. Vérifiez les erreurs et réessayez."
        
        case .invalidData, .validationFailed, .invalidFormat:
            return "Vérifiez les données saisies et réessayez."
        case .dataNotFound:
            return "La ressource demandée n'existe pas ou a été supprimée."
        case .dataCorrupted:
            return "Les données sont corrompues. Une restauration depuis une sauvegarde peut être nécessaire."
        
        case .fileNotFound, .fileReadError, .fileWriteError:
            return "Vérifiez que le fichier existe et que vous avez les permissions nécessaires."
        
        case .sharePointConnectionFailed:
            return "Vérifiez votre connexion à SharePoint et réessayez."
        case .sharePointUploadFailed, .sharePointDownloadFailed:
            return "Vérifiez votre connexion et réessayez. Les modifications sont sauvegardées localement."
        case .sharePointPermissionDenied:
            return "Contactez votre administrateur pour obtenir les permissions nécessaires."
        
        case .encryptionFailed, .decryptionFailed:
            return "Un problème de chiffrement est survenu. Vérifiez la configuration."
        case .encryptionKeyMissing:
            return "La clé de chiffrement n'est pas configurée. Contactez votre administrateur."
        
        case .unknownError:
            return "Une erreur inattendue est survenue. Réessayez ou contactez le support."
        case .operationCancelled:
            return nil
        }
    }
    
    // MARK: - Code d'erreur pour le logging
    
    var errorCode: String {
        switch self {
        case .networkUnavailable: return "NETWORK_UNAVAILABLE"
        case .networkTimeout: return "NETWORK_TIMEOUT"
        case .serverError: return "SERVER_ERROR"
        case .authenticationFailed: return "AUTH_FAILED"
        case .sessionExpired: return "SESSION_EXPIRED"
        case .unauthorizedAccess: return "UNAUTHORIZED"
        case .syncConflict: return "SYNC_CONFLICT"
        case .syncFailed: return "SYNC_FAILED"
        case .syncPartialSuccess: return "SYNC_PARTIAL"
        case .invalidData: return "INVALID_DATA"
        case .dataNotFound: return "DATA_NOT_FOUND"
        case .dataCorrupted: return "DATA_CORRUPTED"
        case .validationFailed: return "VALIDATION_FAILED"
        case .invalidFormat: return "INVALID_FORMAT"
        case .fileNotFound: return "FILE_NOT_FOUND"
        case .fileReadError: return "FILE_READ_ERROR"
        case .fileWriteError: return "FILE_WRITE_ERROR"
        case .sharePointConnectionFailed: return "SHAREPOINT_CONNECTION_FAILED"
        case .sharePointUploadFailed: return "SHAREPOINT_UPLOAD_FAILED"
        case .sharePointDownloadFailed: return "SHAREPOINT_DOWNLOAD_FAILED"
        case .sharePointPermissionDenied: return "SHAREPOINT_PERMISSION_DENIED"
        case .encryptionFailed: return "ENCRYPTION_FAILED"
        case .decryptionFailed: return "DECRYPTION_FAILED"
        case .encryptionKeyMissing: return "ENCRYPTION_KEY_MISSING"
        case .unknownError: return "UNKNOWN_ERROR"
        case .operationCancelled: return "OPERATION_CANCELLED"
        }
    }
    
    // MARK: - Gravité de l'erreur
    
    enum Severity {
        case info
        case warning
        case error
        case critical
    }
    
    var severity: Severity {
        switch self {
        case .networkUnavailable, .syncPartialSuccess:
            return .warning
        case .sessionExpired, .syncConflict:
            return .warning
        case .authenticationFailed, .unauthorizedAccess, .syncFailed:
            return .error
        case .dataCorrupted, .encryptionKeyMissing, .serverError:
            return .critical
        default:
            return .error
        }
    }
    
    // MARK: - Récupérable ou non
    
    var isRecoverable: Bool {
        switch self {
        case .networkUnavailable, .networkTimeout, .syncFailed, .syncPartialSuccess:
            return true
        case .sessionExpired, .authenticationFailed:
            return true
        case .dataCorrupted, .encryptionKeyMissing:
            return false
        default:
            return true
        }
    }
}

// MARK: - Extension pour le logging

extension RailSkillsError {
    /// Log l'erreur avec tous ses détails
    func log(context: String = "") {
        let contextPrefix = context.isEmpty ? "" : "[\(context)] "
        Logger.error("\(contextPrefix)\(errorCode): \(errorDescription ?? "Erreur inconnue")", category: "Error")
        
        if let suggestion = recoverySuggestion {
            Logger.info("Suggestion: \(suggestion)", category: "Error")
        }
    }
}

// MARK: - Extension pour conversion depuis d'autres erreurs

extension RailSkillsError {
    /// Convertit une erreur générique en RailSkillsError
    static func from(_ error: Error, context: String = "") -> RailSkillsError {
        if let railSkillsError = error as? RailSkillsError {
            return railSkillsError
        }
        
        let nsError = error as NSError
        let errorMessage = error.localizedDescription
        
        // Détecter les types d'erreurs courants
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return .networkUnavailable
            case NSURLErrorTimedOut:
                return .networkTimeout
            default:
                return .networkUnavailable
            }
        }
        
        // Erreur générique
        return .unknownError(message: errorMessage)
    }
}

