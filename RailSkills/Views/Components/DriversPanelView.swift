//
//  DriversPanelView.swift
//  RailSkills
//
//  Panneau de sélection des conducteurs avec recherche intégrée
//

import SwiftUI

/// Panneau de sélection et gestion des conducteurs avec recherche
struct DriversPanelView: View {
    @ObservedObject var vm: ViewModel
    let onAddDriver: () -> Void
    
    @State private var showingDriverList = false
    @State private var searchText = ""
    
    // Liste filtrée des conducteurs selon la recherche
    private var filteredDrivers: [(index: Int, driver: DriverRecord)] {
        let enumerated = Array(vm.store.drivers.enumerated()).map { (index: $0.offset, driver: $0.element) }
        
        if searchText.isEmpty {
            return enumerated
        }
        
        let searchLower = searchText.lowercased()
        return enumerated.filter { item in
            item.driver.fullName.lowercased().contains(searchLower) ||
            (item.driver.cpNumber?.lowercased().contains(searchLower) ?? false)
        }
    }
    
    var body: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: 12) {
                if vm.store.drivers.isEmpty {
                    emptyStateView
                } else {
                    driverSelectorRow
                }
            }
        }
        .accessibilityElement(children: .contain)
        .sheet(isPresented: $showingDriverList) {
            driverListSheet
        }
    }
    
    // MARK: - Vue état vide
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
    
    // MARK: - Ligne de sélection compacte
    private var driverSelectorRow: some View {
        HStack(spacing: 12) {
            // Icône conducteur
            Image(systemName: "person.fill")
                .font(.title3)
                .foregroundStyle(SNCFColors.ceruleen)
            
            // Nom du conducteur sélectionné (cliquable)
            Button {
                HapticFeedbackManager.shared.buttonPress()
                showingDriverList = true
            } label: {
                HStack {
                    if vm.store.drivers.indices.contains(vm.selectedDriverIndex) {
                        Text(vm.store.drivers[vm.selectedDriverIndex].fullName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    } else {
                        Text("Sélectionner...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityLabel("Sélectionner un conducteur")
            .accessibilityHint("Double-tapez pour ouvrir la liste")
            
            Spacer()
            
            // Bouton recherche rapide
            Button {
                HapticFeedbackManager.shared.buttonPress()
                showingDriverList = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .foregroundStyle(SNCFColors.ceruleen)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(SNCFColors.ceruleen.opacity(0.1))
                    )
            }
            .accessibilityLabel("Rechercher un conducteur")
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Sheet avec liste et recherche
    private var driverListSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Barre de recherche
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Rechercher un conducteur...", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Nombre de résultats
                if !searchText.isEmpty {
                    HStack {
                        Text("\(filteredDrivers.count) conducteur(s) trouvé(s)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                // Liste des conducteurs
                List {
                    ForEach(filteredDrivers, id: \.driver.id) { item in
                        DriverListRow(
                            driver: item.driver,
                            isSelected: item.index == vm.selectedDriverIndex,
                            onSelect: {
                                HapticFeedbackManager.shared.selection()
                                vm.selectedDriverIndex = item.index
                                showingDriverList = false
                                searchText = ""
                            }
                        )
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Conducteurs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        showingDriverList = false
                        searchText = ""
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingDriverList = false
                        searchText = ""
                        onAddDriver()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Ligne de conducteur dans la liste
private struct DriverListRow: View {
    let driver: DriverRecord
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Avatar avec initiales
                ZStack {
                    Circle()
                        .fill(isSelected ? SNCFColors.ceruleen : SNCFColors.ceruleen.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Text(driver.initials)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : SNCFColors.ceruleen)
                }
                
                // Infos conducteur
                VStack(alignment: .leading, spacing: 4) {
                    Text(driver.fullName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 8) {
                        if let cpNumber = driver.cpNumber, !cpNumber.isEmpty {
                            Text("CP: \(cpNumber)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let start = driver.triennialStart {
                            let remaining = daysRemaining(from: start)
                            HStack(spacing: 2) {
                                Image(systemName: remaining <= 0 ? "exclamationmark.triangle.fill" : "clock")
                                    .font(.caption2)
                                Text(remaining <= 0 ? "Échue" : "\(remaining)j")
                                    .font(.caption)
                            }
                            .foregroundStyle(remainingColor(remaining))
                        }
                    }
                }
                
                Spacer()
                
                // Coche si sélectionné
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(SNCFColors.ceruleen)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // Calcul des jours restants (3 ans - 1 jour)
    private func daysRemaining(from start: Date) -> Int {
        var endDate = Calendar.current.date(byAdding: .year, value: 3, to: start) ?? start
        endDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate) ?? endDate
        
        let days = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return days
    }
    
    // Couleur selon urgence
    private func remainingColor(_ days: Int) -> Color {
        if days <= 0 { return .red }
        if days <= 90 { return .orange }
        return .green
    }
}

