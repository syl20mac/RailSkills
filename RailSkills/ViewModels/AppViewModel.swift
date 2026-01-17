//
//  AppViewModel.swift
//  RailSkills
//
//  ViewModel principal gérant la logique métier de l'application
//

import Foundation
import SwiftUI
import Combine

/// ViewModel principal gérant la logique métier de l'application
final class AppViewModel: ObservableObject {
    @Published var store = Store()
    @Published var selectedDriverIndex: Int = 0 {
        didSet {
            // Invalidation du cache lors du changement de conducteur
            cachedProgress = nil
            cachedStateMap = nil
            cachedNotesMap = nil
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // Système de cache pour optimiser les calculs répétitifs et améliorer les performances
    // Ces propriétés sont internal pour permettre l'accès depuis les extensions
    var cachedProgress: Double?
    var cachedStateMap: [String: Int]?
    var cachedChecklistTitle: String?
    var cachedNotesMap: [String: String]?

    init() {
        // Observe les changements du store pour invalider le cache
        store.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.cachedProgress = nil
                self?.cachedStateMap = nil
                self?.cachedNotesMap = nil
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - Gestion du conducteur sélectionné
    
    /// Retourne les conducteurs filtrés par l'identité SNCF actuelle
    var filteredDrivers: [DriverRecord] {
        store.filteredDrivers
    }
    
    /// Retourne la checklist filtrée par l'identité SNCF actuelle
    var filteredChecklist: Checklist? {
        store.filteredChecklist
    }
    
    /// Retourne la checklist selon le type spécifié
    func checklist(for type: ChecklistType) -> Checklist? {
        switch type {
        case .triennale:
            return store.checklistTriennale
        case .vp:
            return store.checklistVP
        case .te:
            return store.checklistTE
        }
    }
    
    /// Retourne le conducteur actuellement sélectionné ou un conducteur vide si aucun
    /// Utilise les conducteurs filtrés pour l'affichage
    var selectedDriver: DriverRecord {
        if filteredDrivers.indices.contains(selectedDriverIndex) {
            return filteredDrivers[selectedDriverIndex]
        }
        // Retourner le premier conducteur disponible, sinon un placeholder inoffensif
        if let first = filteredDrivers.first { return first }
        return DriverRecord(name: "", lastEvaluation: nil, triennialStart: nil)
    }
    
    // MARK: - Extensions
    // Les méthodes ont été extraites dans des extensions séparées pour améliorer l'organisation :
    // - AppViewModel+StateManagement.swift : Gestion des états des questions
    // - AppViewModel+NotesManagement.swift : Gestion des notes
    // - AppViewModel+Progress.swift : Calcul de progression
    // - AppViewModel+ChecklistManagement.swift : Gestion des checklists
    // - AppViewModel+DriverManagement.swift : Gestion des conducteurs
    // - AppViewModel+Sharing.swift : Partage et collaboration
}

