//
//  DashboardView.swift
//  RailSkills
//
//  Vue de dashboard avec statistiques globales
//

import SwiftUI

/// Filtre pour les échéances affichées
enum DeadlineFilter: String, CaseIterable {
    case all = "Toutes"
    case critical = "Critiques"
    case warning = "À surveiller"
    case ok = "Normales"
}

/// Vue de dashboard affichant les statistiques globales de l'application
struct DashboardView: View {
    @ObservedObject var vm: ViewModel
    @State private var deadlineFilter: DeadlineFilter = .all
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                overviewCards
                driversStats
                triennialCharts
                progressBreakdown
            }
            .padding()
        }
        .navigationTitle("Tableau de bord")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Cartes de vue d'ensemble
    private var overviewCards: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                statCard(
                    title: "Conducteurs",
                    value: "\(vm.store.drivers.count)",
                    icon: "person.3.fill",
                    color: SNCFColors.ceruleen
                )
                
                statCard(
                    title: "Questions totales",
                    value: "\(vm.store.checklist?.questions.count ?? 0)",
                    icon: "list.bullet.rectangle.fill",
                    color: SNCFColors.menthe
                )
            }
            
            if !vm.store.drivers.isEmpty {
                statCard(
                    title: "Progression moyenne",
                    value: "\(Int(averageProgress * 100))%",
                    icon: "chart.bar.fill",
                    color: SNCFColors.safran,
                    fullWidth: true
                )
            }
        }
    }
    
    // MARK: - Statistiques des conducteurs
    private var driversStats: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                // Header avec filtre
                HStack {
                    Text("Échéances triennales")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Filtre picker
                    Menu {
                        ForEach(DeadlineFilter.allCases, id: \.self) { filter in
                            Button {
                                withAnimation {
                                    deadlineFilter = filter
                                }
                            } label: {
                                HStack {
                                    Text(filter.rawValue)
                                    if deadlineFilter == filter {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(deadlineFilter.rawValue)
                                .font(.subheadline)
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.body)
                        }
                        .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal)
                
                if filteredDeadlines.isEmpty {
                    Text("Aucune échéance dans cette catégorie")
                        .font(.subheadline)
                        .foregroundStyle(.primary.opacity(0.7))
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                } else {
                    ForEach(filteredDeadlines.prefix(10)) { driver in
                        deadlineRow(for: driver)
                    }
                }
            }
        } header: {
            Text("Conducteurs")
        }
    }
    
    // MARK: - Graphiques triennaux
    private var triennialCharts: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("Progression triennale")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(driversWithTriennialStart.count) conducteur(s)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                // Graphiques par conducteur
                if driversWithTriennialStart.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        
                        Text("Aucun graphique disponible")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("Définissez une date de début triennale pour les conducteurs")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(driversWithTriennialStart) { driver in
                        TriennialChartView(
                            driver: driver,
                            checklist: vm.store.checklist
                        )
                    }
                }
            }
        } header: {
            Text("Graphiques triennaux")
        }
    }
    
    // MARK: - Répartition de la progression
    private var progressBreakdown: some View {
        Section {
            if let checklist = vm.store.checklist, !checklist.questions.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    if let selectedDriver = selectedDriver {
                        let stats = calculateStats(for: selectedDriver, checklist: checklist)
                        
                        progressStatRow(
                            title: "Validées",
                            count: stats.validated,
                            total: stats.total,
                            color: SNCFColors.menthe
                        )
                        
                        progressStatRow(
                            title: "Partielles",
                            count: stats.partial,
                            total: stats.total,
                            color: SNCFColors.safran
                        )
                        
                        progressStatRow(
                            title: "Non validées",
                            count: stats.notValidated,
                            total: stats.total,
                            color: SNCFColors.corail
                        )
                        
                        progressStatRow(
                            title: "Non applicables",
                            count: stats.notApplicable,
                            total: stats.total,
                            color: .gray
                        )
                    } else {
                        Text("Sélectionnez un conducteur pour voir les statistiques détaillées")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
        } header: {
            Text("Répartition de la progression")
        }
    }
    
    // MARK: - Helpers
    
    private var averageProgress: Double {
        guard !vm.store.drivers.isEmpty, let checklist = vm.store.checklist else { return 0 }
        let questions = checklist.questions
        
        var totalProgress: Double = 0
        var validDrivers = 0
        
        for driver in vm.store.drivers {
            let key = checklist.title
            let map = driver.checklistStates[key] ?? [:]
            let validated = questions.filter { map[$0.id] == 2 }.count
            if !questions.isEmpty {
                totalProgress += Double(validated) / Double(questions.count)
                validDrivers += 1
            }
        }
        
        return validDrivers > 0 ? totalProgress / Double(validDrivers) : 0
    }
    
    private var driversWithUpcomingDeadlines: [DriverWithDeadline] {
        var drivers: [DriverWithDeadline] = []
        
        for driver in vm.store.drivers {
            if let start = driver.triennialStart,
               let due = Calendar.current.date(byAdding: .year, value: 3, to: start) {
                let remaining = Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0
                drivers.append(DriverWithDeadline(
                    driver: driver,
                    deadline: due,
                    daysRemaining: remaining
                ))
            }
        }
        
        return drivers.sorted { $0.daysRemaining < $1.daysRemaining }
    }
    
    /// Conducteurs filtrés selon le filtre sélectionné
    private var filteredDeadlines: [DriverWithDeadline] {
        let all = driversWithUpcomingDeadlines
        
        switch deadlineFilter {
        case .all:
            return all
        case .critical:
            return all.filter { $0.daysRemaining <= 0 }
        case .warning:
            return all.filter { $0.daysRemaining > 0 && $0.daysRemaining <= 90 }
        case .ok:
            return all.filter { $0.daysRemaining > 90 }
        }
    }
    
    private var selectedDriver: DriverRecord? {
        guard vm.store.drivers.indices.contains(vm.selectedDriverIndex) else { return nil }
        return vm.store.drivers[vm.selectedDriverIndex]
    }
    
    /// Liste des conducteurs ayant une date de début triennale
    private var driversWithTriennialStart: [DriverRecord] {
        vm.store.drivers.filter { $0.triennialStart != nil }
            .sorted { driver1, driver2 in
                // Trier par date de début triennale (plus récent en premier)
                guard let date1 = driver1.triennialStart,
                      let date2 = driver2.triennialStart else {
                    return false
                }
                return date1 > date2
            }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color, fullWidth: Bool = false) -> some View {
        VStack(spacing: 16) {
            // Icône plus grande avec background coloré
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.callout)
                    .foregroundStyle(.primary.opacity(0.7))
            }
        }
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .frame(height: 140)
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
    
    private func deadlineRow(for driverWithDeadline: DriverWithDeadline) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(driverWithDeadline.driver.name)
                    .font(.headline)
                
                Text("Échéance: \(DateFormatHelper.formatDate(driverWithDeadline.deadline))")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("\(driverWithDeadline.daysRemaining)j")
                    .font(.headline)
                    .foregroundStyle(deadlineColor(for: driverWithDeadline.daysRemaining))
                
                Image(systemName: deadlineIcon(for: driverWithDeadline.daysRemaining))
                    .foregroundStyle(deadlineColor(for: driverWithDeadline.daysRemaining))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
    
    private func deadlineColor(for days: Int) -> Color {
        if days <= 0 { return SNCFColors.corail }
        if days <= 90 { return SNCFColors.safran }
        return SNCFColors.menthe
    }
    
    private func deadlineIcon(for days: Int) -> String {
        if days <= 0 { return "exclamationmark.triangle.fill" }
        if days <= 90 { return "exclamationmark.triangle" }
        return "checkmark.circle.fill"
    }
    
    private func progressStatRow(title: String, count: Int, total: Int, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("\(count)/\(total)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if total > 0 {
                    let percentage = Double(count) / Double(total)
                    Text("(\(Int(percentage * 100))%)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ProgressView(value: percentage)
                        .frame(width: 100)
                        .tint(color)
                }
            }
        }
    }
    
    private func calculateStats(for driver: DriverRecord, checklist: Checklist) -> ProgressStats {
        let questions = checklist.questions
        let key = checklist.title
        let map = driver.checklistStates[key] ?? [:]
        
        return ProgressStats(
            total: questions.count,
            validated: questions.filter { map[$0.id] == 2 }.count,
            partial: questions.filter { map[$0.id] == 1 }.count,
            notValidated: questions.filter { map[$0.id] == 0 }.count,
            notApplicable: questions.filter { map[$0.id] == 3 }.count
        )
    }
}

// MARK: - Supporting Types

struct DriverWithDeadline: Identifiable {
    let id = UUID()
    let driver: DriverRecord
    let deadline: Date
    let daysRemaining: Int
}

struct ProgressStats {
    let total: Int
    let validated: Int
    let partial: Int
    let notValidated: Int
    let notApplicable: Int
}

