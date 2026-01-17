//
//  ModernButton.swift
//  RailSkills
//
//  Bouton moderne avec différents styles et états (chargement, désactivé)
//

import SwiftUI

enum ModernButtonStyle {
    case primary
    case secondary
    case destructive
    case ghost
    
    var backgroundColor: Color {
        switch self {
        case .primary: return SNCFColors.ceruleen
        case .secondary: return SNCFColors.ceruleen.opacity(0.1)
        case .destructive: return SNCFColors.corail
        case .ghost: return .clear
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary, .destructive: return .white
        case .secondary: return SNCFColors.ceruleen
        case .ghost: return SNCFColors.ceruleen
        }
    }
}

struct ModernButton: View {
    let title: String
    var icon: String? = nil
    var style: ModernButtonStyle = .primary
    var isLoading: Bool = false
    var action: () -> Void
    
    // Pour gérer l'état désactivé via le modifieur standard .disabled()
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style == .primary ? .white : SNCFColors.ceruleen))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.headline)
                    }
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isEnabled ? style.backgroundColor : Color.gray.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .foregroundColor(isEnabled ? style.foregroundColor : .gray)
            .shadow(
                color: (isEnabled && style == .primary) ? style.backgroundColor.opacity(0.3) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(isLoading ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLoading)
        }
        .buttonStyle(PlainButtonStyle()) // Pour éviter l'effet par défaut de SwiftUI qui pourrait interférer
    }
}

#Preview {
    VStack(spacing: 20) {
        ModernButton(title: "Connexion", icon: "arrow.right", style: .primary) {}
        ModernButton(title: "Chargement", style: .primary, isLoading: true) {}
        ModernButton(title: "Secondaire", icon: "gear", style: .secondary) {}
        ModernButton(title: "Supprimer", icon: "trash", style: .destructive) {}
        ModernButton(title: "Désactivé", style: .primary) {}
            .disabled(true)
    }
    .padding()
}
