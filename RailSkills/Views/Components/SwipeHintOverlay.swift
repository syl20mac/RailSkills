//
//  SwipeHintOverlay.swift
//  RailSkills
//
//  Overlay de tutoriel pour les gestes de swipe
//  Amélioration UX pour la découvrabilité des interactions gestuelles
//

import SwiftUI

/// Overlay animé pour indiquer le geste de swipe aux nouveaux utilisateurs
struct SwipeHintOverlay: View {
    // MARK: - Propriétés
    
    /// Clé de stockage pour savoir si l'utilisateur a vu le hint
    @AppStorage("hasSeenSwipeHint") private var hasSeenSwipeHint = false
    
    /// Force l'affichage (pour les tutoriels)
    var forceShow: Bool = false
    
    /// Callback quand le hint est fermé
    var onDismiss: (() -> Void)? = nil
    
    // MARK: - État
    
    @State private var handOffset: CGFloat = 0
    @State private var isVisible = true
    @State private var contentOpacity: Double = 0
    
    // MARK: - Body
    
    var body: some View {
        if (forceShow || !hasSeenSwipeHint) && isVisible {
            VStack(spacing: 0) {
                Spacer()
                
                hintCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // Au-dessus de la TabBar
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                startAnimations()
            }
        }
    }
    
    // MARK: - Sous-vues
    
    /// Carte du hint
    private var hintCard: some View {
        VStack(spacing: 16) {
            // Animation de la main
            handAnimation
            
            // Texte explicatif
            VStack(spacing: 8) {
                Text("Balayez pour changer l'état")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text("Faites glisser horizontalement sur une question pour changer rapidement son état de validation.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            // Bouton de fermeture
            Button {
                dismissHint()
            } label: {
                Text("Compris !")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(SNCFColors.ceruleen)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(.white)
                    )
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [SNCFColors.ceruleen, SNCFColors.cobalt],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: SNCFColors.ceruleen.opacity(0.4), radius: 20, x: 0, y: 10)
        )
        .opacity(contentOpacity)
    }
    
    /// Animation de la main qui glisse
    private var handAnimation: some View {
        ZStack {
            // Fond représentant une ligne de question
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.15))
                .frame(height: 60)
                .overlay(
                    HStack {
                        Circle()
                            .fill(.white.opacity(0.3))
                            .frame(width: 40, height: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.white.opacity(0.4))
                                .frame(width: 120, height: 12)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.white.opacity(0.2))
                                .frame(width: 80, height: 8)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                )
            
            // Main animée
            HStack(spacing: 4) {
                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                
                // Flèches de direction
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .offset(x: handOffset)
        }
        .frame(height: 80)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Animations
    
    /// Démarre les animations
    private func startAnimations() {
        // Apparition de la carte
        withAnimation(.easeOut(duration: 0.4)) {
            contentOpacity = 1
        }
        
        // Animation de la main
        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
            .delay(0.3)
        ) {
            handOffset = 40
        }
    }
    
    /// Ferme le hint
    private func dismissHint() {
        HapticManager.impact(style: .light)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            contentOpacity = 0
            isVisible = false
        }
        
        // Sauvegarder que l'utilisateur a vu le hint
        if !forceShow {
            hasSeenSwipeHint = true
        }
        
        onDismiss?()
    }
}

// MARK: - Hint pour le premier lancement

/// Vue de tutoriel pour le premier lancement de l'app
struct FirstLaunchTutorialOverlay: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentStep = 0
    
    let steps: [TutorialStep] = [
        TutorialStep(
            icon: "person.2.fill",
            title: "Gérez vos conducteurs",
            description: "Ajoutez et suivez les conducteurs avec leurs informations et leur progression.",
            color: SNCFColors.ceruleen
        ),
        TutorialStep(
            icon: "list.bullet.clipboard",
            title: "Checklist de compétences",
            description: "Validez les compétences selon la checklist triennale avec 4 niveaux d'évaluation.",
            color: SNCFColors.menthe
        ),
        TutorialStep(
            icon: "hand.draw.fill",
            title: "Gestes intuitifs",
            description: "Balayez horizontalement pour changer rapidement l'état d'une question.",
            color: SNCFColors.safran
        ),
        TutorialStep(
            icon: "chart.bar.fill",
            title: "Suivi et rapports",
            description: "Consultez le dashboard et exportez des rapports PDF détaillés.",
            color: SNCFColors.lavande
        )
    ]
    
    var body: some View {
        if !hasCompletedOnboarding {
            ZStack {
                // Fond semi-transparent
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                // Contenu du tutoriel
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Icône animée
                    ZStack {
                        Circle()
                            .fill(steps[currentStep].color.opacity(0.2))
                            .frame(width: 140, height: 140)
                        
                        Circle()
                            .fill(steps[currentStep].color.opacity(0.4))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: steps[currentStep].icon)
                            .font(.system(size: 44))
                            .foregroundStyle(steps[currentStep].color)
                    }
                    .padding(.bottom, 20)
                    
                    // Texte
                    VStack(spacing: 12) {
                        Text(steps[currentStep].title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Text(steps[currentStep].description)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    // Indicateurs de page
                    HStack(spacing: 8) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentStep ? steps[currentStep].color : .white.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentStep ? 1.2 : 1)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
                        }
                    }
                    
                    // Boutons
                    HStack(spacing: 16) {
                        if currentStep > 0 {
                            Button {
                                withAnimation {
                                    currentStep -= 1
                                }
                            } label: {
                                Text("Précédent")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 14)
                            }
                        }
                        
                        Button {
                            if currentStep < steps.count - 1 {
                                withAnimation {
                                    currentStep += 1
                                }
                            } else {
                                withAnimation {
                                    hasCompletedOnboarding = true
                                }
                            }
                            HapticManager.impact(style: .medium)
                        } label: {
                            Text(currentStep < steps.count - 1 ? "Suivant" : "Commencer")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 16)
                                .background(
                                    Capsule()
                                        .fill(steps[currentStep].color)
                                )
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .transition(.opacity)
        }
    }
}

/// Étape de tutoriel
struct TutorialStep {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Preview

#Preview("Swipe Hint") {
    ZStack {
        Color(UIColor.systemGroupedBackground)
            .ignoresSafeArea()
        
        VStack {
            Text("Contenu de l'app")
            Spacer()
        }
        
        SwipeHintOverlay(forceShow: true)
    }
}

#Preview("First Launch Tutorial") {
    FirstLaunchTutorialOverlay()
}

