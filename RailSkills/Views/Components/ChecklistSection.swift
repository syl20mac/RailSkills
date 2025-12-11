//
//  ChecklistSection.swift
//  RailSkills
//
//  Modèle de section de checklist (catégorie avec ses questions)
//

import Foundation

/// Représente une section de checklist (catégorie avec ses items)
struct ChecklistSection: Hashable, Identifiable {
    var id: UUID { categoryId }
    let categoryId: UUID
    var categoryTitle: String
    var items: [ChecklistItem]
    
    // Initialiseur pour compatibilité avec l'ancien code
    init(categoryId: UUID, categoryTitle: String, items: [ChecklistItem]) {
        self.categoryId = categoryId
        self.categoryTitle = categoryTitle
        self.items = items
    }
    
    // Initialiseur pour compatibilité avec l'ancien code qui utilise headerTitle
    init(headerTitle: String?, items: [ChecklistItem]) {
        // Si headerTitle est nil, créer un UUID temporaire pour categoryId
        self.categoryId = UUID()
        self.categoryTitle = headerTitle ?? ""
        self.items = items
    }
}





