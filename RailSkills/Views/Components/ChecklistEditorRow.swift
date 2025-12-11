//
//  ChecklistEditorRow.swift
//  RailSkills
//
//  Composant pour éditer une ligne de checklist (catégorie ou question) dans l'éditeur
//

import SwiftUI

/// Ligne d'édition pour une question ou catégorie dans l'éditeur de checklist
struct ChecklistEditorRow: View {
    let item: ChecklistItem
    let onUpdate: (String) -> Void
    let onUpdateNotes: ((String?) -> Void)?
    let onAddQuestion: () -> Void
    let onAddCategory: () -> Void
    let onConvertType: () -> Void
    let onDelete: () -> Void
    let editMode: EditMode
    
    @State private var title: String = ""
    @State private var originalTitle: String = ""
    @State private var notes: String = ""
    @State private var originalNotes: String = ""
    @State private var showingContextMenu = false
    @State private var showingConfirmation = false
    @State private var showingExpectedAnswerEditor = false
    @State private var pendingTitle: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Icône du type
                Image(systemName: item.isCategory ? "folder.fill" : "checkmark.circle")
                    .foregroundStyle(item.isCategory ? SNCFColors.ceruleen : SNCFColors.menthe)
                    .font(.title3)
                    .frame(width: 20)
                
                // Champ de texte
                TextField(item.isCategory ? "Nom de la catégorie" : "Question", text: $title)
                    .focused($isTextFieldFocused)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled(false)
                    .submitLabel(.done)
                    .onSubmit {
                        // Utiliser un petit délai pour éviter les conflits de contraintes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            confirmUpdate()
                            isTextFieldFocused = false
                        }
                    }
                    .onChange(of: isTextFieldFocused) { _, isFocused in
                        // Utiliser un délai pour éviter les conflits lors du changement de focus
                        if !isFocused && title != originalTitle {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                confirmUpdate()
                            }
                        }
                    }
                
                if editMode == .active {
                    // Menu d'actions en mode édition
                    Menu {
                        Section {
                            Button {
                                onAddQuestion()
                            } label: {
                                Label("Ajouter question après", systemImage: "plus.square")
                            }
                            
                            Button {
                                onAddCategory()
                            } label: {
                                Label("Ajouter catégorie après", systemImage: "folder.badge.plus")
                            }
                        }
                        
                        Section {
                            Button {
                                onConvertType()
                            } label: {
                                if item.isCategory {
                                    Label("Convertir en question", systemImage: "arrow.right.circle")
                                } else {
                                    Label("Convertir en catégorie", systemImage: "arrow.right.circle")
                                }
                            }
                        }
                        
                        Section {
                            Button {
                                // Utiliser un délai pour éviter les conflits de contraintes
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    isTextFieldFocused = true
                                }
                            } label: {
                                Label("Modifier le texte", systemImage: "pencil")
                            }
                        }
                        
                        Section {
                            Button(role: .destructive) {
                                onDelete()
                            } label: {
                                if item.isCategory {
                                    Label("Supprimer la catégorie", systemImage: "trash")
                                } else {
                                    Label("Supprimer la question", systemImage: "trash")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Section pour les réponses attendues (uniquement pour les questions et si onUpdateNotes est disponible)
            if !item.isCategory && onUpdateNotes != nil {
                HStack(spacing: 8) {
                    Button {
                        showingExpectedAnswerEditor = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: notes.isEmpty ? "lightbulb" : "lightbulb.fill")
                                .font(.caption)
                                .foregroundStyle(notes.isEmpty ? .secondary : SNCFColors.safran)
                            
                            Text(notes.isEmpty ? "Ajouter réponses attendues" : "Modifier réponses attendues")
                                .font(.caption)
                                .foregroundStyle(notes.isEmpty ? .secondary : SNCFColors.safran)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if !notes.isEmpty {
                        Spacer()
                        Text("\(notes.count) caractères")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.leading, 32)
            }
        }
        .padding(.vertical, 2)
        .onAppear {
            title = item.title
            originalTitle = item.title
            notes = item.notes ?? ""
            originalNotes = item.notes ?? ""
        }
        .sheet(isPresented: $showingExpectedAnswerEditor) {
            ExpectedAnswerEditorSheet(
                questionTitle: item.title,
                expectedAnswer: $notes,
                originalAnswer: originalNotes,
                onSave: { newNotes in
                    notes = newNotes
                    originalNotes = newNotes
                    onUpdateNotes?(newNotes.isEmpty ? nil : newNotes)
                },
                onCancel: {
                    notes = originalNotes
                }
            )
        }
        .alert("Confirmer la modification", isPresented: $showingConfirmation) {
            Button("Annuler", role: .cancel) {
                title = originalTitle
                pendingTitle = ""
            }
            Button("Enregistrer") {
                onUpdate(pendingTitle)
                originalTitle = pendingTitle
                pendingTitle = ""
            }
        } message: {
            Text("Voulez-vous enregistrer les modifications apportées à '\(originalTitle)' ?")
        }
    }
    
    private func confirmUpdate() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Si le titre n'a pas changé, ne rien faire
        guard trimmedTitle != originalTitle else { return }
        
        // Si le titre est vide, restaurer l'original
        guard !trimmedTitle.isEmpty else {
            title = originalTitle
            return
        }
        
        // Demander confirmation pour la modification
        pendingTitle = trimmedTitle
        showingConfirmation = true
    }
}





