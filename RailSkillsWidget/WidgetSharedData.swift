//
//  WidgetSharedData.swift
//  RailSkills
//
//  Modèle de données partagées entre l'app principale et le widget
//  via UserDefaults(suiteName: AppGroup).
//
//  Ce fichier doit être ajouté aux deux targets :
//  - RailSkills (target principale)
//  - RailSkillsWidget (target widget)
//

import Foundation

// MARK: - Identifiant du groupe partagé

/// App Group identifier — à configurer dans les entitlements des deux targets
let railSkillsAppGroup = "group.com.railskills.shared"

/// Clé UserDefaults pour les données widget
let widgetDataKey = "railskills_widget_data"

// MARK: - Modèle partagé

/// Données résumées d'un conducteur, lisibles par le widget
struct WidgetDriverSummary: Codable {
    let id: String
    let name: String
    let firstName: String?
    let cpNumber: String?
    /// Progression Suivi (0.0 – 1.0)
    let progressTriennale: Double
    /// Progression VP (0.0 – 1.0)
    let progressVP: Double
    /// Progression TE (0.0 – 1.0)
    let progressTE: Double
    /// Date de la dernière évaluation
    let lastEvaluation: Date?
    /// Date de début de période triennale
    let triennialStart: Date?

    /// Initiales pour l'avatar
    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    /// Nom affiché (prénom + nom)
    var displayName: String {
        if let fn = firstName, !fn.isEmpty {
            return "\(fn) \(name)"
        }
        return name
    }

    /// Progression globale (moyenne des 3 checklists actives)
    var globalProgress: Double {
        let values = [progressTriennale, progressVP, progressTE].filter { $0 > 0 }
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
}

/// Snapshot global pour le widget
struct WidgetData: Codable {
    /// Conducteurs à afficher (triés par progression décroissante)
    let drivers: [WidgetDriverSummary]
    /// Date de dernière mise à jour
    let lastUpdate: Date
    /// Nombre total de conducteurs dans l'app
    let totalDriverCount: Int

    /// Conducteur le plus récemment évalué
    var mostRecentDriver: WidgetDriverSummary? {
        drivers.filter { $0.lastEvaluation != nil }
            .max { ($0.lastEvaluation ?? .distantPast) < ($1.lastEvaluation ?? .distantPast) }
    }

    /// Conducteur avec la progression globale la plus faible (nécessite attention)
    var lowestProgressDriver: WidgetDriverSummary? {
        drivers.min { $0.globalProgress < $1.globalProgress }
    }

    /// Progression globale de tous les conducteurs
    var averageGlobalProgress: Double {
        guard !drivers.isEmpty else { return 0 }
        return drivers.reduce(0) { $0 + $1.globalProgress } / Double(drivers.count)
    }
}

// MARK: - Persistance partagée

/// Lit/écrit les données du widget dans l'App Group
enum WidgetDataStore {

    static func save(_ data: WidgetData) {
        guard let suite = UserDefaults(suiteName: railSkillsAppGroup) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let encoded = try? encoder.encode(data) {
            suite.set(encoded, forKey: widgetDataKey)
        }
    }

    static func load() -> WidgetData? {
        guard let suite = UserDefaults(suiteName: railSkillsAppGroup),
              let data = suite.data(forKey: widgetDataKey) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WidgetData.self, from: data)
    }

    /// Données de démo pour les previews Xcode
    static func placeholder() -> WidgetData {
        let demo = WidgetDriverSummary(
            id: "demo",
            name: "MARTIN",
            firstName: "Jean",
            cpNumber: "CP-1234",
            progressTriennale: 0.72,
            progressVP: 0.58,
            progressTE: 0.85,
            lastEvaluation: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
            triennialStart: Calendar.current.date(byAdding: .year, value: -1, to: Date())
        )
        let demo2 = WidgetDriverSummary(
            id: "demo2",
            name: "DUBOIS",
            firstName: "Marie",
            cpNumber: "CP-5678",
            progressTriennale: 0.45,
            progressVP: 0.90,
            progressTE: 0.60,
            lastEvaluation: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
            triennialStart: Calendar.current.date(byAdding: .month, value: -8, to: Date())
        )
        return WidgetData(
            drivers: [demo, demo2],
            lastUpdate: Date(),
            totalDriverCount: 12
        )
    }
}
