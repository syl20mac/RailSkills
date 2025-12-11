//
//  PreloadService.swift
//  RailSkills
//
//  Service de préchargement intelligent des données des conducteurs
//  Améliore la fluidité en préchargeant les données du conducteur suivant
//

import Foundation
import Combine

/// Données précalculées d'un conducteur
struct PreloadedDriverData {
    let driverId: UUID
    let progress: Double
    let stateMap: [UUID: Int]
    let notesMap: [UUID: String]
    let categoryProgress: [UUID: (validated: Int, total: Int)]
    let timestamp: Date
    
    /// Vérifie si les données sont encore valides (< 5 minutes)
    var isValid: Bool {
        Date().timeIntervalSince(timestamp) < 300
    }
}

/// Service de préchargement des données conducteurs
@MainActor
class PreloadService: ObservableObject {
    static let shared = PreloadService()
    
    private var preloadedData: [UUID: PreloadedDriverData] = [:]
    private var preloadTasks: [UUID: Task<Void, Never>] = [:]
    
    private init() {
        Logger.info("PreloadService initialisé", category: "PreloadService")
    }
    
    /// Précharge les données d'un conducteur
    /// - Parameters:
    ///   - driver: Conducteur à précharger
    ///   - checklist: Checklist associée
    func preloadDriver(_ driver: DriverRecord, checklist: Checklist) {
        // Annuler la tâche précédente si elle existe
        preloadTasks[driver.id]?.cancel()
        
        // Créer une nouvelle tâche de préchargement
        let task = Task {
            let checklistTitle = checklist.title
            let states = driver.checklistStates[checklistTitle] ?? [:]
            let notes = driver.checklistNotes[checklistTitle] ?? [:]
            
            // Calcul de progression
            let progress = calculateProgress(states: states, checklist: checklist)
            
            // Calcul de progression par catégorie
            let categoryProgress = calculateCategoryProgress(states: states, checklist: checklist)
            
            let preloaded = PreloadedDriverData(
                driverId: driver.id,
                progress: progress,
                stateMap: states,
                notesMap: notes,
                categoryProgress: categoryProgress,
                timestamp: Date()
            )
            
            await MainActor.run {
                preloadedData[driver.id] = preloaded
                preloadTasks.removeValue(forKey: driver.id)
                Logger.debug("Données préchargées pour '\(driver.name)'", category: "PreloadService")
            }
        }
        
        preloadTasks[driver.id] = task
    }
    
    /// Récupère les données préchargées d'un conducteur
    /// - Parameter driverId: ID du conducteur
    /// - Returns: Données préchargées ou nil si non disponibles/expirées
    func getPreloadedData(for driverId: UUID) -> PreloadedDriverData? {
        guard let data = preloadedData[driverId], data.isValid else {
            preloadedData.removeValue(forKey: driverId)
            return nil
        }
        
        Logger.debug("Données préchargées utilisées (cache HIT)", category: "PreloadService")
        return data
    }
    
    /// Invalide les données d'un conducteur spécifique
    /// - Parameter driverId: ID du conducteur
    func invalidate(driverId: UUID) {
        preloadTasks[driverId]?.cancel()
        preloadTasks.removeValue(forKey: driverId)
        preloadedData.removeValue(forKey: driverId)
    }
    
    /// Invalide toutes les données préchargées
    func invalidateAll() {
        preloadTasks.values.forEach { $0.cancel() }
        preloadTasks.removeAll()
        preloadedData.removeAll()
        Logger.info("Toutes les données préchargées invalidées", category: "PreloadService")
    }
    
    // MARK: - Helpers
    
    private func calculateProgress(states: [UUID: Int], checklist: Checklist) -> Double {
        let questions = checklist.items.filter { !$0.isCategory }
        guard !questions.isEmpty else { return 0 }
        
        let validatedCount = questions.filter { question in
            let state = states[question.id] ?? 0
            return state == 2 // Validé
        }.count
        
        // Éviter la division par zéro
        guard !questions.isEmpty else { return 0 }
        return Double(validatedCount) / Double(questions.count)
    }
    
    private func calculateCategoryProgress(states: [UUID: Int], checklist: Checklist) -> [UUID: (validated: Int, total: Int)] {
        var progress: [UUID: (validated: Int, total: Int)] = [:]
        
        var currentCategory: UUID?
        for item in checklist.items {
            if item.isCategory {
                currentCategory = item.id
                progress[item.id] = (validated: 0, total: 0)
            } else if let categoryId = currentCategory {
                let state = states[item.id] ?? 0
                let current = progress[categoryId] ?? (validated: 0, total: 0)
                progress[categoryId] = (
                    validated: current.validated + (state == 2 ? 1 : 0),
                    total: current.total + 1
                )
            }
        }
        
        return progress
    }
}

