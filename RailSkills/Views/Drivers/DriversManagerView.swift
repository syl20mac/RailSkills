//
//  DriversManagerView.swift
//  RailSkills
//
//  Vue de gestion des conducteurs
//

import SwiftUI

/// Vue de gestion des conducteurs (liste, édition, suppression)
struct DriversManagerView: View {
    enum ActiveSheet: Identifiable {
        case addDriver
        case editDriver(Int)
        case importExcel
        case importSharePoint
        
        var id: String {
            switch self {
            case .addDriver: return "addDriver"
            case .editDriver(let index): return "editDriver-\(index)"
            case .importExcel: return "importExcel"
            case .importSharePoint: return "importSharePoint"
            }
        }
    }

    @ObservedObject var vm: ViewModel
    @State private var currentSheet: ActiveSheet?
    @State private var selectedDriverIndex: Int?
    @State private var showingDeleteConfirmation = false
    @State private var pendingDeletionIDs: [UUID] = []
    @State private var searchText: String = ""
    
    /// Conducteurs filtrés par la recherche et triés par urgence
    private var filteredDrivers: [DriverRecord] {
        let sorted = vm.store.drivers.sorted(by: { urgency(of: $0) < urgency(of: $1) })
        
        if searchText.isEmpty {
            return sorted
        } else {
            return sorted.filter { driver in
                driver.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        List {
            // Afficher un message si aucun conducteur et proposer l'import
            if filteredDrivers.isEmpty && !searchText.isEmpty {
                Text("Aucun conducteur trouvé")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowSeparator(.hidden)
            } else if filteredDrivers.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.3")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Aucun conducteur")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Importez vos conducteurs depuis SharePoint ou Excel")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Button {
                            Logger.debug("Bouton Import SharePoint cliqué", category: "DriversManager")
                            currentSheet = .importSharePoint
                        } label: {
                            HStack {
                                Image(systemName: "tray.and.arrow.down")
                                Text("Importer depuis SharePoint")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.borderless)
                        
                        Button {
                            Logger.debug("Bouton Import Excel cliqué", category: "DriversManager")
                            currentSheet = .importExcel
                        } label: {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                Text("Importer depuis Excel")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .foregroundStyle(.orange)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowSeparator(.hidden)
            }
            
            ForEach(filteredDrivers, id: \.id) { driver in
                if let index = vm.store.drivers.firstIndex(where: { $0.id == driver.id }) {
                    NavigationLink {
                        driverDetailView(for: index)
                    } label: {
                        driverRow(for: index)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            currentSheet = .editDriver(index)
                        } label: {
                            Label("Éditer", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
            .onDelete { offsets in
                pendingDeletionIDs = offsets.compactMap { index in
                    guard filteredDrivers.indices.contains(index) else { return nil }
                    return filteredDrivers[index].id
                }
                if !pendingDeletionIDs.isEmpty {
                    showingDeleteConfirmation = true
                }
            }
        }
        .searchable(text: $searchText, prompt: "Rechercher un conducteur")
        .navigationTitle("Conducteurs")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        currentSheet = .addDriver
                    } label: {
                        Label("Ajouter un conducteur", systemImage: "person.badge.plus")
                    }
                    
                    Button {
                        currentSheet = .importExcel
                    } label: {
                        Label("Importer depuis Excel", systemImage: "doc.badge.plus")
                    }
                    
                    Button {
                        currentSheet = .importSharePoint
                    } label: {
                        Label("Importer depuis SharePoint", systemImage: "tray.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "plus.circle")
                }
            }
        }
        .sheet(item: $currentSheet) { sheet in
            switch sheet {
            case .addDriver:
                AddDriverSheet(vm: vm)
            case .editDriver(let index):
                if vm.store.drivers.indices.contains(index) {
                    NavigationStack {
                        quickEditForm(for: index)
                    }
                    .presentationDetents([.medium, .large])
                }
            case .importExcel:
                ImportDriversExcelView(vm: vm)
            case .importSharePoint:
                ImportDriversFromSharePointView(vm: vm, isPresented: Binding(
                    get: { currentSheet?.id == ActiveSheet.importSharePoint.id },
                    set: { if !$0 { currentSheet = nil } }
                ))
            }
        }
        // Alerte de confirmation avant de supprimer un ou plusieurs conducteurs
        .alert("Confirmer la suppression", isPresented: $showingDeleteConfirmation) {
            Button("Annuler", role: .cancel) {
                pendingDeletionIDs.removeAll()
            }
            Button("Supprimer", role: .destructive) {
                guard !pendingDeletionIDs.isEmpty else { return }
                let idsToRemove = Set(pendingDeletionIDs)
                pendingDeletionIDs.removeAll()
                vm.store.drivers.removeAll { driver in
                    idsToRemove.contains(driver.id)
                }
                Logger.warning("Conducteur(s) supprimé(s) après confirmation: \(idsToRemove.count)", category: "DriversManager")
                // Ajuster l'index sélectionné si nécessaire après suppression
                if vm.store.drivers.isEmpty {
                    vm.selectedDriverIndex = 0
                } else if !vm.store.drivers.indices.contains(vm.selectedDriverIndex) {
                    // Si l'index est invalide, sélectionner le dernier conducteur disponible
                    vm.selectedDriverIndex = max(0, vm.store.drivers.count - 1)
                }
            }
        } message: {
            if pendingDeletionIDs.count > 1 {
                Text("Voulez-vous supprimer \(pendingDeletionIDs.count) conducteurs ? Cette action est irréversible.")
            } else {
                if let driver = vm.store.drivers.first(where: { $0.id == pendingDeletionIDs.first }) {
                    Text("Voulez-vous supprimer le conducteur \"\(driver.name)\" ? Cette action est irréversible.")
                } else {
                    Text("Voulez-vous supprimer ce conducteur ? Cette action est irréversible.")
                }
            }
        }
    }
    
    private func driverRow(for index: Int) -> some View {
        HStack(spacing: 12) {
            // Indicateur visuel coloré sur le bord gauche
            if let start = vm.store.drivers[index].triennialStart {
                let days = daysRemaining(from: start)
                Rectangle()
                    .fill(statusColor(forDays: days))
                    .frame(width: 4)
                    .cornerRadius(2)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(vm.store.drivers[index].fullName)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                // Afficher le numéro de CP s'il existe
                if let cpNumber = vm.store.drivers[index].cpNumber, !cpNumber.isEmpty {
                    Text("CP: \(cpNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let start = vm.store.drivers[index].triennialStart {
                    let days = daysRemaining(from: start)
                    HStack(spacing: 6) {
                        Image(systemName: statusSymbol(forDays: days))
                            .font(.caption)
                        Text(remainingText(forDays: days))
                            .font(.subheadline)
                    }
                    .foregroundStyle(statusColor(forDays: days))
                }
            }
            
            Spacer()
            
            // Badge avec nombre de jours (plus visible et accessible)
            if let start = vm.store.drivers[index].triennialStart {
                let days = daysRemaining(from: start)
                if days != Int.max {
                    Text("\(days)j")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(statusColor(forDays: days))
                        )
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .contentShape(Rectangle())
    }
    
    private func driverDetailView(for index: Int) -> some View {
        Form {
            Section {
                TextField("Nom *", text: Binding(
                    get: { vm.store.drivers[index].name },
                    set: { 
                        let trimmedName = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                        if ValidationService.validateDriverName(trimmedName) {
                            vm.store.drivers[index].name = trimmedName
                        } else {
                            Logger.warning("Nom de conducteur invalide lors de l'édition: \(trimmedName)", category: "DriversManager")
                        }
                    }
                ))
                
                TextField("Prénom", text: Binding(
                    get: { vm.store.drivers[index].firstName ?? "" },
                    set: { 
                        let trimmedFirstName = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                        vm.store.drivers[index].firstName = trimmedFirstName.isEmpty ? nil : trimmedFirstName
                    }
                ))
                
                TextField("Numéro de CP", text: Binding(
                    get: { vm.store.drivers[index].cpNumber ?? "" },
                    set: { 
                        let trimmedCpNumber = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                        vm.store.drivers[index].cpNumber = trimmedCpNumber.isEmpty ? nil : trimmedCpNumber
                    }
                ))
                
                DatePicker(
                    "Début triennale",
                    selection: Binding(
                        get: { vm.store.drivers[index].triennialStart ?? Date() },
                        set: { vm.store.drivers[index].triennialStart = $0 }
                    ),
                    displayedComponents: .date
                )
            } header: {
                Text("Informations")
            } footer: {
                Text("Les champs marqués d'un astérisque (*) sont obligatoires.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .navigationTitle(vm.store.drivers[index].fullName)
    }
    
    private func urgency(of driver: DriverRecord) -> Int {
        if let start = driver.triennialStart {
            return daysRemaining(from: start)
        }
        return Int.max
    }
    
    private func urgency(of index: Int) -> Int {
        if index < vm.store.drivers.count, let start = vm.store.drivers[index].triennialStart {
            return daysRemaining(from: start)
        }
        return Int.max
    }
    
    private func daysRemaining(from start: Date) -> Int {
        guard let due = vm.nextDueDate(from: start) else { return Int.max }
        let cal = Calendar.current
        let startDay = cal.startOfDay(for: Date())
        let endDay = cal.startOfDay(for: due)
        return cal.dateComponents([.day], from: startDay, to: endDay).day ?? 0
    }
    
    private func statusColor(forDays days: Int) -> Color {
        switch days {
        case ...AppConstants.Date.criticalDaysThreshold: return .red
        case 1...AppConstants.Date.warningDaysThreshold: return .orange
        default: return .green
        }
    }
    
    private func statusSymbol(forDays days: Int) -> String {
        switch days {
        case ...AppConstants.Date.criticalDaysThreshold: return "exclamationmark.triangle.fill"
        case 1...AppConstants.Date.warningDaysThreshold: return "exclamationmark.triangle"
        default: return "checkmark.circle"
        }
    }
    
    private func remainingText(forDays days: Int) -> String {
        if days <= 0 { return "Échu depuis \(-days) j" }
        return "Restant : \(days) j"
    }
    
    /// Formulaire d'édition rapide
    private func quickEditForm(for index: Int) -> some View {
        Form {
            Section {
                TextField("Nom", text: Binding(
                    get: { vm.store.drivers[index].name },
                    set: { 
                        let trimmedName = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                        if ValidationService.validateDriverName(trimmedName) {
                            vm.store.drivers[index].name = trimmedName
                        } else {
                            Logger.warning("Nom de conducteur invalide lors de l'édition: \(trimmedName)", category: "DriversManager")
                        }
                    }
                ))
                .font(.title3)
                
                DatePicker(
                    "Début triennale",
                    selection: Binding(
                        get: { vm.store.drivers[index].triennialStart ?? Date() },
                        set: { vm.store.drivers[index].triennialStart = $0 }
                    ),
                    displayedComponents: .date
                )
            } header: {
                Text("Informations")
            }
            
            Section {
                if let start = vm.store.drivers[index].triennialStart {
                    let days = daysRemaining(from: start)
                    HStack {
                        Text("Échéance")
                            .foregroundStyle(.primary.opacity(0.7))
                        Spacer()
                        Text(remainingText(forDays: days))
                            .foregroundStyle(statusColor(forDays: days))
                            .fontWeight(.semibold)
                    }
                }
            } header: {
                Text("Statut")
            }
        }
        .navigationTitle("Édition rapide")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("OK") {
                    currentSheet = nil
                }
                .fontWeight(.semibold)
            }
        }
    }
}

