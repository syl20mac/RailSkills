//
//  EnhancedCircularProgressView.swift
//  RailSkills
//
//  Vue de progression circulaire améliorée avec animations et dégradés
//  Amélioration UX pour un meilleur feedback visuel de la progression
//

import SwiftUI

/// Vue de progression circulaire améliorée avec animations fluides et dégradés dynamiques
struct EnhancedCircularProgressView: View {
    // MARK: - Propriétés
    
    /// Progression actuelle (0.0 à 1.0)
    let progress: Double
    
    /// Taille du cercle
    let size: CGFloat
    
    /// Afficher le pourcentage au centre
    var showPercentage: Bool = true
    
    /// Épaisseur relative du trait (ratio par rapport à la taille)
    var strokeRatio: CGFloat = 0.12
    
    // MARK: - État
    
    /// Progression animée pour les transitions fluides
    @State private var animatedProgress: Double = 0
    
    /// Animation de célébration quand 100% atteint
    @State private var isCelebrating: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Cercle de fond avec dégradé subtil
            backgroundCircle
            
            // Arc de progression avec dégradé angulaire
            progressArc
            
            // Indicateur de fin de l'arc (petit cercle)
            if animatedProgress > 0.02 {
                progressEndCap
            }
            
            // Texte central avec animation compteur
            if showPercentage {
                centerText
            }
            
            // Effet de célébration à 100%
            if isCelebrating {
                celebrationEffect
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            startAnimation()
        }
        .onChange(of: progress) { oldValue, newValue in
            updateProgress(from: oldValue, to: newValue)
        }
    }
    
    // MARK: - Sous-vues
    
    /// Cercle de fond avec dégradé subtil
    private var backgroundCircle: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.08),
                        Color.gray.opacity(0.15)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: size * strokeRatio
            )
    }
    
    /// Arc de progression avec dégradé angulaire dynamique
    private var progressArc: some View {
        Circle()
            .trim(from: 0, to: animatedProgress)
            .stroke(
                AngularGradient(
                    colors: progressColors,
                    center: .center,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(270)
                ),
                style: StrokeStyle(
                    lineWidth: size * strokeRatio,
                    lineCap: .round
                )
            )
            .rotationEffect(.degrees(-90))
            .shadow(
                color: progressColors.first?.opacity(0.4) ?? .clear,
                radius: 4,
                x: 0,
                y: 2
            )
    }
    
    /// Petit cercle à la fin de l'arc pour un rendu plus propre
    private var progressEndCap: some View {
        Circle()
            .fill(progressColors.last ?? SNCFColors.ceruleen)
            .frame(width: size * strokeRatio, height: size * strokeRatio)
            .offset(y: -size / 2 + size * strokeRatio / 2)
            .rotationEffect(.degrees(animatedProgress * 360 - 90))
            .shadow(
                color: progressColors.last?.opacity(0.5) ?? .clear,
                radius: 3,
                x: 0,
                y: 1
            )
    }
    
    /// Texte central avec le pourcentage
    private var centerText: some View {
        VStack(spacing: -2) {
            Text("\(Int(animatedProgress * 100))")
                .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .foregroundStyle(textColor)
            
            Text("%")
                .font(.system(size: size * 0.12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
    
    /// Effet de célébration quand 100% atteint
    private var celebrationEffect: some View {
        ForEach(0..<8, id: \.self) { index in
            Circle()
                .fill(progressColors[index % progressColors.count])
                .frame(width: 6, height: 6)
                .offset(y: -size / 2 - 10)
                .rotationEffect(.degrees(Double(index) * 45))
                .scaleEffect(isCelebrating ? 1.5 : 0)
                .opacity(isCelebrating ? 0 : 1)
        }
    }
    
    // MARK: - Couleurs dynamiques
    
    /// Couleurs du dégradé basées sur la progression
    private var progressColors: [Color] {
        if animatedProgress >= 1.0 {
            // Vert éclatant pour 100%
            return [SNCFColors.menthe, SNCFColors.vertEau, SNCFColors.menthe]
        } else if animatedProgress >= 0.7 {
            // Bleu pour bonne progression
            return [SNCFColors.ceruleen, SNCFColors.bleuHorizon, SNCFColors.ceruleen]
        } else if animatedProgress >= 0.4 {
            // Orange/jaune pour progression moyenne
            return [SNCFColors.safran, SNCFColors.ambre, SNCFColors.safran]
        } else {
            // Rouge/corail pour faible progression
            return [SNCFColors.corail, SNCFColors.peche, SNCFColors.corail]
        }
    }
    
    /// Couleur du texte central
    private var textColor: Color {
        if animatedProgress >= 1.0 {
            return SNCFColors.menthe
        } else if animatedProgress >= 0.7 {
            return SNCFColors.ceruleen
        } else if animatedProgress >= 0.4 {
            return SNCFColors.safran
        } else {
            return SNCFColors.corail
        }
    }
    
    // MARK: - Animations
    
    /// Démarre l'animation initiale
    private func startAnimation() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            animatedProgress = progress
        }
        
        // Célébration si déjà à 100%
        if progress >= 1.0 {
            triggerCelebration()
        }
    }
    
    /// Met à jour la progression avec animation
    private func updateProgress(from oldValue: Double, to newValue: Double) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            animatedProgress = newValue
        }
        
        // Déclencher la célébration si on atteint 100%
        if oldValue < 1.0 && newValue >= 1.0 {
            triggerCelebration()
        }
    }
    
    /// Déclenche l'effet de célébration
    private func triggerCelebration() {
        // Retour haptique de succès
        HapticManager.notification(type: .success)
        
        withAnimation(.easeOut(duration: 0.6)) {
            isCelebrating = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isCelebrating = false
        }
    }
}

// MARK: - Variantes de taille prédéfinies

extension EnhancedCircularProgressView {
    /// Petite taille (32pt) - pour les listes compactes
    static func small(progress: Double) -> EnhancedCircularProgressView {
        EnhancedCircularProgressView(progress: progress, size: 32, showPercentage: false, strokeRatio: 0.15)
    }
    
    /// Taille moyenne (56pt) - pour les en-têtes
    static func medium(progress: Double) -> EnhancedCircularProgressView {
        EnhancedCircularProgressView(progress: progress, size: 56)
    }
    
    /// Grande taille (80pt) - pour les dashboards
    static func large(progress: Double) -> EnhancedCircularProgressView {
        EnhancedCircularProgressView(progress: progress, size: 80)
    }
    
    /// Très grande taille (120pt) - pour les écrans de détail
    static func extraLarge(progress: Double) -> EnhancedCircularProgressView {
        EnhancedCircularProgressView(progress: progress, size: 120, strokeRatio: 0.10)
    }
}

// MARK: - Preview

#Preview("Progression variée") {
    VStack(spacing: 30) {
        HStack(spacing: 20) {
            EnhancedCircularProgressView(progress: 0.15, size: 60)
            EnhancedCircularProgressView(progress: 0.45, size: 60)
            EnhancedCircularProgressView(progress: 0.75, size: 60)
            EnhancedCircularProgressView(progress: 1.0, size: 60)
        }
        
        EnhancedCircularProgressView.extraLarge(progress: 0.68)
    }
    .padding()
}


















