//
//  SkeletonLoadingView.swift
//  RailSkills
//
//  Composants de chargement skeleton pour une meilleure perception de performance
//  Amélioration UX pour remplacer les indicateurs de chargement basiques
//

import SwiftUI

/// Vue de chargement skeleton pour une ligne de checklist
struct SkeletonRow: View {
    // MARK: - État
    
    @State private var isAnimating = false
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Placeholder pour l'indicateur d'état
            SkeletonShape(shape: .circle)
                .frame(width: 44, height: 44)
            
            // Contenu textuel
            VStack(alignment: .leading, spacing: 8) {
                // Titre
                SkeletonShape(shape: .rectangle(cornerRadius: 4))
                    .frame(height: 16)
                    .frame(maxWidth: .infinity)
                
                // Sous-titre
                SkeletonShape(shape: .rectangle(cornerRadius: 4))
                    .frame(height: 12)
                    .frame(width: 150)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// Vue de chargement skeleton pour une carte conducteur
struct SkeletonDriverCard: View {
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            SkeletonShape(shape: .circle)
                .frame(width: 56, height: 56)
            
            // Informations
            VStack(alignment: .leading, spacing: 8) {
                SkeletonShape(shape: .rectangle(cornerRadius: 4))
                    .frame(height: 18)
                    .frame(width: 140)
                
                SkeletonShape(shape: .rectangle(cornerRadius: 4))
                    .frame(height: 14)
                    .frame(width: 100)
            }
            
            Spacer()
            
            // Badge de progression
            SkeletonShape(shape: .capsule)
                .frame(width: 60, height: 28)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

/// Vue de chargement skeleton pour une section de catégorie
struct SkeletonCategorySection: View {
    var itemCount: Int = 3
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // En-tête de catégorie
            HStack(spacing: 12) {
                SkeletonShape(shape: .circle)
                    .frame(width: 32, height: 32)
                
                SkeletonShape(shape: .rectangle(cornerRadius: 4))
                    .frame(height: 20)
                    .frame(width: 180)
                
                Spacer()
                
                SkeletonShape(shape: .capsule)
                    .frame(width: 50, height: 24)
            }
            
            // Barre de progression
            SkeletonShape(shape: .rectangle(cornerRadius: 2))
                .frame(height: 4)
            
            // Questions
            ForEach(0..<itemCount, id: \.self) { _ in
                SkeletonRow()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }
}

/// Vue de chargement skeleton pour le dashboard
struct SkeletonDashboard: View {
    var body: some View {
        VStack(spacing: 20) {
            // Carte de progression principale
            HStack(spacing: 20) {
                SkeletonShape(shape: .circle)
                    .frame(width: 80, height: 80)
                
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonShape(shape: .rectangle(cornerRadius: 4))
                        .frame(height: 20)
                        .frame(maxWidth: .infinity)
                    
                    SkeletonShape(shape: .rectangle(cornerRadius: 4))
                        .frame(height: 8)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            
            // Statistiques
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: 8) {
                        SkeletonShape(shape: .rectangle(cornerRadius: 4))
                            .frame(height: 32)
                        
                        SkeletonShape(shape: .rectangle(cornerRadius: 4))
                            .frame(height: 12)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                }
            }
            
            // Liste
            ForEach(0..<2, id: \.self) { _ in
                SkeletonCategorySection(itemCount: 2)
            }
        }
        .padding()
    }
}

// MARK: - Forme skeleton réutilisable

/// Forme skeleton avec animation de shimmer
struct SkeletonShape: View {
    enum ShapeType {
        case rectangle(cornerRadius: CGFloat)
        case circle
        case capsule
    }
    
    let shape: ShapeType
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fond selon le type de forme
                switch shape {
                case .rectangle(let cornerRadius):
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.gray.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(shimmerGradient)
                                .offset(x: isAnimating ? geometry.size.width * 2 : -geometry.size.width * 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        
                case .circle:
                    Circle()
                        .fill(Color.gray.opacity(0.15))
                        .overlay(
                            Circle()
                                .fill(shimmerGradient)
                                .offset(x: isAnimating ? geometry.size.width * 2 : -geometry.size.width * 2)
                        )
                        .clipShape(Circle())
                        
                case .capsule:
                    Capsule()
                        .fill(Color.gray.opacity(0.15))
                        .overlay(
                            Capsule()
                                .fill(shimmerGradient)
                                .offset(x: isAnimating ? geometry.size.width * 2 : -geometry.size.width * 2)
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .onAppear {
            withAnimation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
    
    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.clear,
                Color.white.opacity(0.4),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Modificateur de vue pour skeleton loading

extension View {
    /// Affiche un skeleton à la place du contenu pendant le chargement
    @ViewBuilder
    func skeleton(isLoading: Bool) -> some View {
        if isLoading {
            self.redacted(reason: .placeholder)
                .shimmering()
        } else {
            self
        }
    }
    
    /// Ajoute un effet de shimmer à la vue
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

/// Modificateur pour l'effet de shimmer
struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Preview

#Preview("Skeleton Loading") {
    ScrollView {
        VStack(spacing: 20) {
            SkeletonDriverCard()
            
            Divider()
            
            SkeletonCategorySection()
            
            Divider()
            
            SkeletonRow()
            SkeletonRow()
            SkeletonRow()
        }
        .padding()
    }
}

