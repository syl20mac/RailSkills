//
//  ChecklistType.swift
//  RailSkills
//
//  Type énuméré pour identifier les différents types de checklists
//

import Foundation

/// Type de checklist disponible dans l'application
enum ChecklistType: String, CaseIterable {
    case triennale = "Triennale"
    case vp = "VP"
    case te = "TE"
    
    /// Titre affiché dans l'interface
    var displayTitle: String {
        switch self {
        case .triennale:
            return "Suivi"
        case .vp:
            return "Validation Périodique"
        case .te:
            return "Train d'Essai"
        }
    }
    
    /// Icône système pour l'onglet
    var systemImage: String {
        switch self {
        case .triennale:
            return "list.bullet.rectangle"
        case .vp:
            return "checkmark.circle.fill"
        case .te:
            return "checkmark.seal.fill"
        }
    }
}





















