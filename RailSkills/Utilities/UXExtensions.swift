//
//  UXExtensions.swift
//  RailSkills
//
//  Extensions de vue pour améliorer l'UX de l'application
//  Contient les modificateurs de style, animations et effets réutilisables
//

import SwiftUI

// MARK: - Card Style Extension

extension View {
    /// Applique un style de carte avec fond, coins arrondis et ombre
    /// - Parameters:
    ///   - isElevated: Si true, ombre plus prononcée
    ///   - cornerRadius: Rayon des coins (défaut: 16)
    ///   - padding: Padding intérieur (défaut: 16)
    /// - Returns: La vue stylisée en carte
    func cardStyle(
        isElevated: Bool = false,
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 16
    ) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(
                        color: Color.black.opacity(isElevated ? 0.12 : 0.05),
                        radius: isElevated ? 12 : 4,
                        x: 0,
                        y: isElevated ? 6 : 2
                    )
            )
    }
    
    /// Applique un style de carte avec couleur d'accent sur le bord gauche
    /// - Parameters:
    ///   - accentColor: Couleur de l'accent
    ///   - cornerRadius: Rayon des coins
    /// - Returns: La vue stylisée
    func accentedCardStyle(
        accentColor: Color,
        cornerRadius: CGFloat = 16
    ) -> some View {
        self
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(UIColor.systemBackground))
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(accentColor)
                            .frame(width: 6)
                            .opacity(0.9)
                    }
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            )
    }
    
    /// Style de carte glassmorphism (effet de verre flou)
    func glassCardStyle(cornerRadius: CGFloat = 20) -> some View {
        self
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
    }
}

// MARK: - Animation Extensions

extension View {
    /// Animation de rebond lors de l'apparition
    func bounceOnAppear(delay: Double = 0) -> some View {
        modifier(BounceOnAppearModifier(delay: delay))
    }
    
    /// Animation de fondu lors de l'apparition
    func fadeInOnAppear(delay: Double = 0, duration: Double = 0.3) -> some View {
        modifier(FadeInOnAppearModifier(delay: delay, duration: duration))
    }
    
    /// Animation de slide depuis le bas
    func slideUpOnAppear(delay: Double = 0) -> some View {
        modifier(SlideUpOnAppearModifier(delay: delay))
    }
    
    /// Animation de pulsation continue
    func pulsating(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 1.0) -> some View {
        modifier(PulsatingModifier(minScale: minScale, maxScale: maxScale, duration: duration))
    }
    
    /// Effet de press (scale down quand pressé)
    func pressEffect(scale: CGFloat = 0.95) -> some View {
        modifier(PressEffectModifier(scale: scale))
    }
}

// MARK: - Animation Modifiers

/// Modificateur pour animation de rebond à l'apparition
struct BounceOnAppearModifier: ViewModifier {
    let delay: Double
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(delay)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
    }
}

/// Modificateur pour fondu à l'apparition
struct FadeInOnAppearModifier: ViewModifier {
    let delay: Double
    let duration: Double
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: duration).delay(delay)) {
                    opacity = 1.0
                }
            }
    }
}

/// Modificateur pour slide depuis le bas
struct SlideUpOnAppearModifier: ViewModifier {
    let delay: Double
    @State private var offset: CGFloat = 30
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                    offset = 0
                    opacity = 1.0
                }
            }
    }
}

/// Modificateur pour pulsation continue
struct PulsatingModifier: ViewModifier {
    let minScale: CGFloat
    let maxScale: CGFloat
    let duration: Double
    @State private var scale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                scale = minScale
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    scale = maxScale
                }
            }
    }
}

/// Modificateur pour effet de press
struct PressEffectModifier: ViewModifier {
    let scale: CGFloat
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - Staggered Animation Extension
// Note: Les modificateurs conditionnels `if` sont déjà définis dans ViewExtensions.swift

extension View {
    /// Animation échelonnée pour les listes
    func staggeredAnimation(index: Int, total: Int, baseDelay: Double = 0.05) -> some View {
        self.fadeInOnAppear(delay: Double(index) * baseDelay)
    }
}

// MARK: - Haptic Feedback Button Style

/// Style de bouton avec retour haptique
struct HapticButtonStyle: ButtonStyle {
    var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.impact(style: feedbackStyle)
                }
            }
    }
}

extension ButtonStyle where Self == HapticButtonStyle {
    static var haptic: HapticButtonStyle { HapticButtonStyle() }
    static func haptic(style: UIImpactFeedbackGenerator.FeedbackStyle) -> HapticButtonStyle {
        HapticButtonStyle(feedbackStyle: style)
    }
}

// MARK: - Blur Effect Extension

extension View {
    /// Applique un flou conditionnel
    func conditionalBlur(_ isBlurred: Bool, radius: CGFloat = 3) -> some View {
        self.blur(radius: isBlurred ? radius : 0)
    }
}

// MARK: - Safe Area Aware Padding

extension View {
    /// Padding qui prend en compte la safe area
    func safeAreaPadding(_ edges: Edge.Set = .all, _ length: CGFloat = 16) -> some View {
        self.safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: length)
        }
    }
}

// MARK: - Color Extensions pour les états

extension Color {
    /// Retourne la couleur appropriée pour un état de validation
    static func forState(_ state: Int) -> Color {
        switch state {
        case 0: return SNCFColors.corail      // Non validé
        case 1: return SNCFColors.safran      // Partiel
        case 2: return SNCFColors.menthe      // Validé
        case 3: return SNCFColors.bleuHorizon // Non traité
        default: return Color.gray
        }
    }
    
    /// Retourne le dégradé approprié pour un état de validation
    static func gradientForState(_ state: Int) -> [Color] {
        switch state {
        case 0: return [SNCFColors.corail, SNCFColors.ocre]
        case 1: return [SNCFColors.safran, SNCFColors.ambre]
        case 2: return [SNCFColors.menthe, SNCFColors.vertEau]
        case 3: return [SNCFColors.ceruleen, SNCFColors.bleuHorizon]
        default: return [Color.gray, Color.gray.opacity(0.7)]
        }
    }
}

// MARK: - Preview

#Preview("Card Styles") {
    ScrollView {
        VStack(spacing: 20) {
            Text("Carte standard")
                .cardStyle()
            
            Text("Carte élevée")
                .cardStyle(isElevated: true)
            
            Text("Carte avec accent")
                .accentedCardStyle(accentColor: SNCFColors.ceruleen)
            
            Text("Carte glass")
                .glassCardStyle()
        }
        .padding()
    }
    .background(Color(UIColor.systemGroupedBackground))
}

#Preview("Animations") {
    VStack(spacing: 30) {
        Text("Bounce")
            .padding()
            .background(SNCFColors.ceruleen)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .bounceOnAppear()
        
        Text("Slide Up")
            .padding()
            .background(SNCFColors.menthe)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .slideUpOnAppear(delay: 0.2)
        
        Text("Pulsating")
            .padding()
            .background(SNCFColors.safran)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .pulsating()
    }
}

