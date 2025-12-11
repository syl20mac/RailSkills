//
//  ChecklistParser.swift
//  RailSkills
//
//  Service d'analyse et d'import de checklists depuis du texte Markdown
//

import Foundation

/// Utilitaire pour analyser du texte et créer des checklists
enum ChecklistParser {
    /// Analyse un texte et retourne une checklist structurée
    /// - Parameter text: Le texte à analyser (format Markdown supporté)
    /// - Parameter defaultTitle: Titre par défaut si aucun n'est trouvé
    /// - Returns: Une checklist structurée
    static func parse(_ text: String, defaultTitle: String = "Suivi triennale") -> Checklist {
        var title = defaultTitle
        var items: [ChecklistItem] = []
        var started = false
        
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            if trimmed.hasPrefix("# ") {
                title = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                started = true
                continue
            }

            if isCategoryLine(trimmed) {
                let name = extractCategoryName(from: trimmed)
                items.append(ChecklistItem(title: name, isCategory: true))
                started = true
            } else if started {
                items.append(ChecklistItem(title: trimmed, isCategory: false))
            }
        }
        
        return Checklist(title: title, items: items)
    }
    
    /// Vérifie si une ligne représente une catégorie (titre de section)
    private static func isCategoryLine(_ line: String) -> Bool {
        if line.hasPrefix("**") && line.hasSuffix("**") && line.count > 4 {
            return true
        }
        
        let upper = line.uppercased()
        return upper.hasPrefix("CATÉGORIE:") ||
               upper.hasPrefix("CATEGORIE:") ||
               upper.hasPrefix("CATÉGORIE :") ||
               upper.hasPrefix("CATEGORIE :")
    }
    
    /// Extrait le nom d'une catégorie depuis une ligne formatée
    private static func extractCategoryName(from line: String) -> String {
        if line.hasPrefix("**") && line.hasSuffix("**") {
            return String(line.dropFirst(2).dropLast(2)).trimmingCharacters(in: .whitespaces)
        }
        
        if let colonIndex = line.firstIndex(of: ":") {
            return String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
        }
        
        return line
    }
}






