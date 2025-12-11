//
//  CategorySectionView.swift
//  RailSkills
//
//  Vue pour afficher une section de catégorie de checklist
//

import SwiftUI

/// Vue pour afficher une section de catégorie avec ses questions (mode compact iPhone)
struct CategorySectionView: View {
    let section: ChecklistSection
    let progress: (completed: Int, total: Int)?
    let isExpanded: Bool
    let canInteract: Bool
    let accentColor: Color
    let onToggle: (UUID) -> Void
    let onItemStateChange: (ChecklistItem, Int) -> Void
    let getState: (ChecklistItem) -> Int
    @ObservedObject var vm: ViewModel
    @Environment(\.horizontalSizeClass) private var hSizeClass
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // En-tête de catégorie
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    onToggle(section.categoryId)
                }
            } label: {
                categoryHeader
            }
            .buttonStyle(.plain)
            
            // Barre de progression
            if let progress = progress, progress.total > 0 {
                let ratio = Double(progress.completed) / Double(progress.total)
                ProgressView(value: ratio)
                    .tint(accentColor)
                    .animation(.easeInOut(duration: 0.25), value: ratio)
            }
            
            // Questions (si déployé)
            if isExpanded {
                categoryQuestions
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(categoryBackground)
    }
    
    private var categoryHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                .foregroundStyle(accentColor)
                .font(.title3)
            
            Text(section.categoryTitle)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Spacer(minLength: 8)
            
            if let progress = progress {
                let total = max(progress.total, 1)
                let ratio = Double(progress.completed) / Double(total)
                
                HStack(spacing: 8) {
                    Text("\(progress.completed)/\(progress.total)")
                    Text("\(Int(ratio * 100))%")
                }
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(accentColor.opacity(0.15))
                )
                .foregroundStyle(accentColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Catégorie \(section.categoryTitle)")
        .accessibilityHint(isExpanded ? "Double-tapez pour replier" : "Double-tapez pour déplier")
        .accessibilityValue(progressLabel)
    }
    
    private var progressLabel: String {
        guard let progress = progress else { return "Aucune progression" }
        // Éviter la division par zéro
        let total = max(progress.total, 1)
        let ratio = Double(progress.completed) / Double(total)
        return "\(progress.completed) sur \(progress.total) questions complétées, \(Int(ratio * 100)) pour cent"
    }
    
    @ViewBuilder
    private var categoryQuestions: some View {
        if section.items.isEmpty {
            Text("Aucune question dans cette catégorie")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
        } else {
            VStack(spacing: 12) {
                ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                    ChecklistRow(
                        item: item,
                        state: Binding(
                            get: { getState(item) },
                            set: { newValue in
                                onItemStateChange(item, newValue)
                            }
                        ),
                        isExpanded: false,
                        isInteractionEnabled: canInteract,
                        onCategoryToggle: nil,
                        onToggle: { newValue in
                            onItemStateChange(item, newValue)
                        },
                        vm: vm
                    )
                    .padding(.vertical, 4)
                    
                    if index < section.items.count - 1 {
                        Divider()
                            .padding(.vertical, 4)
                            .padding(.leading, 4)
                    }
                }
            }
        }
    }
    
    private var categoryBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(UIColor.systemBackground))
            .overlay(alignment: .leading) {
                if hSizeClass != .compact,
                   let progress = progress,
                   progress.total > 0 {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(accentColor)
                        .frame(width: 6)
                        .opacity(0.9)
                }
            }
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

