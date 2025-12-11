//
//  INTEGRATION_EXAMPLES.swift
//  RailSkills
//
//  Exemples d'intégration des nouveaux composants visuels
//  ⚠️ Ce fichier est à titre d'exemple uniquement
//  ⚠️ Pour compiler ce fichier, il faut remplacer ViewModel par AppViewModel
//  ⚠️ Ou simplement utiliser ces exemples comme référence sans compiler
//

#if false // ⚠️ Désactivé pour éviter les erreurs de compilation - À utiliser comme référence

import SwiftUI

// MARK: - Exemple 1 : Dashboard avec header moderne

struct ExampleDashboard: View {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header moderne avec progression
                // Note : Adapter selon votre structure de données
                let checklist = viewModel.store.checklist
                let driver = viewModel.selectedDriver
                
                if let checklist = checklist {
                    let progress = calculateProgress()
                    
                    EnhancedProgressHeaderView(
                        progress: progress,
                        checklist: checklist,
                        driver: driver
                    )
                    .padding(.horizontal)
                }
                
                // Cartes de statistiques
                HStack(spacing: 16) {
                    ModernCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Conducteurs")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(viewModel.store.drivers.count)")
                                .font(.system(.largeTitle, design: .rounded).bold())
                                .foregroundColor(SNCFColors.ceruleen)
                        }
                    }
                    
                    ModernCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Évaluations")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("12")
                                .font(.system(.largeTitle, design: .rounded).bold())
                                .foregroundColor(SNCFColors.menthe)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func calculateProgress() -> (completed: Int, total: Int, ratio: Double) {
        // Logique de calcul de progression
        let completed = 15
        let total = 30
        let ratio = Double(completed) / Double(total)
        return (completed, total, ratio)
    }
}

// MARK: - Exemple 2 : Liste de checklist avec nouveau design

struct ExampleChecklistView: View {
    @StateObject private var viewModel = ViewModel()
    @State private var states: [UUID: Int] = [:]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.store.checklist?.items ?? []) { item in
                    if !item.isCategory {
                        EnhancedChecklistRow(
                            item: item,
                            state: Binding(
                                get: { states[item.id] ?? 3 },
                                set: { states[item.id] = $0 }
                            ),
                            isInteractive: true,
                            hasNote: viewModel.note(for: item) != nil,
                            onStateChange: { newState in
                                // Sauvegarder l'état
                                HapticManager.impact(style: .light)
                                viewModel.setState(newState, for: item)
                            },
                            onNoteTap: {
                                // Ouvrir l'éditeur de note
                                HapticManager.selection()
                            }
                        )
                        .transition(.slideAndFade)
                    }
                }
            }
            .padding()
        }
        .animation(AnimationPresets.smooth, value: states)
    }
}

// MARK: - Exemple 3 : Carte de progression avec stats

struct ExampleProgressCard: View {
    let progress: Double = 0.65
    
    var body: some View {
        ModernCard(elevated: true) {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Progression")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Triennale CFL")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    CircularProgressView(
                        progress: progress,
                        lineWidth: 8,
                        size: 60
                    )
                }
                
                // Barre de progression
                ModernProgressBar(
                    progress: progress,
                    height: 16,
                    showPercentage: false,
                    accentColor: SNCFColors.ceruleen
                )
                
                // Stats
                HStack(spacing: 16) {
                    StatPill(
                        icon: "checkmark.circle.fill",
                        value: "20",
                        label: "Validés",
                        color: SNCFColors.menthe
                    )
                    
                    StatPill(
                        icon: "circle.fill",
                        value: "11",
                        label: "Restants",
                        color: SNCFColors.bleuHorizon
                    )
                }
            }
        }
        .padding()
    }
}

// MARK: - Exemple 4 : Utilisation des badges de statut

