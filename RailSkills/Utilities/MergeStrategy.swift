//
//  MergeStrategy.swift
//  RailSkills
//
//  Stratégies de fusion lors de l'import d'un conducteur existant
//

import Foundation

/// Stratégies de fusion lors de l'import d'un conducteur existant
enum MergeStrategy: CaseIterable {
    case replaceAll
    case keepNewer
    case mergeChecklistStates
    
    var title: String {
        switch self {
        case .replaceAll: return "Remplacer toutes les données"
        case .keepNewer: return "Garder les données les plus récentes"
        case .mergeChecklistStates: return "Fusionner les états de checklist"
        }
    }
    
    var description: String {
        switch self {
        case .replaceAll: return "Remplace complètement le conducteur existant"
        case .keepNewer: return "Garde les données avec la date de suivi la plus récente"
        case .mergeChecklistStates: return "Combine les états de checklist des deux versions"
        }
    }
}




