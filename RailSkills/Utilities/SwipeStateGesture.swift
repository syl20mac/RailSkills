//
//  SwipeStateGesture.swift
//  RailSkills
//
//  Gestion du swipe horizontal pour changer rapidement d'état
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// ViewModifier qui ajoute un swipe horizontal pour changer d'état
struct SwipeStateModifier: ViewModifier {
    @Binding var state: Int
    let isEnabled: Bool
    let onStateChange: (Int) -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var feedbackOffset: CGFloat = 0
    
    private let swipeThreshold: CGFloat = 60
    private let states = [0, 1, 2, 3] // Non validé, Partiel, Validé, N/A
    
    func body(content: Content) -> some View {
        ZStack {
            // Arrière-plan indicateur de swipe
            if abs(dragOffset) > 10 {
                swipeBackgroundView
            }
            
            // Contenu principal
            content
                .offset(x: feedbackOffset)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            if isEnabled && abs(value.translation.width) > abs(value.translation.height) {
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if isEnabled {
                                handleSwipeEnd(value.translation.width)
                            }
                            dragOffset = 0
                        }
                )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: feedbackOffset)
    }
    
    /// Vue d'arrière-plan qui indique la direction du swipe
    private var swipeBackgroundView: some View {
        HStack(spacing: 0) {
            // Swipe gauche (état précédent)
            if dragOffset < -10, let prevState = getPreviousState() {
                stateIndicator(for: prevState, direction: .left)
                    .frame(width: abs(dragOffset))
            }
            
            Spacer()
            
            // Swipe droite (état suivant)
            if dragOffset > 10, let nextState = getNextState() {
                stateIndicator(for: nextState, direction: .right)
                    .frame(width: abs(dragOffset))
            }
        }
    }
    
    /// Indicateur visuel de l'état cible
    private func stateIndicator(for targetState: Int, direction: SwipeDirection) -> some View {
        HStack(spacing: 8) {
            if direction == .right {
                Image(systemName: "chevron.left")
                    .font(.caption)
            }
            
            Image(systemName: iconForState(targetState))
                .font(.body)
            
            Text(labelForState(targetState))
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            if direction == .left {
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity)
        .background(Color.forState(targetState))
    }
    
    /// Gère la fin du swipe
    private func handleSwipeEnd(_ translation: CGFloat) {
        guard abs(translation) > swipeThreshold else {
            // Swipe trop court, annuler
            withAnimation {
                feedbackOffset = 0
            }
            return
        }
        
        var newState: Int?
        
        if translation > 0, let next = getNextState() {
            // Swipe droite → état suivant
            newState = next
        } else if translation < 0, let prev = getPreviousState() {
            // Swipe gauche → état précédent
            newState = prev
        }
        
        if let newState = newState {
            // Feedback visuel
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                feedbackOffset = translation > 0 ? 20 : -20
            }
            
            // Changer l'état
            state = newState
            onStateChange(newState)
            
            // Feedback haptique
            provideHapticFeedback(for: newState)
            
            // Reset
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    feedbackOffset = 0
                }
            }
        } else {
            withAnimation {
                feedbackOffset = 0
            }
        }
    }
    
    /// Récupère l'état suivant
    private func getNextState() -> Int? {
        guard let currentIndex = states.firstIndex(of: state) else { return nil }
        let nextIndex = currentIndex + 1
        return nextIndex < states.count ? states[nextIndex] : nil
    }
    
    /// Récupère l'état précédent
    private func getPreviousState() -> Int? {
        guard let currentIndex = states.firstIndex(of: state) else { return nil }
        let prevIndex = currentIndex - 1
        return prevIndex >= 0 ? states[prevIndex] : nil
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
    
    /// Feedback haptique selon l'état
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
}

/// Direction du swipe
enum SwipeDirection {
    case left, right
}

/// Extension pour faciliter l'utilisation
extension View {
    /// Ajoute un swipe horizontal pour changer d'état
    func swipeToChangeState(state: Binding<Int>, isEnabled: Bool, onStateChange: @escaping (Int) -> Void) -> some View {
        self.modifier(SwipeStateModifier(state: state, isEnabled: isEnabled, onStateChange: onStateChange))
    }
}


