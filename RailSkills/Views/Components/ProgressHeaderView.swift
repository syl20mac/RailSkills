//
//  ProgressHeaderView.swift
//  RailSkills
//
//  Vue de l'en-tête avec progression globale - Version améliorée UX
//

import SwiftUI

/// Vue d'en-tête affichant la progression globale et les informations du conducteur
struct ProgressHeaderView: View {
    let progress: Double
    let checklist: Checklist?
    let driver: DriverRecord?
    
    // Animation d'entrée
    @State private var isAnimating = false
    
    var body: some View {
        if let checklist = checklist, !checklist.items.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                progressRow
                
                if let driver = driver {
                    triennialInfo(driver: driver)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel(accessibilityLabel)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isAnimating = true
                }
            }
        }
    }
    
    private var progressRow: some View {
        HStack(spacing: 20) {
            // Utilisation du nouveau composant EnhancedCircularProgressView
            EnhancedCircularProgressView(progress: progress, size: 64)
                .accessibilityLabel("Progression globale")
                .accessibilityValue("\(Int(progress * 100)) pour cent")
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progression")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(progressColor)
                }
                
                // Barre de progression améliorée avec dégradé
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Fond
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                        
                        // Progression avec dégradé
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: progressGradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                    }
                }
                .frame(height: 8)
                .accessibilityValue("\(Int(progress * 100)) pour cent complété")
            }
        }
    }
    
    // Couleur selon la progression
    private var progressColor: Color {
        if progress >= 1.0 {
            return SNCFColors.menthe
        } else if progress >= 0.7 {
            return SNCFColors.ceruleen
        } else if progress >= 0.4 {
            return SNCFColors.safran
        } else {
            return SNCFColors.corail
        }
    }
    
    // Dégradé selon la progression
    private var progressGradientColors: [Color] {
        if progress >= 1.0 {
            return [SNCFColors.menthe, SNCFColors.vertEau]
        } else if progress >= 0.7 {
            return [SNCFColors.ceruleen, SNCFColors.bleuHorizon]
        } else if progress >= 0.4 {
            return [SNCFColors.safran, SNCFColors.ambre]
        } else {
            return [SNCFColors.corail, SNCFColors.peche]
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

