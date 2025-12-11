//
//  Checklist.swift
//  RailSkills
//
//  Modèle de données pour une checklist complète
//

import Foundation

/// Structure représentant une checklist complète avec titre et éléments
struct Checklist: Codable {
    var title: String          // nom de la checklist
    var items: [ChecklistItem] // tous les éléments (catégories et questions)
    var ownerSNCFId: String?   // identifiant SNCF du CTT propriétaire (optionnel pour rétrocompatibilité)
    
    // Propriété calculée pour éviter les filtrages répétés - retourne uniquement les questions
    var questions: [ChecklistItem] {
        items.filter { !$0.isCategory }
    }
    
    init(title: String, items: [ChecklistItem] = [], ownerSNCFId: String? = nil) {
        self.title = title
        self.items = items
        self.ownerSNCFId = ownerSNCFId
    }
}






