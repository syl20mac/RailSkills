//
//  DriversPanelView.swift
//  RailSkills
//
//  Panneau de sélection des conducteurs
//

import SwiftUI

/// Panneau de sélection et gestion des conducteurs
struct DriversPanelView: View {
    @ObservedObject var vm: ViewModel
    let onAddDriver: () -> Void
    
    var body: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: 12) {
                if vm.store.drivers.isEmpty {
                    emptyStateView
                } else if !vm.store.drivers.indices.contains(vm.selectedDriverIndex) {
                    noSelectionView
                } else {
                    driverPicker
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
    
    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Aucun conducteur")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            ModernButton(
                title: "Ajouter un conducteur",
                icon: "person.badge.plus",
                style: .primary
            ) {
                HapticFeedbackManager.shared.buttonPress()
                onAddDriver()
            }
            .accessibilityLabel("Ajouter un conducteur")
            .accessibilityHint("Double-tapez pour créer un nouveau conducteur")
        }
    }
    
    private var noSelectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Aucun conducteur sélectionné")
                .font(.headline)
                .foregroundStyle(.primary)
            Text("Choisissez un conducteur dans la liste pour activer le suivi.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            driverPicker
        }
    }
    
    private var driverPicker: some View {
        Picker("Conducteur", selection: Binding(
            get: { vm.selectedDriverIndex },
            set: { newIndex in
                HapticFeedbackManager.shared.selection()
                vm.selectedDriverIndex = newIndex
            }
        )) {
            ForEach(Array(vm.store.drivers.enumerated()), id: \.element.id) { index, driver in
                Text(driver.name).tag(index)
            }
        }
        .pickerStyle(.menu)
        .accessibilityLabel("Sélectionner un conducteur")
        .accessibilityHint("Double-tapez pour ouvrir la liste des conducteurs")
    }
}

