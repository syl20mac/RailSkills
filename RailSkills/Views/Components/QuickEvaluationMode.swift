//
//  QuickEvaluationMode.swift
//  RailSkills
//
//  Mode d'évaluation rapide - Une question à la fois en plein écran
//

import SwiftUI

/// Mode d'évaluation rapide - Focus sur une seule question à la fois
struct QuickEvaluationMode: View {
    @ObservedObject var vm: ViewModel
    let checklistType: ChecklistType
    @State private var currentQuestionIndex: Int = 0
    @State private var showingExpectedAnswer = false
    @State private var showingNoteEditor = false
    @State private var noteText: String = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    /// Questions de la checklist (filtrées pour ne garder que les questions, pas les catégories)
    private var questions: [ChecklistItem] {
        vm.checklist(for: checklistType)?.questions ?? []
    }

    /// Question actuellement affichée
    private var currentQuestion: ChecklistItem? {
        questions.indices.contains(currentQuestionIndex) ? questions[currentQuestionIndex] : nil
    }

    /// Progression globale (0.0 à 1.0)
    private var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(questions.count)
    }

    var body: some View {
        ZStack {
            // Fond dégradé adaptatif
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header avec progression
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                // Question principale
                if let question = currentQuestion {
                    ScrollView {
                        VStack(spacing: 32) {
                            questionCard(question)

                            // Bouton pour voir les réponses attendues
                            expectedAnswerButton(for: question)

                            // Boutons d'état (gros et accessibles)
                            stateButtons(for: question)

                            // Note existante ou bouton pour ajouter
                            noteSection(for: question)
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer()

                    // Navigation
                    navigationButtons
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showingExpectedAnswer) {
            if let question = currentQuestion {
                expectedAnswerSheet(for: question)
            }
        }
        .sheet(isPresented: $showingNoteEditor) {
            if let question = currentQuestion {
                NoteEditorSheet(
                    item: question,
                    noteText: $noteText,
                    onSave: { note in
                        vm.setNote(note, for: question, type: checklistType)
                        showingNoteEditor = false
                    },
                    onCancel: {
                        showingNoteEditor = false
                    }
                )
            }
        }
    }

    // MARK: - Composants

    /// Fond dégradé selon le mode clair/sombre
    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color.black, Color(white: 0.1)]
                : [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Header avec barre de progression et boutons
    private var header: some View {
        VStack(spacing: 16) {
            // Barre de progression
            ProgressView(value: progress)
                .tint(.blue)
                .scaleEffect(y: 2)

            HStack {
                Text("Question \(currentQuestionIndex + 1)/\(questions.count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary.opacity(0.7))

                Spacer()

                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Quitter")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
                }
            }
        }
    }

    /// Carte de la question principale
    private func questionCard(_ question: ChecklistItem) -> some View {
        VStack(spacing: 20) {
            // Badge de catégorie (si disponible)
            if let category = getCategoryFor(question) {
                Text(category.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.15))
                    )
            }

            // Titre de la question (cliquable pour voir les attendus)
            Button {
                showingExpectedAnswer = true
            } label: {
                HStack(alignment: .top, spacing: 8) {
                    Text(question.title)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)

                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                        .foregroundStyle(SNCFColors.ceruleen)
                }
            }
            .buttonStyle(.plain)

            // État actuel
            let currentState = vm.state(for: question, type: checklistType)
            HStack(spacing: 8) {
                Image(systemName: iconForState(currentState))
                    .font(.title3)
                Text(labelForState(currentState))
                    .font(.body)
                    .fontWeight(.medium)
            }
            .foregroundStyle(Color.forState(currentState))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.forState(currentState).opacity(0.15))
            )
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
        )
    }

    /// Bouton pour afficher les réponses attendues
    private func expectedAnswerButton(for question: ChecklistItem) -> some View {
        Button {
            showingExpectedAnswer = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundStyle(SNCFColors.safran)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Voir les réponses attendues")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if hasExpectedAnswer(for: question) {
                        Text("Touchez pour afficher les critères de validation")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Aucune réponse attendue définie")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(SNCFColors.safran.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(SNCFColors.safran.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    /// Sheet affichant les réponses attendues
    private func expectedAnswerSheet(for question: ChecklistItem) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Icône et titre
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(SNCFColors.safran.opacity(0.15))
                                .frame(width: 56, height: 56)

                            Image(systemName: "lightbulb.fill")
                                .font(.title)
                                .foregroundStyle(SNCFColors.safran)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Réponses attendues")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)

                            Text("Critères de validation")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    // Question concernée
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question :")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text(question.title)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )

                    // Réponses attendues
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Réponses attendues :")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        if hasExpectedAnswer(for: question) {
                            Text(getExpectedAnswer(for: question))
                                .font(.body)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Image(systemName: "info.circle")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)

                                Text(
                                    "Aucune réponse attendue n'a été spécifiée pour cette question."
                                )
                                .font(.body)
                                .foregroundStyle(.secondary)

                                Text(
                                    "Les réponses attendues peuvent être ajoutées lors de la création ou de la modification de la checklist dans l'éditeur."
                                )
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(SNCFColors.safran.opacity(0.08))
                    )

                    Spacer()
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        showingExpectedAnswer = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    /// Boutons d'état (4 grands boutons)
    private func stateButtons(for question: ChecklistItem) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach([2, 1, 0, 3], id: \.self) { stateValue in
                stateButton(for: question, state: stateValue)
            }
        }
    }

    /// Bouton d'état individuel
    private func stateButton(for question: ChecklistItem, state: Int) -> some View {
        let currentState = vm.state(for: question, type: checklistType)
        let isSelected = currentState == state

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                vm.setState(state, for: question, type: checklistType)

                // Feedback haptique
                provideHapticFeedback(for: state)

                // Auto-avancer après un délai
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    moveToNextQuestion()
                }
            }
        } label: {
            VStack(spacing: 12) {
                Image(systemName: iconForState(state))
                    .font(.system(size: 36, weight: .semibold))

                Text(labelForState(state))
                    .font(.callout)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(isSelected ? .white : Color.forState(state))
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? Color.forState(state) : Color.forState(state).opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.forState(state), lineWidth: isSelected ? 3 : 2)
            )
            .shadow(
                color: isSelected ? Color.forState(state).opacity(0.4) : .clear, radius: 12, x: 0,
                y: 6
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }

    /// Section de notes
    private func noteSection(for question: ChecklistItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let note = vm.note(for: question, type: checklistType), !note.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "note.text")
                            .foregroundStyle(.blue)
                        Text("Note :")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    Text(note)
                        .font(.body)
                        .foregroundStyle(.primary.opacity(0.8))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.08))
                )
                .onTapGesture {
                    noteText = note
                    showingNoteEditor = true
                }
            }

            Button {
                noteText = vm.note(for: question, type: checklistType) ?? ""
                showingNoteEditor = true
            } label: {
                HStack {
                    Image(
                        systemName: vm.note(for: question)?.isEmpty == false
                            ? "note.text" : "note.text.badge.plus")
                    Text(
                        vm.note(for: question)?.isEmpty == false
                            ? "Modifier la note" : "Ajouter une note")
                }
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
        }
    }

    /// Boutons de navigation
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Bouton précédent
            Button {
                moveToPreviousQuestion()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("Précédent")
                }
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(
                    currentQuestionIndex == 0 ? Color.primary.opacity(0.3) : Color.primary
                )
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.tertiarySystemBackground))
                )
            }
            .disabled(currentQuestionIndex == 0)
            .buttonStyle(.plain)

            // Bouton suivant
            Button {
                moveToNextQuestion()
            } label: {
                HStack(spacing: 8) {
                    Text(currentQuestionIndex >= questions.count - 1 ? "Terminer" : "Suivant")
                    Image(
                        systemName: currentQuestionIndex >= questions.count - 1
                            ? "checkmark" : "chevron.right")
                }
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            currentQuestionIndex >= questions.count - 1 ? Color.green : Color.blue)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    /// Trouve la catégorie d'une question
    private func getCategoryFor(_ question: ChecklistItem) -> ChecklistItem? {
        guard let checklist = vm.store.checklist else { return nil }

        var currentCategory: ChecklistItem?
        for item in checklist.items {
            if item.isCategory {
                currentCategory = item
            } else if item.id == question.id {
                return currentCategory
            }
        }
        return nil
    }

    /// Vérifie si la question a des réponses attendues
    private func hasExpectedAnswer(for question: ChecklistItem) -> Bool {
        if let notes = question.notes, !notes.isEmpty {
            return true
        }
        return false
    }

    /// Retourne les réponses attendues pour une question
    private func getExpectedAnswer(for question: ChecklistItem) -> String {
        if let notes = question.notes, !notes.isEmpty {
            return notes
        }
        return "Aucune réponse attendue n'a été spécifiée pour cette question."
    }

    /// Icône pour un état
    private func iconForState(_ state: Int) -> String {
        switch state {
        case 0: return "xmark.circle.fill"
        case 1: return "circle.lefthalf.filled"
        case 2: return "checkmark.circle.fill"
        case 3: return "minus.circle.fill"
        default: return "questionmark.circle"
        }
    }

    /// Label pour un état
    private func labelForState(_ state: Int) -> String {
        switch state {
        case 0: return "Non validé"
        case 1: return "Partiel"
        case 2: return "Validé"
        case 3: return "N/A"
        default: return "Inconnu"
        }
    }

    /// Passe à la question suivante
    private func moveToNextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            withAnimation {
                currentQuestionIndex += 1
            }
        } else {
            // Fin de l'évaluation
            dismiss()
        }
    }

    /// Revient à la question précédente
    private func moveToPreviousQuestion() {
        if currentQuestionIndex > 0 {
            withAnimation {
                currentQuestionIndex -= 1
            }
        }
    }

    /// Feedback haptique selon l'état
    private func provideHapticFeedback(for state: Int) {
        #if canImport(UIKit)
            let generator = UINotificationFeedbackGenerator()

            switch state {
            case 2:  // Validé
                generator.notificationOccurred(.success)
            case 0:  // Non validé
                generator.notificationOccurred(.warning)
            default:  // Partiel, N/A
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }
        #endif
    }
}
