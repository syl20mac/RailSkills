//
//  ModernProgressBar.swift
//  RailSkills
//
//  Barre de progression moderne avec animations et dégradé
//

import SwiftUI

/// Barre de progression moderne avec effet de dégradé et animation fluide
struct ModernProgressBar: View {
    let progress: Double // 0.0 à 1.0
    let height: CGFloat
    let showPercentage: Bool
    var accentColor: Color
    
    @State private var animatedProgress: Double = 0
    
    init(
        progress: Double,
        height: CGFloat = 12,
        showPercentage: Bool = true,
        accentColor: Color = SNCFColors.ceruleen
    ) {
        self.progress = min(max(progress, 0), 1)
        self.height = height
        self.showPercentage = showPercentage
        self.accentColor = accentColor
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Barre de progression
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                    
                    // Progress fill avec dégradé
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    accentColor,
                                    accentColor.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedProgress)
                        .overlay(
                            // Shine effect
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: geometry.size.width * animatedProgress)
                        )
                    
                    // Indicateur de progression qui pulse
                    if animatedProgress > 0 && animatedProgress < 1 {
                        Circle()
                            .fill(Color.white)
                            .frame(width: height - 4, height: height - 4)
                            .shadow(color: accentColor.opacity(0.5), radius: 4)
                            .offset(x: geometry.size.width * animatedProgress - height/2)
                    }
                }
            }
            .frame(height: height)
            
            // Pourcentage
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.system(.subheadline, design: .rounded).monospacedDigit().weight(.semibold))
                    .foregroundColor(accentColor)
                    .frame(width: 45, alignment: .trailing)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        ModernProgressBar(progress: 0.3)
        ModernProgressBar(progress: 0.65, accentColor: SNCFColors.menthe)
        ModernProgressBar(progress: 1.0, accentColor: SNCFColors.success)
    }
    .padding()
}


