//
//  DashboardView.swift
//  RailSkills
//
//  Vue de dashboard améliorée avec vision complète de l'équipe pour le CTT
//

import SwiftUI
import Charts

/// Vue de dashboard affichant les statistiques globales et alertes pour le CTT
struct DashboardView: View {
    @ObservedObject var vm: ViewModel
    @State private var selectedTimeFilter: TimeFilter = .all
    @State private var showingDriverDetail: DriverRecord?
    @State private var animateCards = false
    @State private var sortOption: SortOption = .timeRemaining
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var lastSyncDate: Date?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Indicateur de synchronisation
                syncIndicator
                
                // Section 3: Graphique de répartition globale
                teamDistributionChart
                
                // Section 5: Progression par conducteur
                driversProgressSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Tableau de bord")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateCards = true
            }
            updateLastSyncDate()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChecklistDownloaded"))) { _ in
            updateLastSyncDate()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DriversDownloaded"))) { _ in
            updateLastSyncDate()
        }
        .sheet(item: $showingDriverDetail) { driver in
            NavigationStack {
                DriverDetailSheet(driver: driver, vm: vm)
            }
        }
    }

    // MARK: - Sync Indicator
    
    private var syncIndicator: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: vm.store.isSyncing ? "arrow.triangle.2.circlepath" : "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(vm.store.isSyncing ? .blue : .green)
                    .rotationEffect(.degrees(vm.store.isSyncing ? 360 : 0))
                    .animation(vm.store.isSyncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: vm.store.isSyncing)
                
                if vm.store.isSyncing {
                    Text(vm.store.syncStatusMessage.isEmpty ? "Synchronisation en cours..." : vm.store.syncStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let lastSync = lastSyncDate {
                    Text("Dernière synchro : \(timeAgo(from: lastSync))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("En attente de synchronisation...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Barre de progression
            if vm.store.isSyncing {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Fond de la barre
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        // Progression
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * vm.store.syncProgress, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: vm.store.syncProgress)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.secondarySystemBackground).opacity(0.5))
        )
    }
    
    private func updateLastSyncDate() {
        lastSyncDate = SharePointSyncService.shared.lastSyncDate
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        
        if seconds < 60 {
            return "il y a \(seconds)s"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "il y a \(minutes)min"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "il y a \(hours)h"
        } else {
            let days = seconds / 86400
            return "il y a \(days)j"
        }
    }

    // MARK: - Section 3: Graphique de Répartition

    private var teamDistributionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderDashboard(title: "Répartition de l'équipe", icon: "chart.pie.fill", color: SNCFColors.parme)

            if vm.store.drivers.isEmpty {
                EmptyStateCard(
                    icon: "person.3",
                    title: "Aucun conducteur",
                    subtitle: "Ajoutez des conducteurs pour voir la répartition"
                )
            } else {
                let distribution = calculateTeamDistribution()

                HStack(spacing: 16) {
                    // Graphique en anneau
                    ZStack {
                        // Fond
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                            .frame(width: 120, height: 120)

                        // Segments
                        DistributionRingView(distribution: distribution)
                            .frame(width: 120, height: 120)

                        // Centre
                        VStack(spacing: 2) {
                            Text("\(vm.store.drivers.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("total")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Légende
                    VStack(alignment: .leading, spacing: 8) {
                        DistributionLegendRow(
                            color: SNCFColors.menthe,
                            label: "Conformes (>80%)",
                            count: distribution.conform,
                            total: vm.store.drivers.count
                        )

                        DistributionLegendRow(
                            color: SNCFColors.safran,
                            label: "En cours (50-80%)",
                            count: distribution.inProgress,
                            total: vm.store.drivers.count
                        )

                        DistributionLegendRow(
                            color: SNCFColors.corail,
                            label: "À risque (<50%)",
                            count: distribution.atRisk,
                            total: vm.store.drivers.count
                        )

                        DistributionLegendRow(
                            color: .gray,
                            label: "Non évalués",
                            count: distribution.notEvaluated,
                            total: vm.store.drivers.count
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: animateCards)
    }


    
    // MARK: - Section 5: Progression par conducteur
    
    private var driversProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeaderDashboard(title: "Suivi individuel", icon: "person.2.fill", color: SNCFColors.ceruleen)
                
                Spacer()
                
                Menu {
                    Picker("Tri", selection: $sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Label(option.rawValue, systemImage: option.icon).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                        .font(.body)
                        .foregroundStyle(SNCFColors.ceruleen)
                }
            }
            
            if vm.store.drivers.isEmpty {
                EmptyStateCard(
                    icon: "person.3",
                    title: "Aucun conducteur",
                    subtitle: "Ajoutez des conducteurs pour voir leur progression"
                )
            } else {
                // Grille adaptative : s'adapte à la largeur disponible pour éviter les colonnes "vides"
                let minCardWidth: CGFloat = (hSizeClass == .regular) ? 360 : 280
                let columns = [
                    GridItem(.adaptive(minimum: minCardWidth), spacing: 12, alignment: .top)
                ]

                LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                    ForEach(sortedDrivers) { driver in
                        DriverTriennialCard(driver: driver, checklist: vm.store.checklist)
                            .onTapGesture {
                                showingDriverDetail = driver
                            }
                    }
                }
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: animateCards)
    }

    // MARK: - Helpers & Computed Properties



    private var sortedDrivers: [DriverRecord] {
        guard let checklist = vm.store.checklist else {
            let sorted = vm.store.drivers.sorted { $0.name < $1.name }
            return deduplicatedDrivers(sorted)
        }
        
        let sorted = vm.store.drivers.sorted { d1, d2 in
            switch sortOption {
            case .name:
                return d1.name < d2.name
            case .timeRemaining:
                let calendar = Calendar.current
                let end1: Date? = d1.triennialStart.flatMap { calendar.date(byAdding: .year, value: 3, to: $0) }
                let end2: Date? = d2.triennialStart.flatMap { calendar.date(byAdding: .year, value: 3, to: $0) }
                
                // Les dates nulles à la fin
                guard let e1 = end1 else { return false }
                guard let e2 = end2 else { return true }
                
                return e1 < e2
                
            case .completion:
                let q = checklist.questions
                
                // Calcul score d1
                let k1 = d1.resolveDataKey(for: checklist)
                let m1 = d1.checklistStates[k1] ?? [:]
                let v1 = q.filter { m1[$0.id.uuidString] == 2 }.count
                let p1 = Double(v1) / max(Double(q.count), 1)
                
                // Calcul score d2
                let k2 = d2.resolveDataKey(for: checklist)
                let m2 = d2.checklistStates[k2] ?? [:]
                let v2 = q.filter { m2[$0.id.uuidString] == 2 }.count
                let p2 = Double(v2) / max(Double(q.count), 1)
                
                return p1 > p2 // Descendant
            }
        }
        
        return deduplicatedDrivers(sorted)
    }

    private func deduplicatedDrivers(_ drivers: [DriverRecord]) -> [DriverRecord] {
        var seen = Set<UUID>()
        var result: [DriverRecord] = []
        result.reserveCapacity(drivers.count)
        for driver in drivers {
            if seen.insert(driver.id).inserted {
                result.append(driver)
            }
        }
        return result
    }

    private var conformDriversCount: Int {
        guard let checklist = vm.store.checklist else { return 0 }
        let questions = checklist.questions
        guard !questions.isEmpty else { return 0 }

        return vm.store.drivers.filter { driver in
            let key = driver.resolveDataKey(for: checklist)
            let map = driver.checklistStates[key] ?? [:]
            let validated = questions.filter { map[$0.id.uuidString] == 2 }.count
            let progress = Double(validated) / Double(questions.count)
            return progress >= 0.8
        }.count
    }



    private func calculateTeamDistribution() -> TeamDistribution {
        guard let checklist = vm.store.checklist else {
            return TeamDistribution(conform: 0, inProgress: 0, atRisk: 0, notEvaluated: vm.store.drivers.count)
        }

        let questions = checklist.questions
        guard !questions.isEmpty else {
            return TeamDistribution(conform: 0, inProgress: 0, atRisk: 0, notEvaluated: vm.store.drivers.count)
        }

        var conform = 0
        var inProgress = 0
        var atRisk = 0
        var notEvaluated = 0

        for driver in vm.store.drivers {
            let key = driver.resolveDataKey(for: checklist)
            let map = driver.checklistStates[key] ?? [:]

            if map.isEmpty {
                notEvaluated += 1
                continue
            }

            let validated = questions.filter { map[$0.id.uuidString] == 2 }.count
            let progress = Double(validated) / Double(questions.count)

            if progress >= 0.8 {
                conform += 1
            } else if progress >= 0.5 {
                inProgress += 1
            } else {
                atRisk += 1
            }
        }

        return TeamDistribution(conform: conform, inProgress: inProgress, atRisk: atRisk, notEvaluated: notEvaluated)
    }

}

// MARK: - Supporting Types

/// Filtre temporel pour les statistiques du tableau de bord
enum TimeFilter: String, CaseIterable, Identifiable, Hashable {
    case all = "Tous"
    case week = "7 jours"
    case month = "30 jours"
    case year = "12 mois"

    var id: String { rawValue }
}

enum SortOption: String, CaseIterable, Identifiable {
    case name = "Nom"
    case timeRemaining = "Temps restant"
    case completion = "Progression"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .name: return "textformat"
        case .timeRemaining: return "clock"
        case .completion: return "chart.bar"
        }
    }
}

