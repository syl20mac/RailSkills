//
//  SNCFColors.swift
//  RailSkills
//
//  Palette de couleurs officielle SNCF selon la charte graphique
//

import SwiftUI

/// Palette de couleurs officielle SNCF
enum SNCFColors {
    // MARK: - Couleurs claires/pastels
    
    /// Ambre - Jaune-orange clair
    static let ambre = Color(hex: "#EDD484")
    
    /// Pêche - Pêche clair
    static let peche = Color(hex: "#FDBE87")
    
    /// Nude - Rose-beige clair
    static let nude = Color(hex: "#F8C1B8")
    
    /// Dragée - Lavande-rose clair
    static let dragee = Color(hex: "#EFBAE1")
    
    /// Parme - Violet clair
    static let parme = Color(hex: "#C7B2DE")
    
    /// Bleu Horizon - Bleu ciel clair
    static let bleuHorizon = Color(hex: "#A4C8E1")
    
    /// Vert d'eau - Turquoise clair
    static let vertEau = Color(hex: "#A1D6CA")
    
    // MARK: - Couleurs vives/moyennes
    
    /// Safran - Jaune doré profond
    static let safran = Color(hex: "#DAAA00")
    
    /// Ocre - Orange-brun
    static let ocre = Color(hex: "#DC582A")
    
    /// Corail - Rose corail
    static let corail = Color(hex: "#F2827F")
    
    /// Vieux Rose - Rose fané
    static let vieuxRose = Color(hex: "#F59BBB")
    
    /// Lavande - Violet moyen
    static let lavande = Color(hex: "#6558B1")
    
    /// Céruléen - Bleu vif
    static let ceruleen = Color(hex: "#0084D4")
    
    /// Menthe - Vert émeraude
    static let menthe = Color(hex: "#00B388")
    
    // MARK: - Couleurs sombres
    
    /// Mordoré - Vert olive foncé/brun
    static let mordore = Color(hex: "#4A412A")
    
    /// Chocolat - Brun foncé
    static let chocolat = Color(hex: "#4F2910")
    
    /// Burgundy - Rouge-violet profond
    static let burgundy = Color(hex: "#651C32")
    
    /// Aubergine - Violet foncé
    static let aubergine = Color(hex: "#3F2A56")
    
    /// Bleu Marine - Bleu marine foncé
    static let bleuMarine = Color(hex: "#00205B")
    
    /// Cobalt - Bleu foncé
    static let cobalt = Color(hex: "#003865")
    
    /// Forêt - Vert forêt foncé
    static let foret = Color(hex: "#154734")
    
    // MARK: - Couleurs sémantiques pour l'application
    
    /// Couleur principale (bleu SNCF)
    static let primary = ceruleen
    
    /// Couleur secondaire (vert SNCF)
    static let secondary = menthe
    
    /// Couleur d'accent (orange SNCF)
    static let accent = ocre
    
    /// Couleur de succès (vert)
    static let success = menthe
    
    /// Couleur d'avertissement (orange)
    static let warning = safran
    
    /// Couleur d'erreur (rouge/corail)
    static let error = corail
    
    /// Couleur d'information (bleu)
    static let info = bleuHorizon
    
    /// Couleur pour les exports (vert)
    static let export = menthe
    
    /// Couleur pour les imports (bleu)
    static let `import` = ceruleen
    
    /// Couleur pour les checklists (violet)
    static let checklist = parme
    
    /// Couleur pour les conducteurs (bleu)
    static let driver = ceruleen
    
    /// Couleur pour plusieurs conducteurs (orange)
    static let multipleDrivers = ocre
}

// MARK: - Extension Color pour support hex

extension Color {
    /// Initialise une couleur depuis un code hexadécimal
    /// - Parameter hex: Code hexadécimal (ex: "#0084D4" ou "0084D4")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12 bits)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RRGGBB (24 bits)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // RRGGBBAA (32 bits)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Extension pour les états avec couleurs SNCF

extension Color {
    /// Retourne une couleur SNCF correspondant à l'état (0=rouge, 1=orange, 2=vert, 3=bleu)
    /// Utilise la palette officielle SNCF
    static func sncfState(_ state: Int, opacity: Double = 1.0) -> Color {
        switch state {
        case 3: return SNCFColors.bleuHorizon.opacity(opacity)      // Non traité
        case 2: return SNCFColors.menthe.opacity(opacity)            // Validé
        case 1: return SNCFColors.safran.opacity(opacity)           // Partiel
        default: return SNCFColors.corail.opacity(opacity)          // Non validé
        }
    }
}

// MARK: - Extensions pour le Dark Mode

extension SNCFColors {
    /// Couleur adaptée au mode (clair/sombre)
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
            }
        )
    }
    
    // MARK: - Couleurs adaptatives pour les surfaces
    
    /// Fond de carte - s'adapte au mode
    static let cardBackground = adaptive(
        light: Color(UIColor.secondarySystemBackground),
        dark: Color(UIColor.secondarySystemBackground)
    )
    
    /// Fond de surface - s'adapte au mode
    static let surfaceBackground = adaptive(
        light: Color.white,
        dark: Color(UIColor.systemGray6)
    )
    
    /// Fond élevé - pour les cartes avec elevation
    static let elevatedBackground = adaptive(
        light: Color.white,
        dark: Color(UIColor.systemGray5)
    )
    
    /// Séparateur subtil
    static let subtleBorder = adaptive(
        light: Color.primary.opacity(0.08),
        dark: Color.primary.opacity(0.15)
    )
    
    // MARK: - Couleurs de texte adaptatives
    
    /// Texte principal adaptatif
    static let adaptiveText = adaptive(
        light: Color.primary,
        dark: Color.primary
    )
    
    /// Texte secondaire adaptatif
    static let adaptiveSecondary = adaptive(
        light: Color.secondary,
        dark: Color.secondary
    )
}
