//
//  Fonts.swift
//  RailSkills
//
//  Extension pour utiliser les polices système iOS avec un style cohérent
//  Utilise SF Pro (police système Apple) pour garantir la conformité App Store
//

import SwiftUI
import UIKit

// MARK: - Extension Font pour le style RailSkills

extension Font {
    /// Police système avec différentes graisses
    /// - Parameters:
    ///   - weight: La graisse de la police
    ///   - size: La taille de la police
    /// - Returns: Une police système iOS
    static func avenir(_ weight: AvenirWeight = .roman, size: CGFloat) -> Font {
        // Utilise directement la police système iOS (SF Pro)
        return Font.system(size: size, weight: weight.systemWeight, design: .rounded)
    }
    
    // MARK: - Variantes prédéfinies pour SwiftUI
    
    /// Titre principal (équivalent à .largeTitle)
    static var avenirLargeTitle: Font {
        .system(size: 34, weight: .bold, design: .rounded)
    }
    
    /// Titre (équivalent à .title)
    static var avenirTitle: Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }
    
    /// Titre 2 (équivalent à .title2)
    static var avenirTitle2: Font {
        .system(size: 22, weight: .bold, design: .rounded)
    }
    
    /// Titre 3 (équivalent à .title3)
    static var avenirTitle3: Font {
        .system(size: 20, weight: .semibold, design: .rounded)
    }
    
    /// En-tête (équivalent à .headline)
    static var avenirHeadline: Font {
        .system(size: 17, weight: .semibold, design: .rounded)
    }
    
    /// Corps de texte (équivalent à .body)
    static var avenirBody: Font {
        .system(size: 17, weight: .regular, design: .rounded)
    }
    
    /// Corps de texte secondaire (équivalent à .callout)
    static var avenirCallout: Font {
        .system(size: 16, weight: .regular, design: .rounded)
    }
    
    /// Sous-titre (équivalent à .subheadline)
    static var avenirSubheadline: Font {
        .system(size: 15, weight: .regular, design: .rounded)
    }
    
    /// Légende (équivalent à .footnote)
    static var avenirFootnote: Font {
        .system(size: 13, weight: .regular, design: .rounded)
    }
    
    /// Légende (équivalent à .caption)
    static var avenirCaption: Font {
        .system(size: 12, weight: .regular, design: .rounded)
    }
    
    /// Légende 2 (équivalent à .caption2)
    static var avenirCaption2: Font {
        .system(size: 11, weight: .regular, design: .rounded)
    }
}

// MARK: - Enum pour les graisses

/// Graisses disponibles (compatibilité avec l'ancien code)
enum AvenirWeight {
    case light     // Très léger
    case book      // Léger
    case roman     // Normal
    case medium    // Moyen
    case heavy     // Gras
    case black     // Très gras
    
    /// Poids système correspondant
    var systemWeight: Font.Weight {
        switch self {
        case .light: return .ultraLight
        case .book: return .light
        case .roman: return .regular
        case .medium: return .medium
        case .heavy: return .bold
        case .black: return .black
        }
    }
    
    /// Poids UIFont correspondant
    var uiFontWeight: UIFont.Weight {
        switch self {
        case .light: return .ultraLight
        case .book: return .light
        case .roman: return .regular
        case .medium: return .medium
        case .heavy: return .bold
        case .black: return .black
        }
    }
}

// MARK: - Extension UIFont pour les PDFs

extension UIFont {
    /// Crée une police UIFont système pour la génération de PDF
    /// - Parameters:
    ///   - weight: La graisse de la police
    ///   - size: La taille de la police
    /// - Returns: Une police UIFont système
    static func avenir(_ weight: AvenirWeight = .roman, size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: weight.uiFontWeight)
    }
    
    /// Variantes prédéfinies pour les PDFs
    static var avenirTitlePDF: UIFont {
        .systemFont(ofSize: 24, weight: .bold)
    }
    
    static var avenirHeaderPDF: UIFont {
        .systemFont(ofSize: 18, weight: .bold)
    }
    
    static var avenirSubHeaderPDF: UIFont {
        .systemFont(ofSize: 16, weight: .semibold)
    }
    
    static var avenirBodyPDF: UIFont {
        .systemFont(ofSize: 12, weight: .regular)
    }
    
    static var avenirCaptionPDF: UIFont {
        .systemFont(ofSize: 10, weight: .regular)
    }
    
    static var avenirFootnotePDF: UIFont {
        .systemFont(ofSize: 9, weight: .regular)
    }
}
