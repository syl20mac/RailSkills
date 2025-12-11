//
//  StatusBadge.swift
//  RailSkills
//
//  Badge de statut animé avec couleurs et icônes
//

import SwiftUI

/// Badge de statut avec animation et design moderne
struct StatusBadge: View {
    let status: ChecklistItemState
    let size: BadgeSize
    
    @State private var isAnimating = false
    
    /// Tailles disponibles pour le badge
    enum BadgeSize {
        case small, medium, large
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 18
            case .large: return 24
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 12
            }
        }
        
        var font: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            // Icône selon le statut
            Image(systemName: status.iconName)
                .font(.system(size: size.iconSize, weight: .semibold))
                .foregroundColor(.white)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
            
            if size != .small {
                Text(status.label)
                    .font(size.font.weight(.semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, size == .small ? 8 : 12)
        .padding(.vertical, size.padding)
        .background(
            ZStack {
                // Fond principal
                Capsule()
                    .fill(statusColor)
                
                // Overlay brillant
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .shadow(color: statusColor.opacity(0.3), radius: 4, x: 0, y: 2)
        .onAppear {
            if status == .validated {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6).repeatCount(1)) {
                    isAnimating = true
                }
            }
        }
    }
    
    // Couleur selon l'état
    private var statusColor: Color {
        switch status {
        case .notValidated: return SNCFColors.corail
        case .partial: return SNCFColors.safran
        case .validated: return SNCFColors.menthe
        case .notProcessed: return SNCFColors.bleuHorizon
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        StatusBadge(status: .notValidated, size: .small)
        StatusBadge(status: .partial, size: .medium)
        StatusBadge(status: .validated, size: .large)
        StatusBadge(status: .notProcessed, size: .medium)
    }
    .padding()
}


