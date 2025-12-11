//
//  HapticFeedbackManager.swift
//  RailSkills
//
//  Gestionnaire centralisé pour les retours haptiques dans l'application
//

import UIKit
import SwiftUI

/// Gestionnaire centralisé pour les retours haptiques
/// Fournit des feedbacks tactiles contextuels pour améliorer l'UX
final class HapticFeedbackManager {
    static let shared = HapticFeedbackManager()
    
    private init() {}
    
    // MARK: - Impact Feedback (Pour les actions physiques)
    
    /// Feedback léger (pour les interactions subtiles)
    func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Feedback moyen (pour les actions standards)
    func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Feedback fort (pour les actions importantes)
    func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Feedback rigide (pour les actions précises)
    func rigid() {
        if #available(iOS 13.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred()
        } else {
            medium()
        }
    }
    
    /// Feedback doux (pour les actions délicates)
    func soft() {
        if #available(iOS 13.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        } else {
            light()
        }
    }
    
    // MARK: - Notification Feedback (Pour les résultats d'actions)
    
    /// Feedback de succès
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Feedback d'avertissement
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Feedback d'erreur
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback (Pour les changements de sélection)
    
    /// Feedback de sélection (pour les changements de valeur)
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - Contextual Feedback (Méthodes pratiques pour l'app)
    
    /// Feedback pour une action réussie (ex: sauvegarde)
    func actionSuccess() {
        success()
    }
    
    /// Feedback pour une action qui a échoué
    func actionError() {
        error()
    }
    
    /// Feedback pour un changement d'état (ex: toggle)
    func stateChange() {
        selection()
    }
    
    /// Feedback pour un bouton pressé
    func buttonPress() {
        medium()
    }
    
    /// Feedback pour une action destructrice (ex: suppression)
    func destructiveAction() {
        heavy()
    }
    
    /// Feedback pour une interaction de liste (ex: swipe)
    func listInteraction() {
        light()
    }
    
    /// Feedback pour la synchronisation réussie
    func syncSuccess() {
        success()
    }
    
    /// Feedback pour une erreur de synchronisation
    func syncError() {
        error()
    }
    
    /// Feedback pour un changement de conducteur
    func driverChange() {
        selection()
    }
    
    /// Feedback pour une question complétée
    func questionCompleted() {
        medium()
    }
    
    /// Feedback pour une question validée
    func questionValidated() {
        success()
    }
}

// MARK: - Extension View pour utilisation facile

extension View {
    /// Ajoute un feedback haptique lors d'une action
    func hapticFeedback(
        style: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
        onTrigger: @escaping () -> Void
    ) -> some View {
        self.onTapGesture {
            HapticFeedbackManager.shared.medium()
            onTrigger()
        }
    }
}

