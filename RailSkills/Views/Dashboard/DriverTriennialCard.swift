//
//  DriverTriennialCard.swift
//  RailSkills
//
//  Carte affichant la progression triennale et le taux de remplissage pour un conducteur
//

import SwiftUI

struct DriverTriennialCard: View {
    let driver: DriverRecord
    let checklist: Checklist? // Pour calculer le total des questions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // En-tête : Nom et Initiales
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(SNCFColors.ceruleen.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Text(driver.initials)
                        .font(.headline)
                        .foregroundStyle(SNCFColors.ceruleen)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(driver.fullName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let triennialStart = driver.triennialStart {
                        let endDate = Calendar.current.date(byAdding: .year, value: 3, to: triennialStart)
                        
                        Text("Fin période : \(endDate.map { DriverTriennialCard.dateFormatter.string(from: $0) } ?? "—")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Période non définie")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            // Barre 1 : Temps écoulé (Triennal)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Période Triennale", systemImage: "clock.arrow.circlepath")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(timeRemainingText)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(timeProgress >= 1.0 ? .red : .primary)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(timeBarColor)
                            .frame(width: max(0, min(geo.size.width * timeProgress, geo.size.width)), height: 8)
                    }
                }
                .frame(height: 8)
            }
            
            // Barre 2 : Remplissage (Checklist)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Avancement Questionnaire", systemImage: "list.clipboard")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(completionProgress * 100))%")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(completionColor)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(completionColor)
                            .frame(width: max(0, min(geo.size.width * completionProgress, geo.size.width)), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    // MARK: - Computed Properties
    
    /// Progression temporelle (0.0 à 1.0) sur 3 ans
    private var timeProgress: Double {
        guard let start = driver.triennialStart else { return 0 }
        let totalDuration: TimeInterval = 3 * 365 * 24 * 3600 // 3 ans approximatif
        let elapsed = Date().timeIntervalSince(start)
        return max(0, min(elapsed / totalDuration, 1.0))
    }
    
    private var timeRemainingText: String {
        guard let start = driver.triennialStart else { return "—" }
        let end = Calendar.current.date(byAdding: .year, value: 3, to: start) ?? Date()
        let days = Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0
        
        if days < 0 {
            return "Expiré (\(abs(days))j)"
        } else {
            return "\(days)j restants"
        }
    }
    
    private var timeBarColor: Color {
        // Bleu standard, devient orange puis rouge si proche de la fin
        if timeProgress > 0.95 { return .red } // <~2 mois
        if timeProgress > 0.85 { return SNCFColors.safran } // <~6 mois
        return SNCFColors.ceruleen
    }
    
    /// Progression du remplissage (0.0 à 1.0)
    private var completionProgress: Double {
        guard let checklist = checklist, !checklist.questions.isEmpty else { return 0 }
        
        let key = checklist.title
        let map = driver.checklistStates[key] ?? [:]
        
        // On compte les items validés (état 2)
        let validatedCount = checklist.questions.filter { map[$0.id.uuidString] == 2 }.count
        
        return Double(validatedCount) / Double(checklist.questions.count)
    }
    
    private var completionColor: Color {
        if completionProgress >= 0.8 { return SNCFColors.menthe }
        if completionProgress >= 0.5 { return SNCFColors.safran }
        return SNCFColors.corail
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()
}
