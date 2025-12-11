//
//  ProgressHeaderView.swift
//  RailSkills
//
//  Vue de l'en-tête avec progression globale
//

import SwiftUI

/// Vue d'en-tête affichant la progression globale et les informations du conducteur
struct ProgressHeaderView: View {
    let progress: Double
    let checklist: Checklist?
    let driver: DriverRecord?
    
    var body: some View {
        if let checklist = checklist, !checklist.items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                progressRow
                
                if let driver = driver {
                    triennialInfo(driver: driver)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel(accessibilityLabel)
        }
    }
    
    private var progressRow: some View {
        HStack(spacing: 18) {
            CircularProgressView(progress: progress, size: 56)
                .accessibilityLabel("Progression globale")
                .accessibilityValue("\(Int(progress * 100)) pour cent")
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Progression")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.headline)
                        .foregroundStyle(Color.forState(2))
                }
                
                ProgressView(value: progress)
                    .tint(Color.forState(2))
                    .animation(.easeInOut(duration: 0.35), value: progress)
                    .accessibilityValue("\(Int(progress * 100)) pour cent complété")
            }
        }
    }
    
    @ViewBuilder
    private func triennialInfo(driver: DriverRecord) -> some View {
        if let start = driver.triennialStart,
           let due = Calendar.current.date(byAdding: .year, value: 3, to: start) {
            let remaining = Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0
            
            HStack {
                Text("Échéance triennale:")
                Spacer()
                Text(DateFormatHelper.formatDate(due))
                    .foregroundStyle(remaining <= 0 ? SNCFColors.corail : (remaining <= 90 ? SNCFColors.safran : .primary))
            }
            .font(.subheadline)
            .accessibilityLabel("Échéance triennale: \(DateFormatHelper.formatDate(due)), \(remaining <= 0 ? "échu depuis \(-remaining) jours" : "\(remaining) jours restants")")
        }
    }
    
    private var accessibilityLabel: String {
        var label = "Progression globale: \(Int(progress * 100)) pour cent"
        if let driver = driver,
           let start = driver.triennialStart,
           let due = Calendar.current.date(byAdding: .year, value: 3, to: start) {
            let remaining = Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0
            label += ". Échéance triennale: \(DateFormatHelper.formatDate(due))"
            if remaining <= 0 {
                label += ", échu depuis \(-remaining) jours"
            } else if remaining <= 90 {
                label += ", \(remaining) jours restants, attention"
            } else {
                label += ", \(remaining) jours restants"
            }
        }
        return label
    }
}

