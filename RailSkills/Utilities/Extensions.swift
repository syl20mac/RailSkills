//
//  Extensions.swift
//  RailSkills
//
//  Extensions utiles pour Color, Data, View
//

import Foundation
import SwiftUI

// MARK: - Extension Data pour la compression

extension Data {
    /// Compresse les données avec l'algorithme LZFSE
    var compressed: Data {
        return (try? (self as NSData).compressed(using: .lzfse) as Data) ?? self
    }
    
    /// Décompresse les données avec l'algorithme LZFSE
    var decompressed: Data {
        return (try? (self as NSData).decompressed(using: .lzfse) as Data) ?? self
    }
}

// MARK: - Extension Color pour les états

extension Color {
    /// Retourne une couleur correspondant à l'état (0=rouge, 1=orange, 2=vert, 3=bleu)
    /// Utilise la palette officielle SNCF
    static func forState(_ state: Int, opacity: Double = 1.0) -> Color {
        return sncfState(state, opacity: opacity)
    }
}

// MARK: - Extension View pour la compatibilité iOS

extension View {
    /// Extension pour onChange (iOS 18+)
    @ViewBuilder
    func onChangeCompat<T: Equatable>(of value: T, action: @escaping () -> Void) -> some View {
        // iOS 18+ : onChange simplifié directement
        self.onChange(of: value, action)
    }
    
    /// Masque le clavier de manière sécurisée en évitant les conflits de contraintes
    func hideKeyboard() {
        DispatchQueue.main.async {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

