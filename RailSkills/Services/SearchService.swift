//
//  SearchService.swift
//  RailSkills
//
//  Service de recherche optimisé avec index inversé pour les notes
//

import Foundation

/// Service de recherche optimisé pour les questions et notes
enum SearchService {
    /// Index inversé : mot-clé -> Set d'IDs de questions (as String)
    private static var notesSearchIndex: [String: Set<String>] = [:]
    
    /// Met à jour l'index de recherche des notes
    /// - Parameters:
    ///   - drivers: Liste des conducteurs
    ///   - checklistTitle: Titre de la checklist
    static func updateNotesSearchIndex(drivers: [DriverRecord], checklistTitle: String) {
        var index: [String: Set<String>] = [:]
        
        for driver in drivers {
            let notesMap = driver.checklistNotes[checklistTitle] ?? [:]
            for (itemId, note) in notesMap where !note.isEmpty {
                // Tokeniser la note en mots (minimum 3 caractères)
                let words = note.lowercased()
                    .components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
                    .filter { $0.count >= 3 }
                
                for word in words {
                    index[word, default: []].insert(itemId)
                }
            }
        }
        
        notesSearchIndex = index
        Logger.info("Index de recherche mis à jour: \(index.count) mots-clés pour \(drivers.count) conducteur(s)", category: "SearchService")
    }
    
    /// Réinitialise l'index de recherche
    static func resetSearchIndex() {
        notesSearchIndex.removeAll()
    }
    
    /// Vérifie si un item correspond à la recherche
    /// - Parameters:
    ///   - item: L'item à vérifier
    ///   - searchText: Le texte de recherche
    /// - Returns: true si l'item correspond à la recherche
    static func matches(_ item: ChecklistItem, searchText: String) -> Bool {
        guard !searchText.isEmpty else { return true }
        
        let searchLower = searchText.lowercased()
        
        // Recherche dans le titre (rapide)
        if item.title.lowercased().contains(searchLower) {
            return true
        }
        
        // Recherche dans l'index (O(1) lookup par mot)
        let searchWords = searchLower
            .components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
            .filter { $0.count >= 3 }
        
        for word in searchWords {
            if let matchingIds = notesSearchIndex[word], matchingIds.contains(item.id.uuidString) {
                return true
            }
        }
        
        return false
    }
    
    /// Recherche dans les notes de manière exhaustive (fallback si index non disponible)
    /// - Parameters:
    ///   - item: L'item à vérifier
    ///   - searchText: Le texte de recherche
    ///   - drivers: Liste des conducteurs
    ///   - checklistTitle: Titre de la checklist
    /// - Returns: true si une note correspond
    static func matchesInNotes(_ item: ChecklistItem, 
                               searchText: String,
                               drivers: [DriverRecord],
                               checklistTitle: String) -> Bool {
        let searchLower = searchText.lowercased()
        
        for driver in drivers {
            let notesMap = driver.checklistNotes[checklistTitle] ?? [:]
            if let note = notesMap[item.id.uuidString], !note.isEmpty {
                if note.lowercased().contains(searchLower) {
                    return true
                }
            }
        }
        
        return false
    }
}
