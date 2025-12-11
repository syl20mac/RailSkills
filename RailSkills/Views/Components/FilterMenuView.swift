//
//  FilterMenuView.swift
//  RailSkills
//
//  Vue du menu de filtre des questions de checklist
//

import SwiftUI

/// Enumération des filtres de checklist
enum ChecklistFilter: String, CaseIterable, Identifiable {
    case all
    case validated
    case partial
    case notValidated
    case notTreated

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "Tout"
        case .validated: return "Validé"
        case .partial: return "Partiel"
        case .notValidated: return "Non validé"
        case .notTreated: return "Non traité"
        }
    }

    var icon: String {
        switch self {
        case .all: return "line.3.horizontal.decrease.circle"
        case .validated: return "checkmark.circle.fill"
        case .partial: return "circle.lefthalf.fill"
        case .notValidated: return "xmark.circle.fill"
        case .notTreated: return "questionmark.circle.fill"
        }
    }

    func matches(state: Int) -> Bool {
        switch self {
        case .all: return true
        case .validated: return state == 2
        case .partial: return state == 1
        case .notValidated: return state == 0
        case .notTreated: return state == 3
        }
    }
    
    var accessibilityDescription: String {
        switch self {
        case .all: return "Afficher toutes les questions"
        case .validated: return "Afficher uniquement les questions validées"
        case .partial: return "Afficher uniquement les questions partiellement complétées"
        case .notValidated: return "Afficher uniquement les questions non validées"
        case .notTreated: return "Afficher uniquement les questions non traitées"
        }
    }
}

/// Vue du menu de filtre
struct FilterMenuView: View {
    @Binding var selectedFilter: ChecklistFilter
    let onFilterChange: () -> Void
    
    var body: some View {
        Menu {
            ForEach(ChecklistFilter.allCases) { filter in
                Button {
                    selectedFilter = filter
                    onFilterChange()
                } label: {
                    Label(filter.label, systemImage: filter.icon)
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(filter == selectedFilter ? SNCFColors.ceruleen : .primary)
                }
            }
        } label: {
            filterButtonLabel
        }
        .accessibilityLabel("Choisir un filtre de questions")
        .accessibilityHint("Double-tapez pour ouvrir le menu de filtres")
        .menuStyle(.automatic)
    }
    
    private var filterButtonLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: selectedFilter.icon)
            Text(selectedFilter.label)
                .fontWeight(.semibold)
            Image(systemName: "chevron.down")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .font(.footnote)
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .accessibilityValue(selectedFilter.accessibilityDescription)
    }
}

