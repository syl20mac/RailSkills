//
//  ViewExtensions.swift
//  RailSkills
//
//  Extensions utiles pour les vues SwiftUI iOS 18+
//

import SwiftUI

// MARK: - Extension pour conditionnel modifier

extension View {
    /// Modifier conditionnel pour les vues
    /// Permet d'appliquer un modifier seulement si une condition est vraie
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Modifier conditionnel avec else
    /// Permet d'appliquer un modifier différent selon une condition
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
}









