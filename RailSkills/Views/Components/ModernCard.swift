//
//  ModernCard.swift
//  RailSkills
//
//  Composant de carte moderne avec effet glassmorphism et ombres douces
//

import SwiftUI

/// Carte moderne avec design glassmorphism
struct ModernCard<Content: View>: View {
    let content: Content
    var padding: CGFloat
    var cornerRadius: CGFloat
    var shadow: Bool
    var elevated: Bool
    
    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 20,
        shadow: Bool = true,
        elevated: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.elevated = elevated
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Fond principal avec effet material iOS 18 (Liquid Glass)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(elevated ? .ultraThickMaterial : .regularMaterial)
                    
                    // Bordure subtile adaptative avec gradient iOS 18
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.primary.opacity(elevated ? 0.15 : 0.08),
                                    Color.primary.opacity(elevated ? 0.08 : 0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: elevated ? 1.5 : 1
                        )
                }
            )
            .shadow(
                color: .black.opacity(shadow ? (elevated ? 0.1 : 0.06) : 0),
                radius: elevated ? 20 : 8,
                x: 0,
                y: elevated ? 10 : 4
            )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        ModernCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Conducteur")
                    .font(.headline)
                Text("Jean Dupont")
                    .font(.title2.bold())
            }
        }
        
        ModernCard(elevated: true) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Évaluation")
                    .font(.headline)
                Text("Triennale CFL")
                    .font(.title2.bold())
            }
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}


