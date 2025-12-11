//
//  SearchDebouncer.swift
//  RailSkills
//
//  Système de debouncing optimisé avec Combine pour la recherche
//  Évite les calculs répétitifs pendant la saisie
//

import Foundation
import Combine

/// Gère le debouncing de la recherche avec Combine
@MainActor
class SearchDebouncer: ObservableObject {
    /// Texte de recherche en temps réel (changé à chaque frappe)
    @Published var searchText: String = ""
    
    /// Texte de recherche debounced (mis à jour après un délai)
    @Published var debouncedText: String = ""
    
    private var cancellable: AnyCancellable?
    
    /// Initialise le debouncer avec un délai personnalisable
    /// - Parameter delay: Délai en secondes avant la mise à jour (défaut: 0.3s)
    init(delay: TimeInterval = 0.3) {
        cancellable = $searchText
            .debounce(for: .seconds(delay), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] value in
                self?.debouncedText = value
            }
        
        Logger.info("SearchDebouncer initialisé avec délai de \(delay)s", category: "SearchDebouncer")
    }
    
    /// Réinitialise la recherche
    func reset() {
        searchText = ""
        debouncedText = ""
    }
    
    /// Annule le debouncing (appelé explicitement si nécessaire)
    /// Note: AnyCancellable s'annule automatiquement à la désallocation
    func cancel() {
        cancellable?.cancel()
        cancellable = nil
    }
    
    nonisolated deinit {
        // AnyCancellable s'annule automatiquement à la désallocation
        // Pas besoin d'appeler cancel() explicitement
    }
}


