//
//  DemoDataService.swift
//  RailSkills
//
//  Service pour charger des données de démonstration
//  Utilisé en mode démo pour les reviewers Apple
//

import Foundation

/// Service pour charger des données de démonstration
@MainActor
class DemoDataService {
    static let shared = DemoDataService()
    
    private init() {}
    
    /// Crée des conducteurs de démonstration
    func createDemoDrivers() -> [DriverRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        // Créer quelques conducteurs avec des dates triennales variées
        let driver1 = DriverRecord(
            name: "MARTIN",
            firstName: "Jean",
            cpNumber: "CP-2024-001",
            lastEvaluation: calendar.date(byAdding: .month, value: -6, to: now),
            triennialStart: calendar.date(byAdding: .year, value: -1, to: now),
            ownerSNCFId: DemoModeService.shared.demoEmail
        )
        
        let driver2 = DriverRecord(
            name: "DUPONT",
            firstName: "Pierre",
            cpNumber: "CP-2024-002",
            lastEvaluation: calendar.date(byAdding: .month, value: -3, to: now),
            triennialStart: calendar.date(byAdding: .year, value: -2, to: now),
            ownerSNCFId: DemoModeService.shared.demoEmail
        )
        
        let driver3 = DriverRecord(
            name: "BERNARD",
            firstName: "Marie",
            cpNumber: "CP-2024-003",
            lastEvaluation: calendar.date(byAdding: .month, value: -1, to: now),
            triennialStart: calendar.date(byAdding: .month, value: -6, to: now),
            ownerSNCFId: DemoModeService.shared.demoEmail
        )
        
        return [driver1, driver2, driver3]
    }
    
    /// Crée une checklist de démonstration
    func createDemoChecklist() -> Checklist {
        // Créer une checklist simple avec quelques catégories et questions
        var items: [ChecklistItem] = []
        
        // Catégorie 1 : Sécurité
        let securityCategory = ChecklistItem(
            title: "Sécurité",
            isCategory: true
        )
        items.append(securityCategory)
        
        items.append(ChecklistItem(
            title: "Vérification des équipements de sécurité",
            isCategory: false
        ))
        items.append(ChecklistItem(
            title: "Connaissance des procédures d'urgence",
            isCategory: false
        ))
        items.append(ChecklistItem(
            title: "Respect des limitations de vitesse",
            isCategory: false
        ))
        
        // Catégorie 2 : Technique
        let technicalCategory = ChecklistItem(
            title: "Technique",
            isCategory: true
        )
        items.append(technicalCategory)
        
        items.append(ChecklistItem(
            title: "Maîtrise des systèmes de signalisation",
            isCategory: false
        ))
        items.append(ChecklistItem(
            title: "Gestion des situations d'incident",
            isCategory: false
        ))
        items.append(ChecklistItem(
            title: "Communication avec le poste de commande",
            isCategory: false
        ))
        
        // Catégorie 3 : Réglementaire
        let regulatoryCategory = ChecklistItem(
            title: "Réglementaire",
            isCategory: true
        )
        items.append(regulatoryCategory)
        
        items.append(ChecklistItem(
            title: "Connaissance de la réglementation CFL",
            isCategory: false
        ))
        items.append(ChecklistItem(
            title: "Respect des temps de conduite",
            isCategory: false
        ))
        items.append(ChecklistItem(
            title: "Documentation à jour",
            isCategory: false
        ))
        
        return Checklist(
            title: "Checklist de démonstration CFL",
            items: items,
            ownerSNCFId: DemoModeService.shared.demoEmail
        )
    }
    
    /// Charge les données de démonstration dans le Store
    func loadDemoData(into store: Store) {
        Logger.info("Chargement des données de démonstration", category: "DemoData")
        
        // Charger les conducteurs de démo
        let demoDrivers = createDemoDrivers()
        store.drivers = demoDrivers
        
        // Charger la checklist de démo
        let demoChecklist = createDemoChecklist()
        store.checklist = demoChecklist
        
        // Ajouter quelques états de progression pour rendre les données plus réalistes
        if let checklist = store.checklist {
            let questions = checklist.questions
            let checklistKey = checklist.title
            
            // Pour chaque conducteur, ajouter quelques validations
            for (index, driver) in store.drivers.enumerated() {
                var updatedDriver = driver
                var states = updatedDriver.checklistStates[checklistKey] ?? [:]
                
                // Valider quelques questions selon l'index du conducteur
                let questionsToValidate = min(questions.count, (index + 1) * 3)
                for i in 0..<questionsToValidate {
                    if i < questions.count {
                        // Mélanger les états : 2 = validé, 1 = partiel, 0 = non validé
                        let state = i % 3 == 0 ? 2 : (i % 3 == 1 ? 1 : 0)
                        states[questions[i].id] = state
                    }
                }
                
                updatedDriver.checklistStates[checklistKey] = states
                store.drivers[index] = updatedDriver
            }
        }
        
        Logger.success("Données de démonstration chargées: \(demoDrivers.count) conducteur(s), \(demoChecklist.items.count) élément(s) de checklist", category: "DemoData")
    }
}
