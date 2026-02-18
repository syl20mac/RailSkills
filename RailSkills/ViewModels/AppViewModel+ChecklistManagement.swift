//
//  AppViewModel+ChecklistManagement.swift
//  RailSkills
//
//  Extension pour la gestion des checklists (import, export, création)
//

import Foundation

// MARK: - Gestion des checklists
extension AppViewModel {
    
    /// Importe une checklist depuis un fichier texte ou JSON
    /// - Parameter url: L'URL du fichier à importer
    /// - Parameter type: Le type de checklist (triennale par défaut)
    /// - Throws: ValidationError si la checklist n'est pas valide
    /// - Note: Les permissions de sécurité doivent être obtenues AVANT d'appeler cette fonction
    ///   en utilisant url.startAccessingSecurityScopedResource()
    func importTextFile(url: URL, type: ChecklistType = .triennale) throws {
        let importedChecklist: Checklist
        
        // D'abord, essayer d'importer comme JSON
        if url.pathExtension.lowercased() == "json" {
            guard let parsedChecklist = ExportService.importChecklist(from: try Data(contentsOf: url)) else {
                throw ValidationError.invalidChecklistFormat
            }
            importedChecklist = parsedChecklist
        } else {
            // Sinon, traiter comme fichier texte (Markdown)
            let text = try String(contentsOf: url, encoding: .utf8)
            importedChecklist = ChecklistParser.parse(text)
        }
        
        // Valider la checklist importée
        switch ValidationService.validateChecklist(importedChecklist) {
        case .success:
            // Importer dans la bonne checklist selon le type
            // Importer dans la checklist active quel que soit le type
            // La gestion des types multiples a été simplifiée
             store.checklist = importedChecklist
            initializeDriverStates(for: importedChecklist.title)
            Logger.success("Checklist \(type.displayTitle) validée et importée: \(importedChecklist.title) avec \(importedChecklist.items.count) éléments", category: "ChecklistManagement")
        case .failure(let error):
            Logger.error("Erreur de validation de la checklist: \(error.localizedDescription)", category: "ChecklistManagement")
            throw error
        }
    }
    
    /// Fonction helper pour initialiser les états des conducteurs
    private func initializeDriverStates(for checklistTitle: String) {
        for i in store.drivers.indices {
            if store.drivers[i].checklistStates[checklistTitle] == nil {
                store.drivers[i].checklistStates[checklistTitle] = [:]
            }
        }
    }
    
    /// Crée une checklist vide pour permettre à l'utilisateur de créer manuellement les questions et catégories
    func createEmptyChecklist(type: ChecklistType = .triennale) {
        let title: String
        switch type {
        case .triennale:
            title = "Nouvelle checklist"
        case .vp:
            title = "Nouvelle checklist VP"
        case .te:
            title = "Nouvelle checklist TE"
        }
        
        // Créer une checklist avec une structure de base pour éviter qu'elle soit considérée comme "vide" par l'UI
        let defaultItems = [
            ChecklistItem(title: "Général", isCategory: true),
            ChecklistItem(title: "Première question", isCategory: false)
        ]
        
        let newChecklist = Checklist(title: title, items: defaultItems)
        
        // Assigner à la checklist active quel que soit le type
        store.checklist = newChecklist
    }
    
    /// Exporte la checklist actuelle au format JSON
    /// - Returns: Les données JSON encodées ou nil en cas d'erreur
    func exportChecklistAsJSON() -> Data? {
        guard let checklist = store.checklist else { return nil }
        return ExportService.exportChecklist(checklist)
    }

    /// Supprime la checklist actuelle (pour permettre un nouvel import)
    func removeChecklist() {
        store.removeChecklistOnly()
        // Les états des conducteurs sont conservés mais ne seront plus utilisés
        // jusqu'à ce qu'une nouvelle checklist soit importée
    }
}





