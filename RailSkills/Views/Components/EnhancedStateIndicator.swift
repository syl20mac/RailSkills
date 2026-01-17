//
//  EnhancedStateIndicator.swift
//  RailSkills
//
//  Indicateur d'état amélioré avec animations et feedback visuel
//  Amélioration UX pour une meilleure compréhension des états de validation
//

import SwiftUI

/// Indicateur d'état de validation avec animations et feedback visuel améliorés
struct EnhancedStateIndicator: View {
    // MARK: - Propriétés
    
    /// État actuel (0: Non validé, 1: Partiel, 2: Validé, 3: Non traité)
    @Binding var state: Int
    
    /// Taille de l'indicateur
    var size: CGFloat = 44
    
    /// Afficher le label textuel
    var showLabel: Bool = false
    
    /// Mode lecture seule
    var isReadOnly: Bool = false
    
    // MARK: - État
    
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var previousState: Int = -1
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 6) {
            // Indicateur principal
            Button {
                if !isReadOnly {
                    cycleState()
                }
            } label: {
                ZStack {
                    // Cercle de pulse en arrière-plan
                    Circle()
                        .fill(stateColor.opacity(0.2))
                        .scaleEffect(pulseScale)
                        .opacity(isAnimating ? 0 : 0.5)
                    
                    // Cercle principal avec dégradé
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: stateGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: stateColor.opacity(0.4),
                            radius: isAnimating ? 8 : 4,
                            x: 0,
                            y: isAnimating ? 4 : 2
                        )
                    
                    // Icône centrale
                    Image(systemName: stateIcon)
                        .font(.system(size: size * 0.45, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                }
                .frame(width: size, height: size)
            }
            .buttonStyle(.plain)
            .disabled(isReadOnly)
            .accessibilityLabel(stateAccessibilityLabel)
            .accessibilityHint(isReadOnly ? "" : "Double-tapez pour changer l'état")
            .accessibilityValue(stateLabel)
            
            // Label textuel optionnel
            if showLabel {
                Text(stateLabel)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(stateColor)
                    .lineLimit(1)
            }
        }
        .onChange(of: state) { oldValue, newValue in
            animateStateChange(from: oldValue, to: newValue)
        }
        .onAppear {
            previousState = state
        }
    }
    
    // MARK: - Actions
    
    /// Passe à l'état suivant dans le cycle
    private func cycleState() {
        let nextState = (state + 1) % 4
        state = nextState
        HapticManager.impact(style: .medium)
    }
    
    // MARK: - Animations
    
    /// Anime le changement d'état
    private func animateStateChange(from oldState: Int, to newState: Int) {
        // Animation de pulse
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            isAnimating = true
            pulseScale = 1.5
        }
        
        // Réinitialiser après l'animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isAnimating = false
                pulseScale = 1.0
            }
        }
        
        // Feedback haptique spécial pour l'état "Validé"
        if newState == 2 && oldState != 2 {
            HapticManager.notification(type: .success)
        }
        
        previousState = newState
    }
    
    // MARK: - Propriétés calculées
    
    /// Couleur principale de l'état
    private var stateColor: Color {
        switch state {
        case 0: return SNCFColors.corail      // Non validé - Rouge
        case 1: return SNCFColors.safran      // Partiel - Orange
        case 2: return SNCFColors.menthe      // Validé - Vert
        case 3: return SNCFColors.bleuHorizon // Non traité - Bleu
        default: return Color.gray
        }
    }
    
    /// Couleurs du dégradé pour l'état
    private var stateGradientColors: [Color] {
        switch state {
        case 0: return [SNCFColors.corail, SNCFColors.ocre]
        case 1: return [SNCFColors.safran, SNCFColors.ambre]
        case 2: return [SNCFColors.menthe, SNCFColors.vertEau]
        case 3: return [SNCFColors.ceruleen, SNCFColors.bleuHorizon]
        default: return [Color.gray, Color.gray.opacity(0.7)]
        }
    }
    
    /// Icône SF Symbol pour l'état
    private var stateIcon: String {
        switch state {
        case 0: return "xmark"
        case 1: return "minus"
        case 2: return "checkmark"
        case 3: return "questionmark"
        default: return "circle"
        }
    }
    
    /// Label textuel de l'état
    private var stateLabel: String {
        switch state {
        case 0: return "Non validé"
        case 1: return "Partiel"
        case 2: return "Validé"
        case 3: return "Non traité"
        default: return "Inconnu"
        }
    }
    
    /// Label d'accessibilité
    private var stateAccessibilityLabel: String {
        "État de validation: \(stateLabel)"
    }
}

// MARK: - Variante horizontale avec tous les états

/// Vue horizontale affichant les 4 états avec sélection
struct EnhancedStateSelector: View {
    @Binding var selectedState: Int
    var isEnabled: Bool = true
    var showLabels: Bool = true
    var compact: Bool = false
    
    var body: some View {
        HStack(spacing: compact ? 8 : 12) {
            ForEach(0..<4, id: \.self) { stateIndex in
                StateButton(
                    state: stateIndex,
                    isSelected: selectedState == stateIndex,
                    isEnabled: isEnabled,
                    compact: compact,
                    showLabel: showLabels
                ) {
                    if isEnabled {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedState = stateIndex
                        }
                        HapticManager.selection()
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sélecteur d'état de validation")
    }
}

/// Bouton individuel pour un état
private struct StateButton: View {
    let state: Int
    let isSelected: Bool
    let isEnabled: Bool
    let compact: Bool
    let showLabel: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Fond
                    RoundedRectangle(cornerRadius: compact ? 8 : 12)
                        .fill(isSelected ? stateColor : Color.gray.opacity(0.15))
                        .frame(
                            width: compact ? 40 : 56,
                            height: compact ? 40 : 56
                        )
                        .shadow(
                            color: isSelected ? stateColor.opacity(0.4) : .clear,
                            radius: 6,
                            x: 0,
                            y: 3
                        )
                    
                    // Icône
                    Image(systemName: stateIcon)
                        .font(.system(size: compact ? 16 : 20, weight: .bold))
                        .foregroundStyle(isSelected ? .white : stateColor)
                }
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
                
                if showLabel && !compact {
                    Text(stateLabel)
                        .font(.caption2)
                        .fontWeight(isSelected ? .bold : .medium)
                        .foregroundStyle(isSelected ? stateColor : .secondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(stateLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    private var stateColor: Color {
        switch state {
        case 0: return SNCFColors.corail
        case 1: return SNCFColors.safran
        case 2: return SNCFColors.menthe
        case 3: return SNCFColors.bleuHorizon
        default: return Color.gray
        }
    }
    
    private var stateIcon: String {
        switch state {
        case 0: return "xmark"
        case 1: return "minus"
        case 2: return "checkmark"
        case 3: return "questionmark"
        default: return "circle"
        }
    }
    
    private var stateLabel: String {
        switch state {
        case 0: return "Non validé"
        case 1: return "Partiel"
        case 2: return "Validé"
        case 3: return "Non traité"
        default: return "Inconnu"
        }
    }
}

// MARK: - Preview

#Preview("Indicateurs d'état") {
    VStack(spacing: 40) {
        HStack(spacing: 20) {
            ForEach(0..<4, id: \.self) { state in
                EnhancedStateIndicator(
                    state: .constant(state),
                    size: 50,
                    showLabel: true,
                    isReadOnly: true
                )
            }
        }
        
        Divider()
        
        EnhancedStateSelector(selectedState: .constant(2))
        
        Divider()
        
        EnhancedStateSelector(selectedState: .constant(1), compact: true)
    }
    .padding()
}


















