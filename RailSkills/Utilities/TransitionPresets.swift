//
//  TransitionPresets.swift
//  RailSkills
//
//  Préréglages de transitions personnalisées pour les animations de vue
//

import SwiftUI

/// Préréglages de transitions réutilisables
extension AnyTransition {
    /// Transition combinant slide et fade (asymétrique)
    static var slideAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    /// Transition combinant scale et fade
    static var scaleAndFade: AnyTransition {
        .scale(scale: 0.9).combined(with: .opacity)
    }
    
    /// Transition de slide depuis le bas avec fade
    static var slideUpAndFade: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }
    
    /// Transition de slide depuis le haut avec fade
    static var slideDownAndFade: AnyTransition {
        .move(edge: .top).combined(with: .opacity)
    }
    
    /// Transition en push (pour navigation)
    static var push: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        )
    }
    
    /// Transition de carte (scale avec pivot et fade)
    static var card: AnyTransition {
        .scale(scale: 0.95, anchor: .center)
            .combined(with: .opacity)
    }
    
    /// Transition de modal (slide up)
    static var modal: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
}

/// Extensions pour faciliter l'utilisation des transitions avec animations
extension View {
    /// Applique une transition slideAndFade avec animation spring
    func slideAndFadeTransition() -> some View {
        self.transition(.slideAndFade)
            .animation(AnimationPresets.smooth, value: UUID())
    }
    
    /// Applique une transition scaleAndFade avec animation spring
    func scaleAndFadeTransition() -> some View {
        self.transition(.scaleAndFade)
            .animation(AnimationPresets.springBouncy, value: UUID())
    }
    
    /// Applique une transition de carte avec animation douce
    func cardTransition() -> some View {
        self.transition(.card)
            .animation(AnimationPresets.cardAppear, value: UUID())
    }
}


