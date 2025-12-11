//
//  CategorySelectorView.swift
//  RailSkills
//
//  Vue de sélection de catégorie pour ajouter une question
//

import SwiftUI

/// Vue de sélection de catégorie avec saisie de la question
struct CategorySelectorView: View {
    let checklist: Checklist?
    let onSelect: (Int, String) -> Void  // Modifié pour inclure le texte de la question
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var questionText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                // Section de saisie de la question
                Section {
                    TextField("Texte de la question", text: $questionText, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($isTextFieldFocused)
                } header: {
                    Text("Question")
                } footer: {
                    Text("Saisissez le texte de la question que vous souhaitez ajouter")
                }
                
                if let checklist = checklist {
                    // Liste des catégories
                    if hasCategories {
                        Section {
                            ForEach(Array(checklist.items.enumerated()), id: \.element.id) { index, item in
                                if item.isCategory {
                                    Button {
                                        let text = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if !text.isEmpty {
                                            onSelect(index, text)
                                            dismiss()
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: "folder.fill")
                                                .foregroundStyle(SNCFColors.ceruleen)
                                                .frame(width: 24)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.title)
                                                    .font(.body)
                                                    .foregroundStyle(.primary)
                                                Text("Ajouter dans cette catégorie")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        } header: {
                            Text("Catégories")
                        } footer: {
                            Text("Sélectionnez une catégorie pour y ajouter la question à la fin de cette catégorie")
                        }
                    } else {
                        Section {
                            Text("Aucune catégorie disponible")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        } header: {
                            Text("Catégories")
                        } footer: {
                            Text("Créez d'abord une catégorie pour organiser vos questions")
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("Aucune checklist", systemImage: "list.bullet.rectangle")
                    } description: {
                        Text("Importez d'abord une checklist")
                    }
                }
            }
            .navigationTitle("Ajouter une question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        onCancel()
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Focus automatique sur le champ de texte au chargement
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    /// Vérifie si la checklist contient des catégories
    private var hasCategories: Bool {
        checklist?.items.contains { $0.isCategory } ?? false
    }
}

// MARK: - Preview

#Preview {
    CategorySelectorView(
        checklist: Checklist(
            title: "Test",
            items: [
                ChecklistItem(title: "Catégorie 1", isCategory: true),
                ChecklistItem(title: "Question 1", isCategory: false),
                ChecklistItem(title: "Catégorie 2", isCategory: true),
                ChecklistItem(title: "Question 2", isCategory: false)
            ]
        ),
        onSelect: { _, _ in },
        onCancel: { }
    )
}

