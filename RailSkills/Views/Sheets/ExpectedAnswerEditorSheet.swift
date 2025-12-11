//
//  ExpectedAnswerEditorSheet.swift
//  RailSkills
//
//  Sheet pour éditer les réponses attendues d'une question
//

import SwiftUI

/// Sheet pour éditer les réponses attendues d'une question
struct ExpectedAnswerEditorSheet: View {
    let questionTitle: String
    @Binding var expectedAnswer: String
    let originalAnswer: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    
    @State private var editedAnswer: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // En-tête informatif
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.title2)
                            .foregroundStyle(SNCFColors.safran)
                        
                        Text("Réponses attendues")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text("Question : \(questionTitle)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
                
                Divider()
                
                // Instructions
                VStack(alignment: .leading, spacing: 4) {
                    Text("Définissez les réponses attendues pour cette question.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Ces informations seront visibles par les CTT lorsqu'ils cliqueront sur la question.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(SNCFColors.safran.opacity(0.1))
                )
                
                // Zone de texte pour les réponses attendues
                VStack(alignment: .leading, spacing: 8) {
                    Text("Réponses attendues")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    TextEditor(text: $editedAnswer)
                        .frame(minHeight: 200, maxHeight: 400)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    isTextFieldFocused ? SNCFColors.ceruleen : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .focused($isTextFieldFocused)
                        .scrollContentBackground(.hidden)
                    
                    // Compteur de caractères
                    HStack {
                        Spacer()
                        Text("\(editedAnswer.count) caractères")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        onCancel()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        onSave(editedAnswer)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(editedAnswer == originalAnswer)
                }
            }
            .onAppear {
                editedAnswer = expectedAnswer
                // Focus automatique après un court délai
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTextFieldFocused = true
                }
            }
        }
        .presentationDetents([.large])
    }
}

