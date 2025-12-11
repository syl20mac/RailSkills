//
//  StateInteractionViews.swift
//  RailSkills
//
//  Composants d'interaction pour les états des questions de checklist
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Haptic Feedback Helper

/// Fournit un feedback haptique adapté à l'état sélectionné
private func provideHapticFeedback(for state: Int) {
    #if canImport(UIKit)
    let generator = UINotificationFeedbackGenerator()
    
    switch state {
    case 2: // Validé
        generator.notificationOccurred(.success)
    case 0: // Non validé
        generator.notificationOccurred(.warning)
    default: // Partiel, N/A
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    #endif
}

// MARK: - State Interaction View

/// Composant adaptable qui affiche le bon mode d'interaction selon les préférences
struct StateInteractionView: View {
    @Binding var state: Int
    let mode: InteractionMode
    
    var body: some View {
        switch mode {
        case .toggle:
            QuadStateToggle(state: $state)
        case .segmented:
            SegmentedStateControl(state: $state)
        case .buttons:
            ButtonsStateControl(state: $state)
        case .menu:
            MenuStateControl(state: $state)
        }
    }
}

// MARK: - Segmented State Control

/// Mode segmenté compact
struct SegmentedStateControl: View {
    @Binding var state: Int
    
    var body: some View {
        Picker("État", selection: $state) {
            Text("☐").tag(0)
            Text("◪").tag(1)
            Text("☑").tag(2)
            Text("⊘").tag(3)
        }
        .pickerStyle(.segmented)
        .onChange(of: state) { _, newValue in
            provideHapticFeedback(for: newValue)
        }
        // S'adapte à l'espace disponible sans forcer un wrapping
        .frame(minWidth: 160)
        .frame(maxWidth: 220)
    }
}

// MARK: - Buttons State Control

/// Mode boutons individuels
struct ButtonsStateControl: View {
    @Binding var state: Int
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach([0, 1, 2, 3], id: \.self) { value in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        state = value
                        provideHapticFeedback(for: value)
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: icon(for: value))
                            .font(.title3)
                            .foregroundStyle(state == value ? Color.forState(value) : .gray)
                        
                        Text(label(for: value))
                            .font(.caption2)
                            .foregroundStyle(state == value ? Color.forState(value) : .secondary)
                    }
                    .frame(width: 45, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(state == value ? Color.forState(value, opacity: 0.15) : Color.gray.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(state == value ? Color.forState(value) : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func icon(for state: Int) -> String {
        switch state {
        case 3: return "minus.circle.fill"
        case 2: return "checkmark.circle.fill"
        case 1: return "circle.lefthalf.filled"
        default: return "xmark.circle.fill"
        }
    }
    
    private func label(for state: Int) -> String {
        switch state {
        case 3: return "Non traité"
        case 2: return "Validé"
        case 1: return "Partiel"
        default: return "Non"
        }
    }
}

// MARK: - Menu State Control

/// Mode menu déroulant
struct MenuStateControl: View {
    @Binding var state: Int
    
    var body: some View {
        Menu {
            Button {
                state = 2
                provideHapticFeedback(for: 2)
            } label: {
                Label("☑ Validé", systemImage: "checkmark.circle.fill")
            }
            
            Button {
                state = 1
                provideHapticFeedback(for: 1)
            } label: {
                Label("◪ Partiel", systemImage: "circle.lefthalf.filled")
            }
            
            Button {
                state = 0
                provideHapticFeedback(for: 0)
            } label: {
                Label("☐ Non validé", systemImage: "xmark.circle")
            }
            
            Button {
                state = 3
                provideHapticFeedback(for: 3)
            } label: {
                Label("⊘ Non traité", systemImage: "minus.circle")
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon(for: state))
                    .foregroundStyle(Color.forState(state))
                Text(label(for: state))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.forState(state, opacity: 0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.forState(state, opacity: 0.3), lineWidth: 1)
            )
        }
    }
    
    private func icon(for state: Int) -> String {
        switch state {
        case 3: return "minus.circle.fill"
        case 2: return "checkmark.circle.fill"
        case 1: return "circle.lefthalf.filled"
        default: return "xmark.circle.fill"
        }
    }
    
    private func label(for state: Int) -> String {
        switch state {
        case 3: return "Non traité"
        case 2: return "Validé"
        case 1: return "Partiel"
        default: return "Non validé"
        }
    }
}

// MARK: - Quad State Toggle

/// Toggle à 4 états pour les questions de checklist
/// États: 0 = Non validé ☐, 1 = Partiel ◪, 2 = Validé ☑, 3 = Non traité
struct QuadStateToggle: View {
    @Binding var state: Int
    @GestureState private var dragX: CGFloat = 0
    
    private let order: [Int] = [0, 1, 2, 3]  // Non validé, Partiel, Validé, Non traité
    private let height: CGFloat = 32
    private let width: CGFloat = 200  // Largeur optimisée pour 4 états
    
    private var clampedState: Int {
        max(0, min(3, state))
    }

    var body: some View {
        GeometryReader { geo in
            let H = height
            let circleSize = H - 8
            let proposedWidth = geo.size.width
            let fallbackWidth = width
            let W = max(circleSize + 12, proposedWidth > 0 ? proposedWidth : fallbackWidth)
            let availableWidth = max(W - circleSize, 1)
            let step = availableWidth / 3  // 3 intervalles pour 4 positions
            let currentIndex = order.firstIndex(of: clampedState) ?? 0
            let baseX = CGFloat(currentIndex) * step
            let currentX = max(0, min(availableWidth, baseX + dragX))

            ZStack {
                // Fond avec couleur adaptative selon l'état
                RoundedRectangle(cornerRadius: H/2)
                    .fill(Color.forState(clampedState, opacity: 0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: H/2)
                            .stroke(Color.forState(clampedState, opacity: 0.4), lineWidth: 1.5)
                    )
                
                // Labels des états
                HStack(spacing: 0) {
                    Text("☐")
                        .frame(width: W/4)
                        .foregroundStyle(labelColor(forSegment: 0, selected: clampedState))
                        .font(.caption2)
                    Text("◪")
                        .frame(width: W/4)
                        .foregroundStyle(labelColor(forSegment: 1, selected: clampedState))
                        .font(.caption2)
                    Text("☑")
                        .frame(width: W/4)
                        .foregroundStyle(labelColor(forSegment: 2, selected: clampedState))
                        .font(.caption2)
                    Text("⊘")
                        .frame(width: W/4)
                        .foregroundStyle(labelColor(forSegment: 3, selected: clampedState))
                        .font(.caption2)
                }
                .font(.caption2)
                .allowsHitTesting(false)

                // Bouton circulaire avec icône
                Circle()
                    .fill(Color.forState(clampedState))
                    .frame(width: circleSize, height: circleSize)
                    .shadow(color: Color.forState(clampedState, opacity: 0.3), radius: 3, x: 0, y: 2)
                    .overlay(
                        Image(systemName: icon(for: clampedState))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                    .position(x: circleSize/2 + currentX, y: H/2)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: clampedState)
            .frame(width: W, height: H, alignment: .leading)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragX) { value, dragState, _ in
                        if abs(value.translation.width) > abs(value.translation.height), abs(value.translation.width) > 4 {
                            dragState = value.translation.width
                        } else {
                            dragState = 0
                        }
                    }
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height), abs(value.translation.width) > 8 else {
                            return // geste vertical ou mouvement trop léger ignoré
                        }

                        if let currentIndex = order.firstIndex(of: clampedState) {
                            let baseX = CGFloat(currentIndex) * step
                            let total = baseX + value.translation.width
                            let snappedIndex = Int(round(total / step))
                            let clampedIndex = max(0, min(3, snappedIndex))
                            if clampedIndex < order.count {
                                let newState = order[clampedIndex]
                                state = newState
                                provideHapticFeedback(for: newState)
                            }
                        }
                    }
            )
            .onTapGesture {
                if let currentIdx = order.firstIndex(of: clampedState) {
                    let nextIdx = (currentIdx + 1) % order.count
                    let newState = order[nextIdx]
                    state = newState
                    provideHapticFeedback(for: newState)
                } else {
                    state = order[0]
                    provideHapticFeedback(for: order[0])
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("État de validation")
            .accessibilityValue(accessibilityValue(for: clampedState))
            .accessibilityAdjustableAction { direction in
                guard let idx = order.firstIndex(of: state) else { return }
                switch direction {
                case .increment:
                    let next = min(order.count - 1, idx + 1)
                    state = order[next]
                case .decrement:
                    let prev = max(0, idx - 1)
                    state = order[prev]
                default: break
                }
            }
        }
        .frame(height: height)
    }

    /// Retourne l'icône correspondant à l'état
    private func icon(for state: Int) -> String {
        switch state {
        case 3: return "minus.circle.fill"  // Non traité
        case 2: return "checkmark.circle.fill"  // Validé
        case 1: return "minus.circle"  // Partiel
        default: return "xmark.circle.fill"  // Non validé
        }
    }

    /// Retourne la description textuelle pour l'accessibilité
    private func accessibilityValue(for state: Int) -> String {
        switch state {
        case 3: return "Non traité"
        case 2: return "Validé"
        case 1: return "Partiel"
        default: return "Non validé"
        }
    }

    /// Détermine la couleur du label selon si le segment est sélectionné
    private func labelColor(forSegment segment: Int, selected: Int) -> Color {
        if segment == selected {
            return Color.forState(selected)
        } else {
            return .secondary.opacity(0.6)
        }
    }
}

