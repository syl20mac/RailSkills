//
//  CategoryCreatorView.swift
//  RailSkills
//
//  Vue de création de catégorie avec saisie du nom
//

import SwiftUI

/// Vue de création de catégorie avec saisie du nom
struct CategoryCreatorView: View {
    let onSave: (String) -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var categoryName: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                // Section de saisie du nom de la catégorie
                Section {
                    TextField("Nom de la catégorie", text: $categoryName)
                        .focused($isTextFieldFocused)
                } header: {
                    Text("Catégorie")
                } footer: {
                    Text("Saisissez le nom de la catégorie que vous souhaitez créer")
                }
            }
            .navigationTitle("Créer une catégorie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") {
                        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedName.isEmpty {
                            onSave(trimmedName)
                            dismiss()
                        }
                    }
                    .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
}

// MARK: - Preview

#Preview {
    CategoryCreatorView(
        onSave: { _ in },
        onCancel: { }
    )
}























