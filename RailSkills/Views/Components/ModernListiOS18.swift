//
//  ModernListiOS18.swift
//  RailSkills
//
//  Liste moderne iOS 18+ avec séparateurs personnalisés et scrollTransition
//

import SwiftUI

/// Extension pour List avec séparateurs personnalisés iOS 18
@available(iOS 18.0, *)
extension View {
    /// Personnalise les séparateurs de liste avec les couleurs SNCF
    func sncfListStyle() -> some View {
        self
            .listRowSeparatorTint(SNCFColors.ceruleen.opacity(0.2))
            .listSectionSeparatorTint(SNCFColors.ceruleen.opacity(0.3))
    }
    
    /// Ajoute un scrollTransition iOS 18 à une liste
    func withScrollTransition(
        opacity: @escaping (ScrollTransitionPhase) -> Double = { $0.isIdentity ? 1.0 : 0.6 },
        scale: @escaping (ScrollTransitionPhase) -> CGFloat = { $0.isIdentity ? 1.0 : 0.95 },
        blur: @escaping (ScrollTransitionPhase) -> CGFloat = { $0.isIdentity ? 0 : 5 }
    ) -> some View {
        self.scrollTransition { content, phase in
            content
                .opacity(opacity(phase))
                .scaleEffect(scale(phase))
                .blur(radius: blur(phase))
        }
    }
}

/// Wrapper pour List avec style SNCF iOS 18
@available(iOS 18.0, *)
struct ModernList<Content: View>: View {
    let content: Content
    var enableScrollTransition: Bool = false
    
    init(
        enableScrollTransition: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.enableScrollTransition = enableScrollTransition
        self.content = content()
    }
    
    var body: some View {
        List {
            content
        }
        .listStyle(.insetGrouped)
        .sncfListStyle()
        .if(enableScrollTransition) { view in
            view.withScrollTransition()
        }
    }
}

// MARK: - Preview

@available(iOS 18.0, *)
#Preview {
    ModernList(enableScrollTransition: true) {
        Section("Conducteurs") {
            ForEach(0..<5) { index in
                HStack {
                    Circle()
                        .fill(SNCFColors.ceruleen)
                        .frame(width: 40, height: 40)
                    Text("Conducteur \(index + 1)")
                        .font(.headline)
                }
                .listRowSeparatorTint(SNCFColors.ceruleen.opacity(0.2))
            }
        }
        
        Section("Checklists") {
            ForEach(0..<3) { index in
                Text("Checklist \(index + 1)")
                    .listRowSeparatorTint(SNCFColors.menthe.opacity(0.2))
            }
        }
    }
}

