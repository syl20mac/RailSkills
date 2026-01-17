//
//  ChecklistRow.swift
//  RailSkills
//
//  Composant réutilisable pour afficher une ligne de checklist (catégorie ou question)
//

import SwiftUI

/// Composant pour afficher une ligne de checklist (catégorie ou question)
struct ChecklistRow: View {
    let item: ChecklistItem
    @Binding var state: Int
    let isExpanded: Bool
    /// Indique si les interactions de suivi sont autorisées pour cette ligne
    let isInteractionEnabled: Bool
    let onCategoryToggle: (() -> Void)?
    let onToggle: (Int) -> Void
    @ObservedObject var vm: ViewModel
    @State private var showingNoteEditor = false
    @State private var showingExpectedAnswer = false
    @State private var noteText: String = ""
    
    // État local pour le toggle
    @State private var localState: Int = 0
    
    // Mode d'interaction préféré
    @AppStorage("interactionMode") private var interactionMode: String = InteractionMode.toggle.rawValue
    
    // Détection de la taille de l'appareil
    @Environment(\.horizontalSizeClass) private var hSizeClass

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                if item.isCategory {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        onCategoryToggle?()
                        }
                    }) {
                        HStack(spacing: 12) {
                            // Icône de chevron avec animation
                            Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                                .foregroundStyle(SNCFColors.ceruleen)
                                .font(.title3)
                                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
                                .accessibilityHidden(true)
                            
                            // Icône de dossier
                            Image(systemName: "folder.fill")
                                .foregroundStyle(SNCFColors.ceruleen)
                                .font(.title3)
                                .accessibilityHidden(true)
                            
                            Text(item.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            // Badge de progression amélioré
                            HStack(spacing: 4) {
                                if isCategoryComplete(for: item) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(SNCFColors.menthe)
                                        .font(.caption)
                                        .accessibilityHidden(true)
                                }
                            Text(getCategoryProgressText(for: item))
                                .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(isCategoryComplete(for: item) ? SNCFColors.menthe : .primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(isCategoryComplete(for: item) ? SNCFColors.menthe.opacity(0.15) : Color.gray.opacity(0.15))
                                    )
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isExpanded ? SNCFColors.ceruleen.opacity(0.3) : Color.clear, lineWidth: 2)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Catégorie \(item.title)")
                    .accessibilityHint(isExpanded ? "Double-tapez pour replier la catégorie" : "Double-tapez pour déplier la catégorie")
                    .accessibilityValue("\(getCategoryProgressText(for: item)) questions complétées\(isCategoryComplete(for: item) ? ", catégorie complète" : "")")
                } else {
                    questionLayout
                }
            }
        }
        .padding(.horizontal, item.isCategory ? 12 : 20)
        .padding(.vertical, item.isCategory ? 10 : 16)
        .background(
            Group {
                if item.isCategory {
                    Color.clear
                } else if hSizeClass == .compact {
                    Color.clear
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.02), radius: 2, x: 0, y: 1)
                }
            }
        )
        .onAppear {
            localState = vm.state(for: item)
        }
        .onChange(of: state) { _, newValue in
            localState = newValue
        }
        .sheet(isPresented: $showingNoteEditor) {
            NoteEditorSheet(
                item: item,
                noteText: $noteText,
                onSave: { note in
                    vm.setNote(note, for: item)
                    showingNoteEditor = false
                },
                onCancel: {
                    showingNoteEditor = false
                }
            )
        }
        .sheet(isPresented: $showingExpectedAnswer) {
            expectedAnswerSheet
        }
    }

    @ViewBuilder
    private var questionLayout: some View {
        if hSizeClass == .compact {
            compactQuestionLayout
        } else {
            regularQuestionLayout
        }
    }

    private var compactQuestionLayout: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    Text(item.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundStyle(SNCFColors.ceruleen)
                }
                .onTapGesture {
                    showingExpectedAnswer = true
                }
                
                if let evalDate = vm.evaluationDate(for: item) {
                    Text("Suivi le \(DateFormatHelper.formatDate(evalDate))")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.7))
                        .accessibilityLabel("Date de suivi: \(DateFormatHelper.formatDate(evalDate))")
                }
            }
            
            HStack(alignment: .center, spacing: 12) {
                noteButton
                stateControl
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if let note = vm.note(for: item), !note.isEmpty {
                notePreview(note, compact: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .swipeToChangeState(
            state: $state,
            isEnabled: isInteractionEnabled,
            onStateChange: { newValue in
                onToggle(newValue)
            }
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Question: \(item.title)")
        .accessibilityHint("Balayez horizontalement pour changer rapidement l'état de validation")
    }

    private var regularQuestionLayout: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(item.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        
                        Image(systemName: "info.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(SNCFColors.ceruleen)
                    }
                    .onTapGesture {
                        showingExpectedAnswer = true
                    }
                    
                    if let evalDate = vm.evaluationDate(for: item) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                                .foregroundStyle(.primary.opacity(0.6))
                                .accessibilityHidden(true)
                            Text("Suivi le \(DateFormatHelper.formatDate(evalDate))")
                                .font(.caption)
                                .foregroundStyle(.primary.opacity(0.7))
                        }
                        .accessibilityLabel("Date de suivi: \(DateFormatHelper.formatDate(evalDate))")
                    }
                }
                
                if let note = vm.note(for: item), !note.isEmpty {
                    notePreview(note, compact: false)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .trailing, spacing: 12) {
                noteButton
                stateControl
            }
        }
        .swipeToChangeState(
            state: $state,
            isEnabled: isInteractionEnabled,
            onStateChange: { newValue in
                onToggle(newValue)
            }
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Question: \(item.title)")
        .accessibilityHint("Balayez horizontalement pour changer rapidement l'état de validation")
    }

    @ViewBuilder
    private func notePreview(_ note: String, compact: Bool) -> some View {
        if compact {
            VStack(alignment: .leading, spacing: 6) {
                Text(note)
                    .font(.body)
                    .foregroundStyle(.primary.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                
                if note.count > 100 {
                    Text("Toucher pour voir la note complète")
                        .font(.caption2)
                        .foregroundStyle(SNCFColors.ceruleen)
                        .italic()
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(SNCFColors.ceruleen.opacity(0.08))
            )
            .onTapGesture {
                noteText = note
                showingNoteEditor = true
            }
        } else {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "note.text")
                    .foregroundStyle(SNCFColors.ceruleen)
                    .font(.caption)
                    .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(note)
                        .font(.callout)
                        .foregroundStyle(.primary.opacity(0.8))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if note.count > 100 {
                        Text("Toucher pour voir la note complète")
                            .font(.caption2)
                            .foregroundStyle(SNCFColors.ceruleen)
                            .italic()
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(SNCFColors.ceruleen.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(SNCFColors.ceruleen.opacity(0.15), lineWidth: 1)
                    )
            )
            .onTapGesture {
                noteText = note
                showingNoteEditor = true
            }
        }
    }

    private var noteButton: some View {
        Button {
            noteText = vm.note(for: item) ?? ""
            showingNoteEditor = true
        } label: {
            noteButtonLabel
        }
        .buttonStyle(.plain)
        .disabled(!isInteractionEnabled)
        .opacity(isInteractionEnabled ? 1 : 0.5)
        .accessibilityLabel(hasNote ? "Voir la note pour: \(item.title)" : "Ajouter une note pour: \(item.title)")
        .accessibilityHint("Double-tapez pour \(hasNote ? "modifier" : "ajouter") une note")
    }

    @ViewBuilder
    private var noteButtonLabel: some View {
        if hSizeClass == .compact {
            HStack(spacing: 8) {
                Image(systemName: hasNote ? "note.text" : "note.text.badge.plus")
                Text(hasNote ? "Voir la note" : "Ajouter une note")
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(hasNote ? SNCFColors.ceruleen : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill((hasNote ? SNCFColors.ceruleen : Color.gray).opacity(0.16))
            )
        } else {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "note.text")
                    .symbolVariant(hasNote ? .fill : .none)
                    .foregroundStyle(hasNote ? SNCFColors.ceruleen : .primary.opacity(0.6))
                    .font(.title2)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(hasNote ? SNCFColors.ceruleen.opacity(0.15) : Color.gray.opacity(0.15))
                    )
                
                if hasNote {
                    Circle()
                        .fill(SNCFColors.ceruleen)
                        .frame(width: 8, height: 8)
                        .offset(x: 6, y: 6)
                }
            }
        }
    }

    private var stateControl: some View {
        StateInteractionView(
            state: Binding(
                get: { localState },
                set: { newValue in
                    localState = newValue
                    onToggle(newValue)
                }
            ),
            mode: InteractionMode(rawValue: interactionMode) ?? .toggle
        )
        .disabled(!isInteractionEnabled)
        .opacity(isInteractionEnabled ? 1 : 0.4)
        .accessibilityLabel("État de validation pour: \(item.title)")
        .accessibilityHint("Double-tapez pour changer l'état, balayez horizontalement pour changer rapidement entre les états")
    }

    private var hasNote: Bool {
        if let note = vm.note(for: item) {
            return !note.isEmpty
        }
        return false
    }
    
    private func getCategoryProgressText(for categoryItem: ChecklistItem) -> String {
        guard categoryItem.isCategory, let cl = vm.store.checklist else { return "" }
        
        let items = cl.items
        guard let categoryIndex = items.firstIndex(where: { $0.id == categoryItem.id }) else { return "" }
        
        // Trouver toutes les questions après cette catégorie jusqu'à la prochaine catégorie
        var questions: [ChecklistItem] = []
        for i in (categoryIndex + 1)..<items.count {
            let item = items[i]
            if item.isCategory {
                break
            }
            questions.append(item)
        }
        
        let totalQuestions = questions.count
        let completedQuestions = questions.filter { vm.state(for: $0) == 2 }.count
        
        return "\(completedQuestions)/\(totalQuestions)"
    }
    
    private func isCategoryComplete(for categoryItem: ChecklistItem) -> Bool {
        guard categoryItem.isCategory, let cl = vm.store.checklist else { return false }
        let items = cl.items
        guard let categoryIndex = items.firstIndex(where: { $0.id == categoryItem.id }) else { return false }
        var questions: [ChecklistItem] = []
        for i in (categoryIndex + 1)..<items.count {
            let item = items[i]
            if item.isCategory { break }
            questions.append(item)
        }
        let totalQuestions = questions.count
        guard totalQuestions > 0 else { return false }
        let completedQuestions = questions.filter { vm.state(for: $0) == 2 }.count
        return completedQuestions == totalQuestions
    }
    
    // MARK: - Expected Answer
    
    /// Vérifie si la question a des réponses attendues
    private var hasExpectedAnswer: Bool {
        if let notes = item.notes, !notes.isEmpty {
            return true
        }
        return false
    }
    
    /// Retourne les réponses attendues pour une question
    private var expectedAnswer: String {
        if let notes = item.notes, !notes.isEmpty {
            return notes
        }
        return "Aucune réponse attendue n'a été spécifiée pour cette question."
    }
    
    /// Sheet affichant les réponses attendues
    private var expectedAnswerSheet: some View {
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
                        
                        Text(item.title)
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
                        
                        if hasExpectedAnswer {
                            Text(expectedAnswer)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Image(systemName: "info.circle")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                
                                Text("Aucune réponse attendue n'a été spécifiée pour cette question.")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                
                                Text("Les réponses attendues peuvent être ajoutées lors de la création ou de la modification de la checklist dans l'éditeur.")
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
        .presentationDetents([.height(400), .large])
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled)
    }
}


