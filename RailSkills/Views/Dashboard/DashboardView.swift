//
//  DashboardView.swift
//  RailSkills
//
//  Vue de dashboard avec statistiques globales
//

import SwiftUI

/// Vue de dashboard affichant les statistiques globales de l'application
struct DashboardView: View {
    @ObservedObject var vm: ViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                overviewCards
                triennialCharts
                progressBreakdown
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .navigationTitle("Tableau de bord")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Cartes de vue d'ensemble
    private var overviewCards: some View {
        HStack(spacing: 12) {
            statCard(
                title: "Conducteurs",
                value: "\(vm.store.drivers.count)",
                icon: "person.3.fill",
                color: SNCFColors.ceruleen
            )
            
            if !vm.store.drivers.isEmpty {
                statCard(
                    title: "Progression moyenne",
                    value: "\(Int(averageProgress * 100))%",
                    icon: "chart.bar.fill",
                    color: SNCFColors.safran
                )
            }
        }
    }
    
    // MARK: - Graphiques triennaux
    private var triennialCharts: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text("Progression triennale")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(driversWithTriennialStart.count) conducteur(s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
                
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
                VStack(alignment: .leading, spacing: 10) {
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
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
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
        HStack(spacing: 12) {
            // Icône avec background coloré
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
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

struct ProgressStats {
    let total: Int
    let validated: Int
    let partial: Int
    let notValidated: Int
    let notApplicable: Int
}

