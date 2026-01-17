//
//  EnhancedOnboardingView.swift
//  RailSkills
//
//  Vue d'onboarding améliorée avec animations et étapes interactives
//  Amélioration UX pour une meilleure première expérience utilisateur
//

import SwiftUI

/// Vue d'onboarding améliorée avec animations et tutoriel interactif
struct EnhancedOnboardingView: View {
    // MARK: - Propriétés
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Binding var isPresented: Bool
    
    // MARK: - État
    
    @State private var currentPage = 0
    @State private var animateContent = false
    
    // MARK: - Configuration
    
    /// Étapes de l'onboarding
    private let steps: [OnboardingStep] = [
        OnboardingStep(
            icon: "train.side.front.car",
            title: "Bienvenue sur RailSkills",
            description: "L'application de suivi des compétences pour les conducteurs ferroviaires.",
            accentColor: SNCFColors.ceruleen,
            features: [
                OnboardingFeature(icon: "checkmark.circle", text: "Suivi triennal complet"),
                OnboardingFeature(icon: "person.2", text: "Gestion multi-conducteurs"),
                OnboardingFeature(icon: "doc.text", text: "Export PDF professionnel")
            ]
        ),
        OnboardingStep(
            icon: "person.badge.plus",
            title: "Gérez vos conducteurs",
            description: "Ajoutez et organisez les conducteurs avec toutes leurs informations.",
            accentColor: SNCFColors.menthe,
            features: [
                OnboardingFeature(icon: "person.crop.circle", text: "Profil détaillé"),
                OnboardingFeature(icon: "calendar", text: "Suivi des échéances"),
                OnboardingFeature(icon: "chart.line.uptrend.xyaxis", text: "Progression en temps réel")
            ]
        ),
        OnboardingStep(
            icon: "list.bullet.clipboard",
            title: "Checklist de compétences",
            description: "Évaluez chaque compétence avec 4 niveaux de validation.",
            accentColor: SNCFColors.safran,
            features: [
                OnboardingFeature(icon: "xmark.circle", text: "Non validé"),
                OnboardingFeature(icon: "minus.circle", text: "Partiellement validé"),
                OnboardingFeature(icon: "checkmark.circle", text: "Validé"),
                OnboardingFeature(icon: "questionmark.circle", text: "Non traité")
            ]
        ),
        OnboardingStep(
            icon: "hand.draw",
            title: "Gestes intuitifs",
            description: "Balayez horizontalement sur une question pour changer rapidement son état.",
            accentColor: SNCFColors.lavande,
            features: [
                OnboardingFeature(icon: "arrow.left.arrow.right", text: "Swipe pour changer d'état"),
                OnboardingFeature(icon: "hand.tap", text: "Tap pour les détails"),
                OnboardingFeature(icon: "note.text", text: "Ajoutez des notes")
            ]
        ),
        OnboardingStep(
            icon: "chart.bar.doc.horizontal",
            title: "Rapports et exports",
            description: "Générez des rapports PDF professionnels et partagez les données.",
            accentColor: SNCFColors.corail,
            features: [
                OnboardingFeature(icon: "doc.richtext", text: "Rapports PDF détaillés"),
                OnboardingFeature(icon: "square.and.arrow.up", text: "Partage facile"),
                OnboardingFeature(icon: "arrow.triangle.2.circlepath", text: "Synchronisation")
            ]
        )
    ]
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Fond avec dégradé
            backgroundGradient
            
