//
//  ModernButton.swift
//  RailSkills
//
//  Bouton moderne avec animations fluides, haptic feedback et styles variés
//

import SwiftUI

/// Style de bouton moderne
enum ModernButtonStyle {
    case primary    // Style principal (bleu SNCF)
    case secondary  // Style secondaire (vert SNCF)
    case outline    // Style avec bordure
    case destructive // Style destructif (rouge)
    case ghost      // Style minimal
}

/// Bouton moderne avec haptic feedback et animations
struct ModernButton: View {
    let title: String
    let icon: String?
    var style: ModernButtonStyle = .primary
    var size: ButtonSize = .medium
    var hapticFeedback: Bool = true
    var isLoading: Bool = false
    
    let action: () -> Void
    
    @State private var isPressed = false
    
    enum ButtonSize {
        case small, medium, large
        
        var height: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 52
            }
        }
        
        var fontSize: Font {
            switch self {
            case .small: return .subheadline
            case .medium: return .body
            case .large: return .title3
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 18
            case .large: return 20
            }
        }
    }
    
    var body: some View {
        Button(action: {
            if hapticFeedback {
                triggerHapticFeedback()
            }
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .semibold))
                }
                
                if !isLoading {
                    Text(title)
                        .font(size.fontSize.weight(.semibold))
                }
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(backgroundGradient)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .shadow(
                color: shadowColor,
                radius: isPressed ? 4 : 8,
                x: 0,
                y: isPressed ? 2 : 4
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
    }
    
    // MARK: - Computed Properties
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .secondary, .destructive:
            return .white
        case .outline, .ghost:
            return styleColor
        }
    }
    
    private var styleColor: Color {
        switch style {
        case .primary:
            return SNCFColors.ceruleen
        case .secondary:
            return SNCFColors.menthe
        case .outline:
            return SNCFColors.ceruleen
        case .destructive:
            return SNCFColors.corail
        case .ghost:
            return .primary
        }
    }
    
    private var backgroundGradient: LinearGradient {
        switch style {
        case .primary:
            return LinearGradient(
                colors: [SNCFColors.ceruleen, SNCFColors.ceruleen.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            return LinearGradient(
                colors: [SNCFColors.menthe, SNCFColors.menthe.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .destructive:
            return LinearGradient(
                colors: [SNCFColors.corail, SNCFColors.corail.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .outline, .ghost:
            return LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom)
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .outline:
            return styleColor
        case .ghost:
            return Color.clear
        default:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .outline:
            return 2
        default:
            return 0
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary:
            return SNCFColors.ceruleen.opacity(0.3)
        case .secondary:
            return SNCFColors.menthe.opacity(0.3)
        case .destructive:
            return SNCFColors.corail.opacity(0.3)
        default:
            return .black.opacity(0.1)
        }
    }
    
    private var cornerRadius: CGFloat {
        switch size {
        case .small: return 10
        case .medium: return 12
        case .large: return 14
        }
    }
    
    // MARK: - Haptic Feedback
    
    private func triggerHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Press Events Modifier

extension View {
    func pressEvents(
        onPress: @escaping () -> Void,
        onRelease: @escaping () -> Void
    ) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    onPress()
                }
                .onEnded { _ in
                    onRelease()
                }
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ModernButton(title: "Bouton Principal", icon: "checkmark.circle.fill", style: .primary) {
            Logger.info("Action", category: "ModernButton")
        }
        
        ModernButton(title: "Bouton Secondaire", icon: "arrow.right", style: .secondary) {
            Logger.info("Action", category: "ModernButton")
        }
        
        ModernButton(title: "Bouton Outline", icon: nil, style: .outline) {
            Logger.info("Action", category: "ModernButton")
        }
        
        ModernButton(title: "Supprimer", icon: "trash", style: .destructive) {
            Logger.info("Action", category: "ModernButton")
        }
        
        ModernButton(title: "Chargement...", icon: nil, style: .primary, isLoading: true) {
            Logger.info("Action", category: "ModernButton")
        }
    }
    .padding()
}









