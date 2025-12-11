//
//  SyncIndicatorView.swift
//  RailSkills
//
//  Indicateur compact de synchronisation pour la barre de navigation
//  Affiche l'état temps réel de la synchronisation SharePoint
//

import SwiftUI

/// Indicateur compact de synchronisation dans la navigation
struct SyncIndicatorView: View {
    @StateObject private var sharePointService = SharePointSyncService.shared
    @ObservedObject var store: Store
    
    @State private var showingDetailsSheet: Bool = false
    
    var body: some View {
        Button(action: {
            showingDetailsSheet = true
        }) {
            HStack(spacing: 6) {
                syncIcon
                
                if let lastSync = sharePointService.lastSyncDate {
                    Text(formatSyncTime(lastSync))
                        .font(.avenirCaption2)
                        .foregroundStyle(syncColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(syncColor.opacity(0.1))
            .cornerRadius(12)
        }
        .sheet(isPresented: $showingDetailsSheet) {
            SyncDetailsSheet(store: store)
        }
    }
    
    // MARK: - Sync Icon
    
    @ViewBuilder
    private var syncIcon: some View {
        if sharePointService.isSyncing {
            // Synchronisation en cours
            ProgressView()
                .scaleEffect(0.8)
                .tint(SNCFColors.ceruleen)
        } else if sharePointService.syncError != nil {
            // Erreur de sync
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(SNCFColors.corail)
        } else if sharePointService.isConfigured {
            if let _ = sharePointService.lastSyncDate {
                // Sync OK
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(SNCFColors.menthe)
            } else {
                // Configuré mais pas encore sync
                Image(systemName: "cloud.fill")
                    .font(.caption)
                    .foregroundStyle(SNCFColors.ceruleen)
            }
        } else {
            // Non configuré
            Image(systemName: "cloud.slash.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var syncColor: Color {
        if sharePointService.isSyncing {
            return SNCFColors.ceruleen
        } else if sharePointService.syncError != nil {
            return SNCFColors.corail
        } else if sharePointService.lastSyncDate != nil {
            return SNCFColors.menthe
        } else {
            return SNCFColors.ceruleen
        }
    }
    
    private func formatSyncTime(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "maintenant"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h"
        } else {
            let days = Int(interval / 86400)
            return "\(days)j"
        }
    }
}

// MARK: - Sync Details Sheet

struct SyncDetailsSheet: View {
    @StateObject private var sharePointService = SharePointSyncService.shared
    @ObservedObject var store: Store
    @Environment(\.dismiss) private var dismiss
    
    @State private var isSyncing: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // État actuel
                    currentStatusCard
                    
                    // SharePoint
                    if sharePointService.isConfigured {
                        sharePointSection
                    } else {
                        notConfiguredCard
                    }
                    
                    // Actions rapides
                    quickActionsSection
                }
                .padding()
            }
            .navigationTitle("Synchronisation")
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
    
    // MARK: - Current Status Card
    
    private var currentStatusCard: some View {
        VStack(spacing: 12) {
            if sharePointService.isSyncing {
                // En cours
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Synchronisation en cours...")
                        .font(.avenirHeadline)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if let error = sharePointService.syncError {
                // Erreur
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(SNCFColors.corail)
                    
                    Text("Erreur de synchronisation")
                        .font(.avenirHeadline)
                        .foregroundStyle(.primary)
                    
                    Text(error)
                        .font(.avenirCaption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if let lastSync = sharePointService.lastSyncDate {
                // Succès
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(SNCFColors.menthe)
                    
                    Text("Synchronisé")
                        .font(.avenirHeadline)
                        .foregroundStyle(.primary)
                    
                    Text("Dernière synchronisation : \(DateFormatHelper.formatDate(lastSync, style: .medium))")
                        .font(.avenirCaption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                // Jamais synchronisé
                VStack(spacing: 12) {
                    Image(systemName: "cloud")
                        .font(.system(size: 40))
                        .foregroundStyle(SNCFColors.ceruleen)
                    
                    Text("Prêt à synchroniser")
                        .font(.avenirHeadline)
                        .foregroundStyle(.primary)
                    
                    Text("Aucune synchronisation effectuée")
                        .font(.avenirCaption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - SharePoint Section
    
    private var sharePointSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cloud.fill")
                    .foregroundStyle(SNCFColors.ceruleen)
                Text("SharePoint")
                    .font(.avenirHeadline)
            }
            
            Divider()
            
            infoRow(label: "État", value: sharePointService.isConfigured ? "Configuré" : "Non configuré")
            infoRow(label: "Synchronisation auto", value: store.sharePointAutoSyncEnabled ? "Activée" : "Désactivée")
            
            if let lastSync = sharePointService.lastSyncDate {
                infoRow(label: "Dernière sync", value: DateFormatHelper.formatDate(lastSync, style: .medium))
            }
            
            if let error = sharePointService.syncError {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Erreur")
                        .font(.avenirCaption)
                        .foregroundStyle(.secondary)
                    Text(error)
                        .font(.avenirFootnote)
                        .foregroundStyle(SNCFColors.corail)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var notConfiguredCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "cloud.slash.fill")
                .font(.title)
                .foregroundStyle(.secondary)
            
            Text("SharePoint non configuré")
                .font(.avenirHeadline)
            
            Text("Configurez Azure AD pour activer la synchronisation SharePoint")
                .font(.avenirCaption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: SharePointSetupView()) {
                Text("Configurer")
                    .font(.avenirBody)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(SNCFColors.ceruleen)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            Text("Actions rapides")
                .font(.avenirHeadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if sharePointService.isConfigured {
                Button(action: syncNow) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundStyle(SNCFColors.ceruleen)
                        Text("Synchroniser maintenant")
                            .font(.avenirBody)
                            .foregroundStyle(.primary)
                        Spacer()
                        if isSyncing {
                            ProgressView()
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .disabled(isSyncing || sharePointService.isSyncing)
                .buttonStyle(.plain)
            }
            
            Toggle(isOn: $store.sharePointAutoSyncEnabled) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(SNCFColors.menthe)
                    Text("Synchronisation automatique")
                        .font(.avenirBody)
                        .foregroundStyle(.primary)
                }
            }
            .padding()
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            .disabled(!sharePointService.isConfigured)
        }
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.avenirCaption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.avenirBody)
                .foregroundStyle(.primary)
        }
    }
    
    private func syncNow() {
        isSyncing = true
        
        Task {
            do {
                // Synchronisation bidirectionnelle : récupérer les modifications depuis SharePoint ET envoyer les modifications locales
                await store.syncDriversBidirectional()
                
                // Synchroniser la checklist si présente
                if let checklist = store.checklist {
                    try await sharePointService.syncChecklist(checklist)
                }
                
                await MainActor.run {
                    isSyncing = false
                }
            } catch {
                await MainActor.run {
                    isSyncing = false
                }
                Logger.error("Erreur lors de la synchronisation manuelle: \(error.localizedDescription)", category: "SyncIndicator")
            }
        }
    }
}

#Preview {
    NavigationStack {
        VStack {
            SyncIndicatorView(store: Store())
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SyncIndicatorView(store: Store())
            }
        }
    }
}