struct ExampleStatusGrid: View {
    var body: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("États d'évaluation")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Procédure d'urgence")
                            .font(.body)
                        Spacer()
                        StatusBadge(status: .validated, size: .medium)
                    }
                    
                    HStack {
                        Text("Signalisation CFL")
                            .font(.body)
                        Spacer()
                        StatusBadge(status: .partial, size: .medium)
                    }
                    
                    HStack {
                        Text("Radio GSM-R")
                            .font(.body)
                        Spacer()
                        StatusBadge(status: .notValidated, size: .medium)
                    }
                    
                    HStack {
                        Text("ETCS Niveau 2")
                            .font(.body)
                        Spacer()
                        StatusBadge(status: .notProcessed, size: .medium)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Exemple 5 : Animations et transitions

struct ExampleAnimatedView: View {
    @State private var showDetails = false
    @State private var progress: Double = 0.0
    
    var body: some View {
        VStack(spacing: 24) {
            // Bouton avec haptic feedback
            Button {
                HapticManager.impact(style: .medium)
                withAnimation(AnimationPresets.springBouncy) {
                    showDetails.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                    Text(showDetails ? "Masquer" : "Afficher les détails")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(
                    Capsule()
                        .fill(SNCFColors.ceruleen)
                )
            }
            
            // Vue avec transition
            if showDetails {
                ModernCard {
                    VStack(spacing: 16) {
                        Text("Détails de l'évaluation")
                            .font(.title3.bold())
                        
                        ModernProgressBar(
                            progress: progress,
                            accentColor: SNCFColors.menthe
                        )
                        
                        Button("Incrémenter") {
                            HapticManager.selection()
                            withAnimation(AnimationPresets.progressUpdate) {
                                progress = min(progress + 0.1, 1.0)
                            }
                            
                            if progress >= 1.0 {
                                HapticManager.notification(type: .success)
                            }
                        }
                    }
                    .padding()
                }
                .transition(.scaleAndFade)
            }
        }
        .padding()
    }
}

// MARK: - Exemple 6 : Dark Mode adaptatif

struct ExampleDarkModeView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ModernCard {
            VStack(spacing: 16) {
                Text("Mode: \(colorScheme == .dark ? "Sombre" : "Clair")")
                    .font(.headline)
                
                // Fond adaptatif
                RoundedRectangle(cornerRadius: 12)
                    .fill(SNCFColors.cardBackground)
                    .frame(height: 100)
                    .overlay(
                        Text("Fond adaptatif")
                            .foregroundColor(SNCFColors.adaptiveText)
                    )
                
                // Bordure adaptative
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(SNCFColors.subtleBorder, lineWidth: 2)
                    .frame(height: 100)
                    .overlay(
                        Text("Bordure adaptative")
                            .foregroundColor(SNCFColors.adaptiveSecondary)
                    )
            }
        }
        .padding()
    }
}

// MARK: - Exemple 7 : Grille de cartes responsive

struct ExampleCardGrid: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    
    let items = ["Conducteurs", "Évaluations", "Rapports", "Statistiques"]
    
    var body: some View {
        let columns = sizeClass == .compact ? 2 : 4
        
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: columns),
            spacing: 16
        ) {
            ForEach(items, id: \.self) { item in
                ModernCard {
                    VStack(spacing: 12) {
                        Image(systemName: iconForItem(item))
                            .font(.system(size: 32))
                            .foregroundColor(SNCFColors.ceruleen)
                        
                        Text(item)
                            .font(.headline)
                    }
                    .frame(height: 120)
                }
                .onTapGesture {
                    HapticManager.impact(style: .light)
                }
            }
        }
        .padding()
    }
    
    private func iconForItem(_ item: String) -> String {
        switch item {
        case "Conducteurs": return "person.3.fill"
        case "Évaluations": return "checkmark.circle.fill"
        case "Rapports": return "doc.text.fill"
        case "Statistiques": return "chart.bar.fill"
        default: return "circle.fill"
        }
    }
}

// MARK: - Preview de tous les exemples

#Preview("Dashboard") {
    ExampleDashboard()
}

#Preview("Progress Card") {
    ExampleProgressCard()
}

#Preview("Status Grid") {
    ExampleStatusGrid()
}

#Preview("Animations") {
    ExampleAnimatedView()
}

#Preview("Dark Mode") {
    ExampleDarkModeView()
}

#Preview("Card Grid") {
    ExampleCardGrid()
}

#endif // Fin du bloc d'exemples - Décommenter si vous souhaitez compiler

