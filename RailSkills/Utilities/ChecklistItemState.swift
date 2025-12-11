//
//  ChecklistItemState.swift
//  RailSkills
//
//  Énumération des états possibles pour un élément de checklist
//

import Foundation

/// États possibles d'un élément de checklist
enum ChecklistItemState: Int, Codable, CaseIterable {
    case notValidated = 0   // Non validé ☐
    case partial = 1        // Partiel ◪
    case validated = 2      // Validé ☑
    case notProcessed = 3   // Non applicable (N/A)
    
    /// Icône SF Symbol associée à l'état
    var iconName: String {
        switch self {
        case .notValidated: return "xmark.circle.fill"
        case .partial: return "exclamationmark.circle.fill"
        case .validated: return "checkmark.circle.fill"
        case .notProcessed: return "circle.fill"
        }
    }
    
    /// Libellé textuel de l'état
    var label: String {
        switch self {
        case .notValidated: return "Non validé"
        case .partial: return "Partiel"
        case .validated: return "Validé"
        case .notProcessed: return "À traiter"
        }
    }
    
    /// État suivant dans le cycle
    var next: ChecklistItemState {
        switch self {
        case .notValidated: return .partial
        case .partial: return .validated
        case .validated: return .notProcessed
        case .notProcessed: return .notValidated
        }
    }
}


