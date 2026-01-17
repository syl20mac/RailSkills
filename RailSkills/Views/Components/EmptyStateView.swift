//
//  EmptyStateView.swift
//  RailSkills
//
//  Vue réutilisable pour les états vides avec animations engageantes
//  Amélioration UX pour une meilleure première impression
//

import SwiftUI

/// Vue engageante pour les états vides avec animation et action optionnelle
struct EmptyStateView: View {
    // MARK: - Propriétés
    
    /// Nom de l'icône SF Symbol
    let icon: String
    
    /// Titre principal
    let title: String
    
    /// Message descriptif
    let message: String
    
    /// Titre du bouton d'action (optionnel)
    var actionTitle: String? = nil
    
    /// Action du bouton (optionnel)
    var action: (() -> Void)? = nil
    
    /// Titre du bouton secondaire (optionnel)
    var secondaryActionTitle: String? = nil
    
    /// Action secondaire (optionnel)
    var secondaryAction: (() -> Void)? = nil
    
    /// Style visuel de l'état vide
    var style: EmptyStateStyle = .default
    
    // MARK: - État
    
    @State private var isAnimating = false
    @State private var iconScale: CGFloat = 0.5
    @State private var contentOpacity: Double = 0
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 28) {
            // Icône animée avec dégradé
            iconView
            
            // Textes
            textContent
            
            // Boutons d'action
            actionButtons
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Sous-vues
    
    /// Icône principale avec animation
    private var iconView: some View {
        ZStack {
            // Cercle de fond avec pulse
            Circle()
                .fill(style.backgroundColor.opacity(0.15))
                .frame(width: 140, height: 140)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            // Cercle intermédiaire
            Circle()
                .fill(style.backgroundColor.opacity(0.25))
                .frame(width: 110, height: 110)
            
            // Icône principale
            Image(systemName: icon)
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: style.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse.byLayer, options: .repeating, value: isAnimating)
        }
        .scaleEffect(iconScale)
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: iconScale)
    }
    
    /// Contenu textuel
    private var textContent: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .opacity(contentOpacity)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: contentOpacity)
    }
    
    /// Boutons d'action
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Bouton principal
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticManager.impact(style: .medium)
                    action()
                }) {
                    HStack(spacing: 8) {
                        if let actionIcon = style.actionIcon {
                            Image(systemName: actionIcon)
                        }
                        Text(actionTitle)
                            .fontWeight(.semibold)
                    }
                    .frame(minWidth: 200)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(style.accentColor)
                .shadow(color: style.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            // Bouton secondaire
            if let secondaryTitle = secondaryActionTitle, let secondaryAction = secondaryAction {
                Button(action: {
                    HapticManager.impact(style: .light)
                    secondaryAction()
                }) {
                    Text(secondaryTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .buttonStyle(.plain)
                .foregroundStyle(style.accentColor)
            }
        }
        .opacity(contentOpacity)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: contentOpacity)
    }
    
    // MARK: - Animations
    
    /// Démarre les animations d'entrée
    private func startAnimations() {
        // Animation de l'icône
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            iconScale = 1.0
        }
        
        // Animation du contenu
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            contentOpacity = 1.0
        }
        
        // Démarrer le pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAnimating = true
        }
    }
}

// MARK: - Styles prédéfinis

/// Styles visuels pour les états vides
enum EmptyStateStyle {
    case `default`
    case drivers
    case checklist
    case search
    case error
    case success
    case filter
    
    /// Couleurs du dégradé pour l'icône
    var gradientColors: [Color] {
        switch self {
        case .default:
            return [SNCFColors.ceruleen, SNCFColors.bleuHorizon]
        case .drivers:
            return [SNCFColors.ceruleen, SNCFColors.lavande]
        case .checklist:
            return [SNCFColors.menthe, SNCFColors.vertEau]
        case .search:
            return [SNCFColors.safran, SNCFColors.ambre]
        case .error:
            return [SNCFColors.corail, SNCFColors.ocre]
        case .success:
            return [SNCFColors.menthe, SNCFColors.vertEau]
        case .filter:
            return [SNCFColors.lavande, SNCFColors.parme]
        }
    }
    
    /// Couleur de fond
    var backgroundColor: Color {
        gradientColors.first ?? SNCFColors.ceruleen
    }
    
    /// Couleur d'accent pour les boutons
    var accentColor: Color {
        switch self {
        case .default, .drivers:
            return SNCFColors.ceruleen
        case .checklist, .success:
            return SNCFColors.menthe
        case .search:
            return SNCFColors.safran
        case .error:
            return SNCFColors.corail
        case .filter:
            return SNCFColors.lavande
        }
    }
    
    /// Icône optionnelle pour le bouton d'action
    var actionIcon: String? {
        switch self {
        case .drivers:
            return "person.badge.plus"
        case .checklist:
            return "doc.badge.plus"
        case .search:
            return "magnifyingglass"
        case .error:
            return "arrow.clockwise"
        case .filter:
            return "line.3.horizontal.decrease.circle"
        default:
            return nil
        }
    }
}

// MARK: - Variantes prédéfinies pour RailSkills

extension EmptyStateView {
    /// État vide pour aucun conducteur
    static func noDrivers(onAddDriver: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "person.2.slash",
            title: "Aucun conducteur",
            message: "Ajoutez votre premier conducteur pour commencer le suivi des compétences.",
            actionTitle: "Ajouter un conducteur",
            action: onAddDriver,
            style: .drivers
        )
    }
    
    /// État vide pour aucune checklist
    static func noChecklist(onImport: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "list.bullet.clipboard",
            title: "Aucune checklist",
            message: "Importez une checklist pour commencer l'évaluation des conducteurs.",
            actionTitle: "Importer une checklist",
            action: onImport,
            style: .checklist
        )
    }
    
    /// État vide pour recherche sans résultat
    static func noSearchResults(searchText: String, onClear: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "Aucun résultat",
            message: "Aucun élément ne correspond à \"\(searchText)\".",
            actionTitle: "Effacer la recherche",
            action: onClear,
            style: .search
        )
    }
    
    /// État vide pour filtre sans résultat
    static func noFilterResults(filterName: String, onResetFilter: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "line.3.horizontal.decrease.circle",
            title: "Aucun résultat pour ce filtre",
            message: "Le filtre \"\(filterName)\" ne retourne aucun résultat.",
            actionTitle: "Réinitialiser le filtre",
            action: onResetFilter,
            style: .filter
        )
    }
    
    /// État vide pour erreur de chargement
    static func loadingError(onRetry: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "exclamationmark.triangle",
            title: "Erreur de chargement",
            message: "Une erreur s'est produite lors du chargement des données.",
            actionTitle: "Réessayer",
            action: onRetry,
            style: .error
        )
    }
    
    /// État de succès (par exemple après export)
    static func success(title: String, message: String, onDone: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "checkmark.circle",
            title: title,
            message: message,
            actionTitle: "Terminé",
            action: onDone,
            style: .success
        )
    }
}

// MARK: - Preview

#Preview("États vides") {
    ScrollView {
        VStack(spacing: 40) {
            EmptyStateView.noDrivers(onAddDriver: {})
                .frame(height: 400)
            
            Divider()
            
            EmptyStateView.noSearchResults(searchText: "test", onClear: {})
                .frame(height: 400)
        }
    }
}


















