//
//  MoreView.swift
//  RailSkills
//
//  Vue "Plus" regroupant les fonctions secondaires de l'application
//  Amélioration UX pour réduire le nombre d'onglets dans la TabBar
//

import SwiftUI

/// Vue regroupant les fonctions secondaires (Éditeur, Rapports, Réglages, etc.)
struct MoreView: View {
    // MARK: - Propriétés
    
    @ObservedObject var vm: AppViewModel
    
    // MARK: - État
    
    @State private var showingOnboarding = false
    @State private var animateCards = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // En-tête avec statistiques rapides
                    quickStatsHeader
                    
                    // Sections de fonctionnalités
                    checklistsSection
                    toolsSection
                    dataSection
                    helpSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Plus")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateCards = true
            }
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            EnhancedOnboardingView(isPresented: $showingOnboarding)
        }
    }
    
    // MARK: - Sous-vues
    
    /// En-tête avec statistiques rapides
    private var quickStatsHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                // Stat: Conducteurs
                QuickStatCard(
                    icon: "person.2.fill",
                    value: "\(vm.store.drivers.count)",
                    label: "Conducteurs",
                    color: SNCFColors.ceruleen
                )
                
                // Stat: Questions
                QuickStatCard(
                    icon: "list.bullet.clipboard",
                    value: "\(vm.store.checklist?.items.filter { !$0.isCategory }.count ?? 0)",
                    label: "Questions",
                    color: SNCFColors.menthe
                )
                
                // Stat: Progression
                QuickStatCard(
                    icon: "chart.pie.fill",
                    value: "\(Int(vm.progress * 100))%",
                    label: "Progression",
                    color: SNCFColors.safran
                )
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animateCards)
    }
    
    /// Section tableau de bord et statistiques
    private var checklistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Statistiques", icon: "chart.bar.fill")
            
            VStack(spacing: 0) {
                // Tableau de bord
                NavigationLink {
                    DashboardView(vm: vm)
                } label: {
                    MenuRow(
                        icon: "chart.bar.fill",
                        title: "Tableau de bord",
                        subtitle: "Statistiques et progression globale",
                        color: SNCFColors.ceruleen
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
            )
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: animateCards)
    }
    
    /// Section des outils
    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Outils", icon: "wrench.and.screwdriver.fill")
            
            VStack(spacing: 0) {
                // Éditeur de checklist
                NavigationLink {
                    ChecklistEditorView(vm: vm)
                } label: {
                    MenuRow(
                        icon: "square.and.pencil",
                        title: "Éditeur de checklist",
                        subtitle: "Créer et modifier les questions",
                        color: SNCFColors.lavande
                    )
                }
                
                Divider().padding(.leading, 56)
                
                // Modèles de notes
                NavigationLink {
                    NoteTemplatesManagerView()
                } label: {
                    MenuRow(
                        icon: "doc.text.fill",
                        title: "Modèles de notes",
                        subtitle: "Créer des notes réutilisables",
                        color: SNCFColors.safran
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
            )
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: animateCards)
    }
    
    /// Section des données
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Données et rapports", icon: "doc.fill")
            
            VStack(spacing: 0) {
                // Rapports
                NavigationLink {
                    ReportsView(vm: vm)
                } label: {
                    MenuRow(
                        icon: "doc.richtext.fill",
                        title: "Rapports PDF",
                        subtitle: "Générer et exporter des rapports",
                        color: SNCFColors.corail
                    )
                }
                
                Divider().padding(.leading, 56)
                
                // Synchronisation SharePoint
                NavigationLink {
                    SharePointSyncView(store: vm.store)
                } label: {
                    MenuRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Synchronisation",
                        subtitle: "SharePoint et cloud",
                        color: SNCFColors.menthe
                    )
                }
                
                Divider().padding(.leading, 56)
                
                // Import/Export
                NavigationLink {
                    SharingView(vm: vm)
                } label: {
                    MenuRow(
                        icon: "square.and.arrow.up.on.square",
                        title: "Import / Export",
                        subtitle: "Partager les données JSON",
                        color: SNCFColors.bleuHorizon
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
            )
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25), value: animateCards)
    }
    
    /// Section d'aide et paramètres
    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Aide et paramètres", icon: "questionmark.circle.fill")
            
            VStack(spacing: 0) {
                // Réglages
                NavigationLink {
                    SettingsView(vm: vm)
                } label: {
                    MenuRow(
                        icon: "gear",
                        title: "Réglages",
                        subtitle: "Configuration de l'application",
                        color: Color.gray
                    )
                }
                
                Divider().padding(.leading, 56)
                
                // Tutoriel
                Button {
                    showingOnboarding = true
                } label: {
                    MenuRow(
                        icon: "book.fill",
                        title: "Tutoriel",
                        subtitle: "Revoir l'introduction",
                        color: SNCFColors.parme
                    )
                }
                
                Divider().padding(.leading, 56)
                
                // À propos
                NavigationLink {
                    AboutView()
                } label: {
                    MenuRow(
                        icon: "info.circle.fill",
                        title: "À propos",
                        subtitle: "Version et informations",
                        color: SNCFColors.cobalt
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
            )
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35), value: animateCards)
    }
}

// MARK: - Composants réutilisables

/// Carte de statistique compacte pour la vue Plus
struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

/// En-tête de section
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 4)
    }
}

/// Ligne de menu avec icône et descriptions
struct MenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icône
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
            }
            
            // Textes
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Vue À propos

/// Vue affichant les informations sur l'application
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Logo et version
                VStack(spacing: 16) {
                    Image(systemName: "train.side.front.car")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [SNCFColors.ceruleen, SNCFColors.cobalt],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(spacing: 4) {
                        Text("RailSkills")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 40)
                
                // Description
                Text("Application de suivi des compétences pour les conducteurs ferroviaires selon la checklist triennale.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Divider()
                    .padding(.horizontal, 32)
                
                // Crédits
                VStack(spacing: 8) {
                    Text("Développé par")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    Text("Sylvain GALLON")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
            }
        }
        .navigationTitle("À propos")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    MoreView(vm: ViewModel())
}

