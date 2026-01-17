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
                    // Fond principal avec effet material
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.regularMaterial)
                    
                    // Bordure subtile en light mode
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                }
            )
            .shadow(
                color: .black.opacity(shadow ? 0.06 : 0),
                radius: elevated ? 16 : 8,
                x: 0,
                y: elevated ? 8 : 4
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



