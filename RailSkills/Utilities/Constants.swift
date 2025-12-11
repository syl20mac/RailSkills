//
//  Constants.swift
//  RailSkills
//
//  Constantes centralisées de l'application pour éviter les valeurs magiques
//

import Foundation
import SwiftUI

/// Constantes centralisées de l'application
enum AppConstants {
    /// Constantes liées au débouncing et aux délais
    enum Debounce {
        /// Délai pour la sauvegarde locale (UserDefaults)
        static let saveDelay: TimeInterval = 0.3
        
        /// Délai pour la synchronisation SharePoint (plus long car requête réseau)
        static let sharePointSyncDelay: TimeInterval = 2.0
    }
    
    /// Constantes liées à l'interface utilisateur
    enum UI {
        /// Marge des pages PDF
        static let pageMargin: CGFloat = 36.0
        
        /// Largeur d'une page PDF (A4)
        static let pageWidth: CGFloat = 595.0
        
        /// Hauteur d'une page PDF (A4)
        static let pageHeight: CGFloat = 842.0
        
        /// Rayon des coins arrondis par défaut
        static let cornerRadius: CGFloat = 12.0
        
        /// Opacité par défaut pour les couleurs adoucies
        static let softColorOpacity: Double = 0.7
        
        /// Opacité pour les cercles de fond (icônes)
        static let iconBackgroundOpacity: Double = 0.12
    }
    
    /// Constantes liées aux données
    enum Data {
        /// Version du format d'export
        static let exportFormatVersion = "1.0"
        
        /// Nom de l'application pour les exports
        static let exporterInfo = "RailSkills v2.0"
        
        /// Longueur maximale d'un nom de fichier
        static let maxFileNameLength = 255
    }
    
    /// Constantes liées aux dates
    enum Date {
        /// Durée d'une période triennale en années
        static let triennialYears = 3
        
        /// Nombre de jours avant échéance pour alerte orange (3 mois)
        static let warningDaysThreshold = 90
        
        /// Nombre de jours avant échéance pour alerte rouge
        static let criticalDaysThreshold = 0
    }
    
    /// Constantes liées à la validation
    enum Validation {
        /// Longueur minimale d'un nom de conducteur
        static let minDriverNameLength = 1
        
        /// Longueur maximale d'un nom de conducteur
        static let maxDriverNameLength = 100
        
        /// Taille maximale d'un fichier d'import (10 MB)
        static let maxImportFileSize: Int = 10_000_000
    }
    
    /// Constantes liées à la recherche
    enum Search {
        /// Délai de debounce pour la recherche (en secondes)
        static let debounceDelay: TimeInterval = 0.3
        
        /// Longueur minimale d'un mot pour l'indexation (3 caractères)
        static let minWordLength = 3
    }
    
    /// Constantes liées aux exports
    enum Export {
        /// Délai minimum entre deux exports (en secondes) - rate limiting
        static let cooldownDelay: TimeInterval = 1.0
    }
}

