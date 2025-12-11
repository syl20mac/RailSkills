//
//  DemoModeService.swift
//  RailSkills
//
//  Service pour gérer le mode démonstration pour les reviewers Apple
//  Permet d'accéder à toutes les fonctionnalités sans authentification réelle
//

import Foundation
import Combine

/// Service pour gérer le mode démonstration
@MainActor
class DemoModeService: ObservableObject {
    static let shared = DemoModeService()
    
    /// Clé UserDefaults pour le mode démo
    private let demoModeKey = "demo_mode_enabled"
    
    /// Indique si le mode démo est activé
    @Published var isDemoModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDemoModeEnabled, forKey: demoModeKey)
            Logger.info("Mode démo \(isDemoModeEnabled ? "activé" : "désactivé")", category: "DemoMode")
        }
    }
    
    /// Email de démonstration
    let demoEmail = "demo.reviewer@sncf.fr"
    
    /// Nom de démonstration
    let demoName = "Reviewer Apple"
    
    private init() {
        // Charger l'état depuis UserDefaults
        self.isDemoModeEnabled = UserDefaults.standard.bool(forKey: demoModeKey)
    }
    
    /// Active le mode démonstration
    func enableDemoMode() {
        isDemoModeEnabled = true
        Logger.success("Mode démonstration activé", category: "DemoMode")
    }
    
    /// Désactive le mode démonstration
    func disableDemoMode() {
        isDemoModeEnabled = false
        Logger.success("Mode démonstration désactivé", category: "DemoMode")
    }
    
    /// Crée un profil utilisateur de démonstration
    func createDemoUserProfile() -> UserProfile {
        return UserProfile(
            id: UUID().uuidString,
            email: demoEmail,
            cttId: demoEmail, // Utiliser l'email comme CTT ID
            role: .admin, // Admin pour accéder à toutes les fonctionnalités
            hasGlobalView: true, // Accès global
            createdAt: ISO8601DateFormatter().string(from: Date()),
            lastLogin: ISO8601DateFormatter().string(from: Date())
        )
    }
}
