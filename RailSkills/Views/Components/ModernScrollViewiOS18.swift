//
//  ModernScrollViewiOS18.swift
//  RailSkills
//
//  ScrollView moderne iOS 18+ avec scrollTargetBehavior et scrollTransition
//

import SwiftUI

/// Comportements de scroll disponibles
@available(iOS 18.0, *)
enum ScrollBehaviorType {
    case viewAligned
    case paging
}

/// ScrollView moderne iOS 18+ avec comportements personnalisés
@available(iOS 18.0, *)
struct ModernScrollView<Content: View>: View {
    let content: Content
    var behaviorType: ScrollBehaviorType = .viewAligned
    var showIndicators: Bool = true
    var enableScrollTransition: Bool = true
    
    init(
        behavior: ScrollBehaviorType = .viewAligned,
        showIndicators: Bool = true,
        enableScrollTransition: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.behaviorType = behavior
        self.showIndicators = showIndicators
        self.enableScrollTransition = enableScrollTransition
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            content
                .if(enableScrollTransition) { view in
                    view.scrollTransition { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1.0 : 0.7)
                            .blur(radius: phase.isIdentity ? 0 : 4)
                            .scaleEffect(phase.isIdentity ? 1.0 : 0.97)
                    }
                }
        }
        .applyScrollBehavior(behaviorType)
        .scrollIndicators(showIndicators ? .visible : .hidden)
    }
}

/// Extension pour appliquer les comportements de scroll
@available(iOS 18.0, *)
extension View {
    @ViewBuilder
    func applyScrollBehavior(_ behavior: ScrollBehaviorType) -> some View {
        switch behavior {
        case .viewAligned:
            self.scrollTargetBehavior(.viewAligned)
        case .paging:
            self.scrollTargetBehavior(.paging)
        }
    }
}

// MARK: - Preview

@available(iOS 18.0, *)
#Preview {
    ModernScrollView(behavior: .viewAligned) {
        VStack(spacing: 20) {
            ForEach(0..<10) { index in
                ModernCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Section \(index + 1)")
                            .font(.headline)
                        Text("Contenu de la section \(index + 1)")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}
