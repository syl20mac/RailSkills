//
//  RailSkillsWidgetProvider.swift
//  RailSkillsWidget
//
//  Timeline provider — fournit les entrées affichées par le widget.
//  Les données sont lues depuis l'App Group partagé avec l'app principale.
//

import WidgetKit
import SwiftUI

// MARK: - Entry

struct RailSkillsEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
    let isPlaceholder: Bool

    static func placeholder() -> RailSkillsEntry {
        RailSkillsEntry(
            date: Date(),
            data: WidgetDataStore.placeholder(),
            isPlaceholder: true
        )
    }
}

// MARK: - Provider

struct RailSkillsWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> RailSkillsEntry {
        .placeholder()
    }

    func getSnapshot(in context: Context, completion: @escaping (RailSkillsEntry) -> Void) {
        let data = WidgetDataStore.load() ?? WidgetDataStore.placeholder()
        completion(RailSkillsEntry(date: Date(), data: data, isPlaceholder: false))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RailSkillsEntry>) -> Void) {
        let data = WidgetDataStore.load() ?? WidgetDataStore.placeholder()
        let entry = RailSkillsEntry(date: Date(), data: data, isPlaceholder: false)

        // Rafraîchir toutes les 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