struct TeamDistribution {
    let conform: Int
    let inProgress: Int
    let atRisk: Int
    let notEvaluated: Int
}



// MARK: - Component Views

struct SectionHeaderDashboard: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }
}



struct EmptyStateCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.5))

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

struct DistributionRingView: View {
    let distribution: TeamDistribution

    var body: some View {
        let total = distribution.conform + distribution.inProgress + distribution.atRisk + distribution.notEvaluated
        guard total > 0 else {
            return AnyView(EmptyView())
        }

        let conformAngle = Double(distribution.conform) / Double(total) * 360
        let inProgressAngle = Double(distribution.inProgress) / Double(total) * 360
        let atRiskAngle = Double(distribution.atRisk) / Double(total) * 360

        return AnyView(
            ZStack {
                // Conform segment
                RingSegment(startAngle: 0, endAngle: conformAngle, color: SNCFColors.menthe)

                // In Progress segment
                RingSegment(startAngle: conformAngle, endAngle: conformAngle + inProgressAngle, color: SNCFColors.safran)

                // At Risk segment
                RingSegment(startAngle: conformAngle + inProgressAngle, endAngle: conformAngle + inProgressAngle + atRiskAngle, color: SNCFColors.corail)

                // Not Evaluated segment
                RingSegment(startAngle: conformAngle + inProgressAngle + atRiskAngle, endAngle: 360, color: .gray.opacity(0.3))
            }
        )
    }
}

