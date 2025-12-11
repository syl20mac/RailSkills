//
//  ChecklistItem.swift
//  RailSkills
//
//  Modèle de données pour un élément de checklist
//

import Foundation

/// Élément individuel d'une checklist - peut être une catégorie ou une question
struct ChecklistItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var isCategory: Bool       // true = catégorie, false = question
    var checked: Bool         // état coché (obsolète, remplacé par le système à 4 états)
    var notes: String?        // notes supplémentaires (notes globales de la checklist, non utilisées pour les suivis par conducteur)

    init(id: UUID = UUID(), title: String, isCategory: Bool, checked: Bool = false, notes: String? = nil) {
        self.id = id
        self.title = title
        self.isCategory = isCategory
        self.checked = checked
        self.notes = notes
    }
}




