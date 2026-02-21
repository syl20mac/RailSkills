//
//  Store+Widget.swift
//  RailSkills
//
//  Extension de Store pour mettre à jour les données du widget
//  dans l'App Group partagé, et déclencher le rafraîchissement WidgetKit.
//
//  Appelé automatiquement à chaque modification des conducteurs ou des checklists.
//

import Foundation
import WidgetKit

extension Store {

    // MARK: - Mise à jour du widget

    /// Recalcule et sauvegarde les données du widget dans l'App Group,
    /// puis demande à WidgetKit de rafraîchir les timelines.
    func refreshWidgetData() {
        let summaries = buildDriverSummaries()
        let widgetData = WidgetData(
            drivers: summaries,
            lastUpdate: Date(),
            totalDriverCount: drivers.count
        )
        WidgetDataStore.save(widgetData)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Construction des résumés

    /// Transforme les DriverRecord du Store en WidgetDriverSummary,
    /// en calculant la progression pour chaque checklist.
    private func buildDriverSummaries() -> [WidgetDriverSummary] {
        drivers.map { driver in
            let progressTriennale = computeProgress(for: driver, checklist: checklistTriennale)
            let progressVP        = computeProgress(for: driver, checklist: checklistVP)
            let progressTE        = computeProgress(for: driver, checklist: checklistTE)

            return WidgetDriverSummary(
                id: driver.id.uuidString,
                name: driver.name,
                firstName: driver.firstName,
                cpNumber: driver.cpNumber,
                progressTriennale: progressTriennale,
                progressVP: progressVP,
                progressTE: progressTE,
                lastEvaluation: driver.lastEvaluation,
                triennialStart: driver.triennialStart
            )
        }
        // Trier par progression globale décroissante pour afficher les plus avancés en premier
        .sorted { $0.globalProgress > $1.globalProgress }
    }

    /// Calcule la proportion de questions validées (état == 2) pour un conducteur et une checklist donnés.
    private func computeProgress(for driver: DriverRecord, checklist: Checklist?) -> Double {
        guard let cl = checklist else { return 0 }
        let questions = cl.items.filter { !$0.isCategory }
        guard !questions.isEmpty else { return 0 }
        let stateMap = driver.checklistStates[cl.title] ?? [:]
        let validated = questions.filter { stateMap[$0.id.uuidString] == 2 }.count
        return Double(validated) / Double(questions.count)
    }
}
