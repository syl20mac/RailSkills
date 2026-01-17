//
//  AppViewModel+NotesManagement.swift
//  RailSkills
//
//  Extension pour la gestion des notes associées aux questions
//

import Foundation
import Combine

// MARK: - Gestion des notes
extension AppViewModel {
    
    /// Map de notes cachée pour les questions avec système de cache amélioré
    private func notesMap(for type: ChecklistType = .triennale) -> [String: String] {
        guard let cl = checklist(for: type) else { return [:] }
        guard store.drivers.indices.contains(selectedDriverIndex) else { return [:] }
        
        // Vérifier si le cache est valide
        if let cached = cachedNotesMap, cachedChecklistTitle == cl.title {
            return cached
        }
        
        // Mettre à jour le cache
        let map = store.drivers[selectedDriverIndex].checklistNotes[cl.title] ?? [:]
        cachedNotesMap = map
        return map
    }
    
    /// Retourne la note pour un élément (spécifique au conducteur)
    /// - Optimisé avec cache pour réduire les accès répétés
    func note(for item: ChecklistItem, type: ChecklistType = .triennale) -> String? {
        guard !item.isCategory else { return nil }
        return notesMap(for: type)[item.id.uuidString]
    }
    
    /// Définit la note pour un élément et met à jour la date du dernier suivi
    /// - Optimisé avec debouncing pour éviter les sauvegardes excessives
    func setNote(_ note: String?, for item: ChecklistItem, type: ChecklistType = .triennale) {
        guard let cl = checklist(for: type), !item.isCategory else { return }
        guard store.drivers.indices.contains(selectedDriverIndex) else { return }
        
        let key = cl.title
        var driver = store.drivers[selectedDriverIndex]
        var notes = driver.checklistNotes[key] ?? [:]
        
        // Traiter la note
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmedNote = trimmedNote, !trimmedNote.isEmpty {
            notes[item.id.uuidString] = trimmedNote
        } else {
            notes.removeValue(forKey: item.id.uuidString)
        }
        
        driver.checklistNotes[key] = notes
        driver.lastEvaluation = Date()
        
        // Créer un nouveau tableau pour forcer le didSet à se déclencher
        var updatedDrivers = store.drivers
        updatedDrivers[selectedDriverIndex] = driver
        store.drivers = updatedDrivers
        
        // Invalider le cache de notes
        cachedNotesMap = nil
        objectWillChange.send()
        
        Logger.debug("Note mise à jour pour question '\(item.title)'", category: "NotesManagement")
    }
    
    /// Supprime la note d'un élément
    func removeNote(for item: ChecklistItem, type: ChecklistType = .triennale) {
        setNote(nil, for: item, type: type)
    }
    
    /// Vérifie si un élément a une note
    func hasNote(for item: ChecklistItem, type: ChecklistType = .triennale) -> Bool {
        guard !item.isCategory else { return false }
        return notesMap(for: type)[item.id.uuidString] != nil
    }
    
    /// Compte le nombre de questions avec notes dans la checklist actuelle
    func notesCount(type: ChecklistType = .triennale) -> Int {
        return notesMap(for: type).values.filter { !$0.isEmpty }.count
    }
}