struct RingSegment: View {
    let startAngle: Double
    let endAngle: Double
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let lineWidth: CGFloat = 20

            Path { path in
                path.addArc(
                    center: CGPoint(x: size / 2, y: size / 2),
                    radius: (size - lineWidth) / 2,
                    startAngle: .degrees(startAngle - 90),
                    endAngle: .degrees(endAngle - 90),
                    clockwise: false
                )
            }
            .stroke(color, lineWidth: lineWidth)
        }
    }
}

struct DistributionLegendRow: View {
    let color: Color
    let label: String
    let count: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            if total > 0 {
                Text("(\(Int(Double(count) / Double(total) * 100))%)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

struct DriverDetailSheet: View {
    let driver: DriverRecord
    @ObservedObject var vm: ViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // En-tête
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(SNCFColors.ceruleen.opacity(0.2))
                            .frame(width: 80, height: 80)

                        Text(driver.initials)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(SNCFColors.ceruleen)
                    }

                    Text(driver.fullName)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let cpNumber = driver.cpNumber {
                        Text("N° CP: \(cpNumber)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 20)

                // Infos triennales
                if let triennialStart = driver.triennialStart {
                    let calendar = Calendar.current
                    let endDate = calendar.date(byAdding: .year, value: 3, to: triennialStart) ?? triennialStart
                    let daysRemaining = calendar.dateComponents([.day], from: Date(), to: endDate).day ?? 0

                    VStack(spacing: 8) {
                        HStack {
                            Text("Période triennale")
                                .font(.headline)
                            Spacer()
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Début")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(triennialStart, style: .date)
                                    .font(.subheadline)
                            }

                            Spacer()

                            VStack(alignment: .center) {
                                Text("Restant")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(daysRemaining)j")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(daysRemaining <= 30 ? .red : (daysRemaining <= 90 ? SNCFColors.safran : SNCFColors.menthe))
                            }

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text("Fin")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(endDate, style: .date)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                }

                // Progression
                if let checklist = vm.store.checklist {
                    let questions = checklist.questions
                    let key = driver.resolveDataKey(for: checklist)
                    let map = driver.checklistStates[key] ?? [:]
                    let validated = questions.filter { map[$0.id.uuidString] == 2 }.count
                    let partial = questions.filter { map[$0.id.uuidString] == 1 }.count
                    let notValidated = questions.filter { map[$0.id.uuidString] == 0 || map[$0.id.uuidString] == nil }.count
                    let notApplicable = questions.filter { map[$0.id.uuidString] == 3 }.count
                    let progress = questions.isEmpty ? 0 : Double(validated) / Double(questions.count)

                    VStack(spacing: 12) {
                        HStack {
                            Text("Progression")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(progress >= 0.8 ? SNCFColors.menthe : (progress >= 0.5 ? SNCFColors.safran : SNCFColors.corail))
                        }

                        ProgressView(value: progress)
                            .tint(progress >= 0.8 ? SNCFColors.menthe : (progress >= 0.5 ? SNCFColors.safran : SNCFColors.corail))

                        HStack(spacing: 16) {
                            StatBadge(label: "Validées", value: validated, color: SNCFColors.menthe)
                            StatBadge(label: "Partielles", value: partial, color: SNCFColors.safran)
                            StatBadge(label: "Non validées", value: notValidated, color: SNCFColors.corail)
                            StatBadge(label: "N/A", value: notApplicable, color: .gray)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                }

                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("Détail conducteur")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Fermer") {
                    dismiss()
                }
            }
        }
    }
}

struct StatBadge: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.headline)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DashboardView(vm: ViewModel())
    }
}
