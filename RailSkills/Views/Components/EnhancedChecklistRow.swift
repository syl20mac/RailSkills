//
//  EnhancedChecklistRow.swift
//  RailSkills
//
//  Ligne de checklist améliorée avec design glassmorphism et animations
//

import SwiftUI

/// Ligne de checklist moderne avec effet glassmorphism
struct EnhancedChecklistRow: View {
    let item: ChecklistItem
    @Binding var state: Int
    let isInteractive: Bool
    let hasNote: Bool
    let onStateChange: (Int) -> Void
    let onNoteTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            if isInteractive {
                HapticManager.impact(style: .light)
                // Cycle entre les états
                let newState = (state + 1) % 4
                state = newState
                onStateChange(newState)
            }
        } label: {
            HStack(spacing: 16) {
                // Indicateur visuel du statut (barre latérale colorée)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(stateColor)
                    .frame(width: 5)
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Titre
                    Text(item.title)
                        .font(.body.weight(.medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Notes si présentes
                    if hasNote {
                        HStack(spacing: 6) {
                            Image(systemName: "note.text")
                                .font(.caption2)
                                .foregroundColor(SNCFColors.ceruleen)
                            Text("Note présente")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Bouton de note
                Button {
                    HapticManager.selection()
                    onNoteTap()
                } label: {
                    Image(systemName: hasNote ? "note.text.fill" : "note.text.badge.plus")
                        .font(.title3)
                        .foregroundColor(hasNote ? SNCFColors.ceruleen : .secondary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill((hasNote ? SNCFColors.ceruleen : Color.secondary).opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                .disabled(!isInteractive)
                
                // Badge de statut
                StatusBadge(status: checklistState, size: .medium)
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.regularMaterial)
                    
                    // Bordure colorée selon l'état
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(stateColor.opacity(0.3), lineWidth: 2)
                }
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!isInteractive)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
    
    // Conversion de l'état Int en ChecklistItemState
    private var checklistState: ChecklistItemState {
        ChecklistItemState(rawValue: state) ?? .notProcessed
    }
    
    // Couleur selon l'état
    private var stateColor: Color {
        Color.sncfState(state)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        EnhancedChecklistRow(
            item: ChecklistItem(title: "Connaissance de la réglementation CFL", isCategory: false),
            state: .constant(0),
            isInteractive: true,
            hasNote: false,
            onStateChange: { _ in },
            onNoteTap: { }
        )
        
        EnhancedChecklistRow(
            item: ChecklistItem(title: "Procédures de sécurité", isCategory: false),
            state: .constant(2),
            isInteractive: true,
            hasNote: true,
            onStateChange: { _ in },
            onNoteTap: { }
        )
    }
    .padding()
}


