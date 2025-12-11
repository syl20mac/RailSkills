//
//  ValidationService.swift
//  RailSkills
//
//  Service de validation des données pour améliorer la robustesse
//

import Foundation

/// Erreurs de validation possibles
enum ValidationError: LocalizedError {
    case invalidChecklistFormat
    case missingRequiredFields(fields: [String])
    case invalidDateRange
    case invalidDriverName
    case invalidUUID
    case dataCorrupted
    
    var errorDescription: String? {
        switch self {
        case .invalidChecklistFormat:
            return "Le format de la checklist est invalide"
        case .missingRequiredFields(let fields):
            return "Des champs obligatoires sont manquants: \(fields.joined(separator: ", "))"
        case .invalidDateRange:
            return "La plage de dates est invalide"
        case .invalidDriverName:
            return "Le nom du conducteur est invalide"
        case .invalidUUID:
            return "L'identifiant unique est invalide"
        case .dataCorrupted:
            return "Les données sont corrompues ou incompatibles"
        }
    }
}

/// Service de validation des données
enum ValidationService {
    /// Valide un nom de conducteur
    /// - Parameter name: Le nom à valider
    /// - Returns: True si valide, false sinon
    static func validateDriverName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= AppConstants.Validation.minDriverNameLength &&
               trimmed.count <= AppConstants.Validation.maxDriverNameLength
    }
    
    /// Valide un DriverRecord
    /// - Parameter driver: Le conducteur à valider
    /// - Returns: Résultat de validation avec erreurs éventuelles
    static func validateDriver(_ driver: DriverRecord) -> Result<Void, ValidationError> {
        // Valider le nom
        guard validateDriverName(driver.name) else {
            return .failure(.invalidDriverName)
        }
        
        // Valider l'UUID
        guard !driver.id.uuidString.isEmpty else {
            return .failure(.invalidUUID)
        }
        
        // Valider les dates si présentes
        if let start = driver.triennialStart {
            let calendar = Calendar.current
            let now = Date()
            
            // La date de début ne doit pas être trop dans le futur (max 1 an)
            if let maxDate = calendar.date(byAdding: .year, value: 1, to: now),
               start > maxDate {
                return .failure(.invalidDateRange)
            }
            
            // La date de début ne doit pas être trop dans le passé (max 10 ans)
            if let minDate = calendar.date(byAdding: .year, value: -10, to: now),
               start < minDate {
                return .failure(.invalidDateRange)
            }
        }
        
        return .success(())
    }
    
    /// Valide une Checklist
    /// - Parameter checklist: La checklist à valider
    /// - Returns: Résultat de validation avec erreurs éventuelles
    static func validateChecklist(_ checklist: Checklist) -> Result<Void, ValidationError> {
        // Vérifier que le titre n'est pas vide
        guard !checklist.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.missingRequiredFields(fields: ["title"]))
        }
        
        // Vérifier qu'il y a au moins un élément
        guard !checklist.items.isEmpty else {
            return .failure(.invalidChecklistFormat)
        }
        
        // Valider chaque item
        for item in checklist.items {
            // Vérifier que le titre n'est pas vide
            guard !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return .failure(.invalidChecklistFormat)
            }
            
            // Vérifier que l'UUID est valide
            guard !item.id.uuidString.isEmpty else {
                return .failure(.invalidUUID)
            }
        }
        
        return .success(())
    }
    
    /// Valide un ShareableDriverRecord
    /// - Parameter record: Le record à valider
    /// - Returns: Résultat de validation avec erreurs éventuelles
    static func validateShareableDriverRecord(_ record: ShareableDriverRecord) -> Result<Void, ValidationError> {
        // Valider le conducteur
        switch validateDriver(record.driver) {
        case .failure(let error):
            return .failure(error)
        case .success:
            break
        }
        
        // Valider la checklist si présente
        if let checklist = record.checklist {
            switch validateChecklist(checklist) {
            case .failure(let error):
                return .failure(error)
            case .success:
                break
            }
        }
        
        // Valider la date d'export
        let calendar = Calendar.current
        let now = Date()
        
        // La date d'export ne doit pas être dans le futur
        if record.exportDate > now.addingTimeInterval(60) { // Tolérance de 1 minute
            return .failure(.invalidDateRange)
        }
        
        // La date d'export ne doit pas être trop ancienne (max 10 ans)
        if let minDate = calendar.date(byAdding: .year, value: -10, to: now),
           record.exportDate < minDate {
            return .failure(.invalidDateRange)
        }
        
        return .success(())
    }
    
    /// Sanitise un nom de fichier pour éviter les caractères dangereux
    /// - Parameter name: Le nom à sanitizer
    /// - Returns: Le nom sanitizé
    static func sanitizeFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/:?<>\\|*\"")
        var sanitized = name.components(separatedBy: invalidCharacters).joined(separator: "_")
        
        // Supprimer les espaces en début/fin
        sanitized = sanitized.trimmingCharacters(in: .whitespaces)
        
        // Limiter la longueur
        if sanitized.count > AppConstants.Data.maxFileNameLength {
            let index = sanitized.index(sanitized.startIndex, offsetBy: AppConstants.Data.maxFileNameLength)
            sanitized = String(sanitized[..<index])
        }
        
        // Si vide après sanitization, utiliser un nom par défaut
        if sanitized.isEmpty {
            sanitized = "file"
        }
        
        return sanitized
    }
    
    /// Valide un fichier d'import avant traitement
    /// - Parameter data: Les données du fichier à valider
    /// - Returns: Résultat de validation avec erreurs éventuelles
    static func validateImportData(_ data: Data) -> Result<Void, ValidationError> {
        // Vérifier la taille (limite raisonnable)
        guard data.count <= AppConstants.Validation.maxImportFileSize else {
            return .failure(.dataCorrupted)
        }
        
        // Vérifier que ce n'est pas vide
        guard !data.isEmpty else {
            return .failure(.dataCorrupted)
        }
        
        // Vérifier la structure JSON de base
        guard let _ = try? JSONSerialization.jsonObject(with: data) else {
            // Ce n'est peut-être pas du JSON (peut être chiffré ou compressé)
            // On accepte quand même, la validation se fera après décompression/déchiffrement
            return .success(())
        }
        
        return .success(())
    }
}





