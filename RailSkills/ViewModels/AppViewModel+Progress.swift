//
//  AppViewModel+Progress.swift
//  RailSkills
//
//  Extension pour le calcul de progression des suivis
//

import Foundation

// MARK: - Calcul de progression
extension AppViewModel {
    
    /// Calcul de progression avec système de cache pour optimiser les performances
    var progress: Double {
        progress(for: .triennale)
    }
    
    /// Calcul de progression pour un type de checklist spécifique
    func progress(for type: ChecklistType) -> Double {
        if let cached = cachedProgress, cachedChecklistTitle == checklist(for: type)?.title {
            return cached
        }
        
        guard let cl = checklist(for: type) else { return 0 }
        let questions = cl.questions
        
        guard !questions.isEmpty else { return 0 }
        
        // Accéder directement au store pour obtenir les états
        guard store.drivers.indices.contains(selectedDriverIndex) else { return 0 }
        let key = cl.title
        let stateMap = store.drivers[selectedDriverIndex].checklistStates[key] ?? [:]
        
        let checkedCount = questions.filter { stateMap[$0.id] == 2 }.count
        let result = Double(checkedCount) / Double(questions.count)
        
        cachedProgress = result
        cachedChecklistTitle = cl.title
        return result
    }
}

