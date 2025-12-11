//
//  TriennialChartView.swift
//  RailSkills
//
//  Composant de graphique pour visualiser la progression triennale d'un conducteur
//

import SwiftUI
import Charts

/// Vue de graphique affichant la progression triennale d'un conducteur
struct TriennialChartView: View {
    let driver: DriverRecord
    let checklist: Checklist?
    
    /// Données pour le graphique de progression triennale
    private var triennialData: TriennialChartData? {
        guard let startDate = driver.triennialStart else { return nil }
        
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .year, value: 3, to: startDate) ?? startDate
        let now = Date()
        
        // Calculer la progression dans la période triennale (0.0 à 1.0)
        let totalDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        let elapsedDays = calendar.dateComponents([.day], from: startDate, to: now).day ?? 0
        let triennialProgress = min(max(Double(elapsedDays) / Double(totalDays), 0.0), 1.0)
        
        // Calculer la progression de la checklist
        let checklistProgress = calculateChecklistProgress()
        
        return TriennialChartData(
            startDate: startDate,
            endDate: endDate,
            currentDate: now,
            triennialProgress: triennialProgress,
            checklistProgress: checklistProgress,
            daysRemaining: calendar.dateComponents([.day], from: now, to: endDate).day ?? 0
        )
    }
    
    var body: some View {
        if let data = triennialData {
            VStack(alignment: .leading, spacing: 16) {
                // En-tête avec nom du conducteur
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(driver.fullName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("Période triennale")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Indicateur de jours restants
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(data.daysRemaining)j")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(deadlineColor(for: data.daysRemaining))
                        
                        Text("restants")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Graphique de progression
                chartView(data: data)
                
                // Légende et informations
                chartLegend(data: data)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
        } else {
            // Aucune date de début triennale
            VStack(spacing: 12) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                
                Text("Aucune période triennale définie")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("Définissez une date de début pour visualiser la progression")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - Graphique
    
    @ViewBuilder
    private func chartView(data: TriennialChartData) -> some View {
        Chart {
            // Barre de fond (période triennale totale)
            BarMark(
                xStart: .value("Début", data.startDate),
                xEnd: .value("Fin", data.endDate),
                y: .value("Période", "Triennale")
            )
            .foregroundStyle(SNCFColors.bleuHorizon.opacity(0.2))
            .cornerRadius(4)
            
            // Barre de progression triennale (temps écoulé)
            BarMark(
                xStart: .value("Début", data.startDate),
                xEnd: .value("Maintenant", data.currentDate),
                y: .value("Période", "Triennale")
            )
            .foregroundStyle(SNCFColors.ceruleen)
            .cornerRadius(4)
            
            // Barre de progression checklist (superposée)
            if data.checklistProgress > 0 {
                let totalDays = Calendar.current.dateComponents([.day], from: data.startDate, to: data.endDate).day ?? 1
                let checklistEndDate = Calendar.current.date(
                    byAdding: .day,
                    value: Int(data.checklistProgress * Double(totalDays)),
                    to: data.startDate
                ) ?? data.startDate
                
                BarMark(
                    xStart: .value("Début", data.startDate),
                    xEnd: .value("Checklist", checklistEndDate),
                    y: .value("Période", "Checklist")
                )
                .foregroundStyle(SNCFColors.menthe.opacity(0.7))
                .cornerRadius(4)
            }
            
            // Marqueur de date actuelle
            RuleMark(x: .value("Maintenant", data.currentDate))
                .foregroundStyle(SNCFColors.corail)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month, count: 6)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month().year(.twoDigits))
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
            }
        }
        .frame(height: 120)
    }
    
    // MARK: - Légende
    
    @ViewBuilder
    private func chartLegend(data: TriennialChartData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Informations de dates
            HStack(spacing: 16) {
                legendItem(
                    color: SNCFColors.ceruleen,
                    label: "Début",
                    value: DateFormatHelper.formatDate(data.startDate)
                )
                
                Spacer()
                
                legendItem(
                    color: SNCFColors.corail,
                    label: "Échéance",
                    value: DateFormatHelper.formatDate(data.endDate)
                )
            }
            
            // Progression
            HStack(spacing: 16) {
                legendItem(
                    color: SNCFColors.ceruleen,
                    label: "Progression triennale",
                    value: "\(Int(data.triennialProgress * 100))%"
                )
                
                Spacer()
                
                if let checklist = checklist, !checklist.questions.isEmpty {
                    legendItem(
                        color: SNCFColors.menthe,
                        label: "Progression checklist",
                        value: "\(Int(data.checklistProgress * 100))%"
                    )
                }
            }
        }
        .font(.caption)
    }
    
    private func legendItem(color: Color, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .foregroundStyle(.secondary)
            
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - Helpers
    
    /// Calcule la progression de la checklist (0.0 à 1.0)
    private func calculateChecklistProgress() -> Double {
        guard let checklist = checklist else { return 0.0 }
        
        let questions = checklist.questions
        guard !questions.isEmpty else { return 0.0 }
        
        let key = checklist.title
        let map = driver.checklistStates[key] ?? [:]
        let validated = questions.filter { map[$0.id] == 2 }.count
        
        return Double(validated) / Double(questions.count)
    }
    
    /// Retourne la couleur selon les jours restants
    private func deadlineColor(for days: Int) -> Color {
        if days <= 0 { return SNCFColors.corail }
        if days <= 90 { return SNCFColors.safran }
        return SNCFColors.menthe
    }
}

// MARK: - Données du graphique

/// Structure de données pour le graphique triennal
struct TriennialChartData {
    let startDate: Date
    let endDate: Date
    let currentDate: Date
    let triennialProgress: Double      // 0.0 à 1.0
    let checklistProgress: Double       // 0.0 à 1.0
    let daysRemaining: Int
}

