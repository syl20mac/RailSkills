//
//  AnimationPresets.swift
//  RailSkills
//
//  Préréglages d'animations et gestion du retour haptique
//

import SwiftUI
import UIKit

/// Préréglages d'animations réutilisables dans l'application
enum AnimationPresets {
    // MARK: - Animations standards
    
    /// Animation spring standard
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.75)
    
    /// Animation spring rebondissante
    static let springBouncy = Animation.spring(response: 0.3, dampingFraction: 0.6)
    
    /// Animation douce
    static let smooth = Animation.easeInOut(duration: 0.3)
    
    /// Animation rapide
    static let quick = Animation.easeInOut(duration: 0.15)
    
    // MARK: - Animations spécifiques
    
    /// Animation d'apparition de carte
    static let cardAppear = Animation.spring(response: 0.5, dampingFraction: 0.8).delay(0.05)
    
    /// Animation de mise à jour de progression
    static let progressUpdate = Animation.spring(response: 0.6, dampingFraction: 0.75)
    
    /// Animation de changement d'état
    static let stateChange = Animation.spring(response: 0.3, dampingFraction: 0.7)
}

/// Gestionnaire de retour haptique
enum HapticManager {
    /// Génère un retour haptique d'impact
    /// - Parameter style: Style de l'impact (light, medium, heavy, soft, rigid)
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    /// Génère un retour haptique de notification
    /// - Parameter type: Type de notification (success, warning, error)
    static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    /// Génère un retour haptique de sélection
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}