            // Contenu principal
            VStack(spacing: 0) {
                // Bouton passer (skip)
                skipButton
                
                // Pages de l'onboarding
                TabView(selection: $currentPage) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        OnboardingPageView(step: step, isActive: currentPage == index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)
                
                // Navigation
                navigationControls
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateContent = true
            }
        }
    }
    
    // MARK: - Sous-vues
    
    /// Fond avec dégradé animé
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                steps[currentPage].accentColor.opacity(0.15),
                Color(UIColor.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.5), value: currentPage)
    }
    
    /// Bouton pour passer l'onboarding
    private var skipButton: some View {
        HStack {
            Spacer()
            
            Button {
                completeOnboarding()
            } label: {
                Text("Passer")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .opacity(currentPage < steps.count - 1 ? 1 : 0)
    }
    
    /// Contrôles de navigation (indicateurs + boutons)
    private var navigationControls: some View {
        VStack(spacing: 24) {
            // Indicateurs de page
            HStack(spacing: 10) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? steps[currentPage].accentColor : Color.gray.opacity(0.3))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                }
            }
            
            // Boutons de navigation
            HStack(spacing: 16) {
                // Bouton précédent
                if currentPage > 0 {
                    Button {
                        withAnimation {
                            currentPage -= 1
                        }
                        HapticManager.impact(style: .light)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Précédent")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(steps[currentPage].accentColor)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                }
                
                Spacer()
                
                // Bouton suivant / commencer
                Button {
                    if currentPage < steps.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                    HapticManager.impact(style: .medium)
                } label: {
                    HStack(spacing: 8) {
                        Text(currentPage < steps.count - 1 ? "Suivant" : "Commencer")
                            .fontWeight(.bold)
                        
                        Image(systemName: currentPage < steps.count - 1 ? "chevron.right" : "checkmark")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        steps[currentPage].accentColor,
                                        steps[currentPage].accentColor.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: steps[currentPage].accentColor.opacity(0.4), radius: 10, x: 0, y: 5)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Actions
    
    /// Termine l'onboarding
    private func completeOnboarding() {
        HapticManager.notification(type: .success)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedOnboarding = true
            isPresented = false
        }
    }
}

// MARK: - Page d'onboarding individuelle

/// Vue pour une page d'onboarding
struct OnboardingPageView: View {
    let step: OnboardingStep
    let isActive: Bool
    
    @State private var animateIcon = false
    @State private var animateFeatures = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icône principale animée
            iconView
            
            // Textes
            VStack(spacing: 16) {
                Text(step.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                
                Text(step.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
            }
            
            // Liste des fonctionnalités
            featuresView
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                triggerAnimations()
            }
        }
        .onAppear {
            if isActive {
                triggerAnimations()
            }
        }
    }
    
    /// Vue de l'icône principale
    private var iconView: some View {
        ZStack {
            // Cercles de fond
            Circle()
                .fill(step.accentColor.opacity(0.1))
                .frame(width: 180, height: 180)
                .scaleEffect(animateIcon ? 1.1 : 1.0)
                .animation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                    value: animateIcon
                )
            
            Circle()
                .fill(step.accentColor.opacity(0.2))
                .frame(width: 140, height: 140)
            
            // Icône
            Image(systemName: step.icon)
                .font(.system(size: 56, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [step.accentColor, step.accentColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.bounce, value: isActive)
        }
    }
    
    /// Liste des fonctionnalités
    private var featuresView: some View {
        VStack(spacing: 12) {
            ForEach(Array(step.features.enumerated()), id: \.offset) { index, feature in
                HStack(spacing: 12) {
                    Image(systemName: feature.icon)
                        .font(.body)
                        .foregroundStyle(step.accentColor)
                        .frame(width: 24)
                    
                    Text(feature.text)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .opacity(animateFeatures ? 1 : 0)
                .offset(x: animateFeatures ? 0 : -20)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.7)
                    .delay(Double(index) * 0.1),
                    value: animateFeatures
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    /// Déclenche les animations
    private func triggerAnimations() {
        animateIcon = false
        animateFeatures = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                animateIcon = true
            }
            
            withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                animateFeatures = true
            }
        }
    }
}

// MARK: - Modèles

/// Étape d'onboarding
struct OnboardingStep {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    let features: [OnboardingFeature]
}

/// Fonctionnalité dans une étape
struct OnboardingFeature {
    let icon: String
    let text: String
}

// MARK: - Modificateur pour afficher l'onboarding

extension View {
    /// Affiche l'onboarding au premier lancement
    func showOnboardingIfNeeded() -> some View {
        modifier(OnboardingModifier())
    }
}

/// Modificateur pour gérer l'affichage de l'onboarding
struct OnboardingModifier: ViewModifier {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasCompletedOnboarding {
                    showOnboarding = true
                }
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                EnhancedOnboardingView(isPresented: $showOnboarding)
            }
    }
}

// MARK: - Preview

#Preview {
    EnhancedOnboardingView(isPresented: .constant(true))
}


















