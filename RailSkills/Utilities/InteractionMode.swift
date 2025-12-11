//
//  InteractionMode.swift
//  RailSkills
//
//  Modes d'interaction pour les états de validation
//

import Foundation

/// Énumération des modes d'interaction disponibles pour les états de validation
enum InteractionMode: String, CaseIterable, Identifiable {
    case toggle = "toggle"
    case segmented = "segmented"
    case buttons = "buttons"
    case menu = "menu"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .toggle: return "Toggle interactif"
        case .segmented: return "Segmenté compact"
        case .buttons: return "Boutons individuels"
        case .menu: return "Menu déroulant"
        }
    }
    
    var description: String {
        switch self {
        case .toggle: return "Glissez ou tapez pour changer d'état. Design moderne et fluide."
        case .segmented: return "Interface compacte avec sélection directe. Simple et rapide."
        case .buttons: return "Boutons visuels avec icônes colorées. Très intuitif."
        case .menu: return "Menu déroulant avec texte descriptif. Idéal pour la précision."
        }
    }
    
    var icon: String {
        switch self {
        case .toggle: return "slider.horizontal.3"
        case .segmented: return "rectangle.split.3x1"
        case .buttons: return "circle.grid.2x2"
        case .menu: return "list.bullet"
        }
    }
}






