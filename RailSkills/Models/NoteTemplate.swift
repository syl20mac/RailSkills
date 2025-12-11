//
//  NoteTemplate.swift
//  RailSkills
//
//  Modèle pour les templates rapides de notes
//

import Foundation
import SwiftUI
import Combine

/// Template rapide pour les notes
struct NoteTemplate: Identifiable, Codable, Hashable {
    let id: UUID
    var text: String
    var icon: String
    var colorName: String // Stocke le nom de la couleur pour la sérialisation
    
    /// Couleur SwiftUI correspondante
    var color: Color {
        ColorTemplateManager.color(from: colorName)
    }
    
    init(id: UUID = UUID(), text: String, icon: String, colorName: String) {
        self.id = id
        self.text = text
        self.icon = icon
        self.colorName = colorName
    }
    
    /// Initialiseur avec Color directement (convertit en nom)
    init(id: UUID = UUID(), text: String, icon: String, color: Color) {
        self.id = id
        self.text = text
        self.icon = icon
        self.colorName = ColorTemplateManager.name(for: color)
    }
}

/// Gestionnaire des templates de notes
class NoteTemplateManager: ObservableObject {
    static let shared = NoteTemplateManager()
    
    @Published var templates: [NoteTemplate] = []
    
    private let userDefaultsKey = "noteTemplates"
    
    private init() {
        loadTemplates()
        // Si aucun template, initialiser avec les templates par défaut
        if templates.isEmpty {
            initializeDefaultTemplates()
        }
    }
    
    /// Charge les templates depuis UserDefaults
    private func loadTemplates() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([NoteTemplate].self, from: data) else {
            return
        }
        templates = decoded
    }
    
    /// Sauvegarde les templates dans UserDefaults
    private func saveTemplates() {
        if let encoded = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            // Logger.info("Templates sauvegardés: \(templates.count) template(s)", category: "NoteTemplate")
        }
    }
    
    /// Initialise les templates par défaut
    private func initializeDefaultTemplates() {
        templates = [
            NoteTemplate(text: "✓ Satisfaisant", icon: "checkmark.circle.fill", colorName: "green"),
            NoteTemplate(text: "⚠️ À améliorer", icon: "exclamationmark.triangle.fill", colorName: "orange"),
            NoteTemplate(text: "📚 Formation recommandée", icon: "book.fill", colorName: "blue"),
            NoteTemplate(text: "⭐ Excellent", icon: "star.fill", colorName: "yellow"),
            NoteTemplate(text: "🔄 À réévaluer", icon: "arrow.clockwise", colorName: "purple"),
            NoteTemplate(text: "ℹ️ Voir procédure", icon: "info.circle.fill", colorName: "blue")
        ]
        saveTemplates()
    }
    
    /// Ajoute un nouveau template
    func addTemplate(_ template: NoteTemplate) {
        templates.append(template)
        saveTemplates()
    }
    
    /// Met à jour un template existant
    func updateTemplate(_ template: NoteTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
            saveTemplates()
        }
    }
    
    /// Supprime un template
    func deleteTemplate(_ template: NoteTemplate) {
        templates.removeAll { $0.id == template.id }
        saveTemplates()
    }
    
    /// Supprime un template par son ID
    func deleteTemplate(at indexSet: IndexSet) {
        templates.remove(atOffsets: indexSet)
        saveTemplates()
    }
    
    /// Réinitialise aux templates par défaut
    func resetToDefaults() {
        initializeDefaultTemplates()
    }
    
    /// Réorganise les templates (déplacement)
    func moveTemplate(from source: IndexSet, to destination: Int) {
        templates.move(fromOffsets: source, toOffset: destination)
        saveTemplates()
    }
}

/// Gestionnaire des couleurs pour les templates
class ColorTemplateManager {
    /// Couleurs disponibles pour les templates
    static let availableColors: [(name: String, color: Color)] = [
        ("green", .green),
        ("orange", .orange),
        ("blue", .blue),
        ("yellow", .yellow),
        ("purple", .purple),
        ("red", .red),
        ("pink", .pink),
        ("cyan", .cyan),
        ("mint", .mint),
        ("indigo", .indigo)
    ]
    
    /// Convertit un nom de couleur en Color
    static func color(from name: String) -> Color {
        availableColors.first(where: { $0.name == name })?.color ?? .blue
    }
    
    /// Convertit une Color en nom
    static func name(for color: Color) -> String {
        // Comparaison approximative des couleurs
        // Pour une meilleure précision, on pourrait utiliser UIColor
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        for (name, templateColor) in availableColors {
            if UIColor(templateColor).isEqual(uiColor) {
                return name
            }
        }
        #endif
        return "blue" // Par défaut
    }
}

