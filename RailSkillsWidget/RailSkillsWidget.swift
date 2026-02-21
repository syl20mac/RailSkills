//
//  RailSkillsWidget.swift
//  RailSkillsWidget
//
//  Point d'entrée du widget — déclare les 3 tailles supportées
//  et regroupe les widgets dans un WidgetBundle.
//

import WidgetKit
import SwiftUI

// MARK: - Widget principal (Small + Medium + Large)

struct RailSkillsWidget: Widget {
    let kind: String = "RailSkillsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RailSkillsWidgetProvider()) { entry in
            RailSkillsWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("RailSkills")
        .description("Suivez la progression de vos conducteurs.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Routeur de vue selon la taille

struct RailSkillsWidgetEntryView: View {
    let entry: RailSkillsEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
        .widgetURL(URL(string: "railskills://widget"))
    }
}

// MARK: - Bundle

@main
struct RailSkillsWidgetBundle: WidgetBundle {
    var body: some Widget {
        RailSkillsWidget()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    RailSkillsWidget()
} timeline: {
    RailSkillsEntry.placeholder()
}

#Preview("Medium", as: .systemMedium) {
    RailSkillsWidget()
} timeline: {
    RailSkillsEntry.placeholder()
}

#Preview("Large", as: .systemLarge) {
    RailSkillsWidget()
} timeline: {
    RailSkillsEntry.placeholder()
}
