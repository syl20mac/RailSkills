//
//  AppMode.swift
//  RailSkills
//
//  Définit le mode de fonctionnement de l'application
//

import Foundation

/// Mode de fonctionnement de l'application
enum AppMode: String, Codable, CaseIterable {
    /// Mode avec authentification et synchronisation (ex: SNCF)
    case enterprise
    /// Mode hors-ligne, données stockées localement
    case local
    /// Mode configuration initiale (choix non fait)
    case setup
    
    /// Titre affiché pour le mode
    var title: String {
        switch self {
        case .enterprise: return "Mode Entreprise"
        case .local: return "Mode Local (Découverte)"
        case .setup: return "Configuration"
        }
    }
    
    /// Description affichée à l'utilisateur
    var description: String {
        switch self {
        case .enterprise: return "Connectez-vous avec votre compte professionnel pour synchroniser vos données."
        case .local: return "Utilisez l'application sans compte. Vos données restent uniquement sur cet appareil."
        case .setup: return "Choisissez le mode de fonctionnement de l'application."
        }
    }
}
