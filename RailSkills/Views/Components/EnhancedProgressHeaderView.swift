//
//  EnhancedProgressHeaderView.swift
//  RailSkills
//
//  Header de progression moderne avec design amélioré
//

import SwiftUI

/// En-tête de progression moderne avec avatar, stats et progression circulaire
struct EnhancedProgressHeaderView: View {
    let progress: (completed: Int, total: Int, ratio: Double)
    let checklist: Checklist?
    let driver: DriverRecord?
    
    @State private var animateGradient = false
    
    var body: some View {
        ModernCard(elevated: true) {
            VStack(spacing: 20) {
                // En-tête avec conducteur
                HStack(alignment: .center, spacing: 16) {
                    // Avatar avec initiales
                    if let driver = driver {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        SNCFColors.ceruleen,
                                        SNCFColors.lavande
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text(driver.initials)
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                            )
                            .shadow(color: SNCFColors.ceruleen.opacity(0.3), radius: 8)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if let driver = driver {
                            Text(driver.fullName)
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                            
                            Text("Évaluation triennale")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Aucun conducteur sélectionné")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Badge de progression circulaire
                    CircularProgressView(
                        progress: progress.ratio,
                        lineWidth: 8,
                        size: 60
                    )
                }
                
                // Barre de progression principale
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Progression globale")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(progress.completed)/\(progress.total)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                    }
                    
                    ModernProgressBar(
                        progress: progress.ratio,
                        height: 16,
                        showPercentage: false,
                        accentColor: progressColor
                    )
                }
                
                // Stats rapides
                HStack(spacing: 16) {
                    StatPill(
                        icon: "checkmark.circle.fill",
                        value: "\(progress.completed)",
                        label: "Validés",
                        color: SNCFColors.menthe
                    )
                    
                    StatPill(
                        icon: "circle.fill",
                        value: "\(progress.total - progress.completed)",
                        label: "Restants",
                        color: SNCFColors.bleuHorizon
                    )
                    
                    if progress.ratio >= 1.0 {
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .foregroundColor(SNCFColors.safran)
                            Text("Complet !")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(SNCFColors.menthe)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(SNCFColors.menthe.opacity(0.15))
                        )
                    }
                }
            }
        }
    }
    
    // Couleur de progression selon l'avancement
    private var progressColor: Color {
        switch progress.ratio {
        case 0..<0.33: return SNCFColors.corail
        case 0.33..<0.66: return SNCFColors.safran
        case 0.66..<1.0: return SNCFColors.ceruleen
        default: return SNCFColors.menthe
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        EnhancedProgressHeaderView(
            progress: (completed: 15, total: 30, ratio: 0.5),
            checklist: nil,
            driver: DriverRecord(name: "Jean Dupont")
        )
        
        EnhancedProgressHeaderView(
            progress: (completed: 30, total: 30, ratio: 1.0),
            checklist: nil,
            driver: DriverRecord(name: "Marie Martin")
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}


