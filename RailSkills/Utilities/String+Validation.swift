//
//  String+Validation.swift
//  RailSkills
//
//  Extensions pour la validation des chaînes de caractères
//

import Foundation

extension String {
    /// Vérifie si l'email est valide et se termine par @sncf.fr
    /// - Returns: Tuple avec isValid (Bool) et errorMessage (String?)
    func isValidSNCFEmail() -> (isValid: Bool, errorMessage: String?) {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Vérifier que l'email n'est pas vide
        guard !trimmed.isEmpty else {
            return (true, nil) // Pas d'erreur si vide (géré par le champ requis)
        }
        
        // Si l'email ne contient pas encore @, pas d'erreur (en cours de saisie)
        guard trimmed.contains("@") else {
            return (true, nil)
        }
        
        // Si l'email contient @ mais n'est pas encore complet (pas de point après @), attendre
        if let atIndex = trimmed.firstIndex(of: "@") {
            let afterAt = String(trimmed[trimmed.index(after: atIndex)...])
            if !afterAt.contains(".") {
                // Email en cours de saisie (ex: "test@sncf"), pas encore d'erreur
                return (true, nil)
            }
        }
        
        // Vérifier que l'email se termine par @sncf.fr (STRICT)
        if !trimmed.hasSuffix("@sncf.fr") {
            return (false, "Seules les adresses email @sncf.fr sont autorisées")
        }
        
        // Vérifier le format email de base
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: trimmed) else {
            return (false, "Format d'email invalide")
        }
        
        return (true, nil)
    }
    
    /// Vérifie si l'email est un email SNCF valide (pour affichage visuel)
    var isSNCFEmailValid: Bool {
        let validation = self.isValidSNCFEmail()
        return validation.isValid
    }
}

