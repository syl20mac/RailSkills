//
//  AppViewModel+StateManagement.swift
//  RailSkills
//
//  Extension pour la gestion des états des questions de checklist
//

import Foundation
import Combine

// MARK: - Gestion des états
extension AppViewModel {
    
    /// Map d'état cachée pour les réponses aux questions
    private func stateMap(for type: ChecklistType = .triennale) -> [String: Int] {
        guard let cl = checklist(for: type) else { return [:] }
        guard store.drivers.indices.contains(selectedDriverIndex) else { return [:] }
        
        if let cached = cachedStateMap, cachedChecklistTitle == cl.title {
            return cached
        }
        
        let map = store.drivers[selectedDriverIndex].checklistStates[cl.title] ?? [:]
        cachedStateMap = map
        cachedChecklistTitle = cl.title
        return map
    }
    
    /// Retourne l'état d'un élément (0=non validé, 1=partiel, 2=validé, 3=non traité)
    func state(for item: ChecklistItem, type: ChecklistType = .triennale) -> Int {
        stateMap(for: type)[item.id.uuidString] ?? 3  // Par défaut: Non traité
    }

    /// Vérifie si un élément est complètement validé (état 2)
    func isChecked(_ item: ChecklistItem, type: ChecklistType = .triennale) -> Bool {
        stateMap(for: type)[item.id.uuidString] == 2
    }

    /// Fait basculer l'état d'un élément entre les 4 valeurs possibles
    func toggle(_ item: ChecklistItem, type: ChecklistType = .triennale) {
        setState((state(for: item, type: type) + 1) % 4, for: item, type: type)
    }

    /// Définit l'état d'un élément et met à jour la date du dernier suivi
    func setState(_ value: Int, for item: ChecklistItem, type: ChecklistType = .triennale) {
        guard let cl = checklist(for: type), !item.isCategory else { return }
        guard store.drivers.indices.contains(selectedDriverIndex) else { return }
        
        let clampedValue = max(0, min(3, value))
        let key = cl.title
        let currentDate = Date()
        
        var driver = store.drivers[selectedDriverIndex]
        var map = driver.checklistStates[key] ?? [:]
        let previousValue = map[item.id.uuidString]
        
        // Vérifier si l'état a réellement changé
        guard previousValue != clampedValue else { return }
        
        // Haptic feedback pour le changement d'état
        HapticFeedbackManager.shared.stateChange()
        
        // Feedback spécifique selon l'état
        if clampedValue == 2 {
            // Question validée
            HapticFeedbackManager.shared.questionValidated()
        } else if clampedValue == 1 {
            // Question partiellement complétée
            HapticFeedbackManager.shared.questionCompleted()
        }
        
        // Mettre à jour l'état
        map[item.id.uuidString] = clampedValue
        driver.checklistStates[key] = map
        driver.lastEvaluation = currentDate
        
        // Enregistrer la date de suivi de la question à chaque changement d'état
        var datesMap = driver.checklistDates[key] ?? [:]
        datesMap[item.id.uuidString] = currentDate
        driver.checklistDates[key] = datesMap
        
        // Mettre à jour directement le tableau (le store déclenchera les notifications et la sauvegarde)
        store.drivers[selectedDriverIndex] = driver
        
        // Invalider le cache de progression
        cachedProgress = nil
        cachedStateMap = nil
        objectWillChange.send()
        
        Logger.debug("État mis à jour pour question '\(item.title)': \(clampedValue)", category: "StateManagement")
    }
    
    /// Retourne la date de suivi d'une question
    func evaluationDate(for item: ChecklistItem, type: ChecklistType = .triennale) -> Date? {
        guard let cl = checklist(for: type), !item.isCategory else { return nil }
        guard store.drivers.indices.contains(selectedDriverIndex) else { return nil }
        
        let key = cl.title
        let datesMap = store.drivers[selectedDriverIndex].checklistDates[key] ?? [:]
        return datesMap[item.id.uuidString]
    }

    /// Remet à zéro toutes les réponses de la checklist pour le conducteur sélectionné
    func resetChecklist(type: ChecklistType = .triennale) {
        guard let cl = checklist(for: type) else { return }
        guard store.drivers.indices.contains(selectedDriverIndex) else { return }
        let key = cl.title
        var driver = store.drivers[selectedDriverIndex]
        driver.checklistStates[key] = [:]
        
        // Mettre à jour directement le tableau
        store.drivers[selectedDriverIndex] = driver
        
        cachedProgress = nil
        cachedStateMap = nil
    }
}

