//
//  NoteTemplatesManagerView.swift
//  RailSkills
//
//  Vue de gestion des templates rapides de notes
//

import SwiftUI

/// Vue de gestion des templates rapides
struct NoteTemplatesManagerView: View {
    @StateObject private var templateManager = NoteTemplateManager.shared
    @State private var showingAddTemplate = false
    @State private var editingTemplate: NoteTemplate?
    @State private var showingDeleteConfirmation = false
    @State private var templateToDelete: NoteTemplate?
    
    var body: some View {
        List {
            Section {
                if templateManager.templates.isEmpty {
                    ContentUnavailableView {
                        Label("Aucun template", systemImage: "note.text")
                    } description: {
                        Text("Ajoutez des templates pour accélérer la saisie de notes")
                    }
                } else {
                    ForEach(templateManager.templates) { template in
                        templateRow(template)
                    }
                    .onDelete { indexSet in
                        templateToDelete = templateManager.templates[indexSet.first!]
                        showingDeleteConfirmation = true
                    }
                    .onMove { source, destination in
                        templateManager.moveTemplate(from: source, to: destination)
                    }
                }
            } header: {
                Text("Templates rapides")
            } footer: {
                Text("Ces templates apparaîtront dans l'éditeur de notes pour une saisie rapide")
            }
            
            Section {
                Button {
                    showingAddTemplate = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Ajouter un template")
                    }
                }
                
                Button(role: .destructive) {
                    templateManager.resetToDefaults()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Réinitialiser aux valeurs par défaut")
                    }
                }
            }
        }
        .navigationTitle("Templates de notes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddTemplate) {
            TemplateEditorView(
                template: nil,
                onSave: { template in
                    templateManager.addTemplate(template)
                }
            )
        }
        .sheet(item: $editingTemplate) { template in
            TemplateEditorView(
                template: template,
                onSave: { updatedTemplate in
                    templateManager.updateTemplate(updatedTemplate)
                }
            )
        }
        .alert("Supprimer le template", isPresented: $showingDeleteConfirmation) {
            Button("Annuler", role: .cancel) {
                templateToDelete = nil
            }
            Button("Supprimer", role: .destructive) {
                if let template = templateToDelete {
                    templateManager.deleteTemplate(template)
                    templateToDelete = nil
                }
            }
        } message: {
            if let template = templateToDelete {
                Text("Voulez-vous supprimer le template \"\(template.text)\" ?")
            }
        }
    }
    
    /// Ligne d'affichage d'un template
    private func templateRow(_ template: NoteTemplate) -> some View {
        Button {
            editingTemplate = template
        } label: {
            HStack(spacing: 12) {
                Image(systemName: template.icon)
                    .font(.title3)
                    .foregroundStyle(template.color)
                    .frame(width: 32)
                
                Text(template.text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

/// Vue d'édition d'un template
struct TemplateEditorView: View {
    let template: NoteTemplate?
    let onSave: (NoteTemplate) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var text: String = ""
    @State private var icon: String = "checkmark.circle.fill"
    @State private var selectedColor: Color = .blue
    @State private var selectedColorName: String = "blue"
    
    // Icônes suggérées
    private let suggestedIcons = [
        "checkmark.circle.fill",
        "exclamationmark.triangle.fill",
        "book.fill",
        "star.fill",
        "arrow.clockwise",
        "info.circle.fill",
        "xmark.circle.fill",
        "questionmark.circle.fill",
        "lightbulb.fill",
        "flag.fill",
        "bell.fill",
        "heart.fill"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Texte du template", text: $text)
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Text("Texte")
                } footer: {
                    Text("Le texte qui sera ajouté à la note")
                }
                
                Section {
                    Picker("Icône", selection: $icon) {
                        ForEach(suggestedIcons, id: \.self) { iconName in
                            HStack {
                                Image(systemName: iconName)
                                Text(iconName)
                            }
                            .tag(iconName)
                        }
                    }
                    
                    // Champ personnalisé pour icône
                    TextField("Icône personnalisée (SF Symbols)", text: $icon)
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Icône")
                } footer: {
                    Text("Nom de l'icône SF Symbols (ex: checkmark.circle.fill)")
                }
                
                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                        ForEach(ColorTemplateManager.availableColors, id: \.name) { colorOption in
                            Button {
                                selectedColor = colorOption.color
                                selectedColorName = colorOption.name
                            } label: {
                                Circle()
                                    .fill(colorOption.color)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                selectedColorName == colorOption.name ? Color.primary : Color.clear,
                                                lineWidth: 3
                                            )
                                    )
                                    .overlay(
                                        Image(systemName: selectedColorName == colorOption.name ? "checkmark" : "")
                                            .foregroundStyle(.white)
                                            .font(.caption.bold())
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Couleur")
                } footer: {
                    Text("Couleur de l'icône du template")
                }
            }
            .navigationTitle(template == nil ? "Nouveau template" : "Modifier le template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        saveTemplate()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let template = template {
                    text = template.text
                    icon = template.icon
                    selectedColorName = template.colorName
                    selectedColor = template.color
                }
            }
        }
    }
    
    private func saveTemplate() {
        let newTemplate = NoteTemplate(
            id: template?.id ?? UUID(),
            text: text.trimmingCharacters(in: .whitespaces),
            icon: icon,
            colorName: selectedColorName
        )
        onSave(newTemplate)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NoteTemplatesManagerView()
    }
}







