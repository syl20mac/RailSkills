//
//  SharePointSyncView.swift
//  RailSkills
//
//  Vue de synchronisation avec SharePoint
//

import SwiftUI

struct SharePointSyncView: View {
    @ObservedObject private var syncService = SharePointSyncService.shared
    @ObservedObject var store: Store
    
    @State private var showingSyncAlert = false
    @State private var syncAlertMessage = ""
    @State private var syncAlertTitle = ""
    
    var body: some View {
        Form {
            // État de la configuration
            Section {
                HStack {
                    Text("État")
                        .font(.headline)
                    Spacer()
                    if syncService.isConfigured {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(SNCFColors.menthe)
                            Text("Configuré")
                                .font(.caption)
                                .foregroundStyle(SNCFColors.menthe)
                        }
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(SNCFColors.corail)
                            Text("Non configuré")
                                .font(.caption)
                                .foregroundStyle(SNCFColors.corail)
                        }
                    }
                }
                
                if !syncService.isConfigured {
                    Text("Pour utiliser la synchronisation SharePoint, configurez d'abord le Client Secret Azure AD dans les paramètres.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    NavigationLink {
                        AzureADConfigView()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundStyle(SNCFColors.ceruleen)
                            Text("Configurer Azure AD")
                                .font(.headline)
                        }
                    }
                }
            } header: {
                Text("Configuration")
            }
            
            if syncService.isConfigured {
                // Informations de synchronisation
                Section {
                    if let lastSync = syncService.lastSyncDate {
                        HStack {
                            Text("Dernière synchronisation")
                            Spacer()
                            Text(DateFormatHelper.formatDate(lastSync))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Aucune synchronisation effectuée")
                            .foregroundStyle(.secondary)
                    }
                    
                    if let siteId = syncService.siteId {
                        HStack {
                            Text("Site ID")
                            Spacer()
                            Text(String(siteId.prefix(20)) + "...")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Informations")
                }
                
                // Actions de synchronisation
                Section {
                    Button {
                        syncAll()
                    } label: {
                        HStack {
                            if syncService.isSyncing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.up.arrow.down.circle.fill")
                                    .font(.title3)
                            }
                            Text("Synchroniser tout vers SharePoint")
                                .font(.headline)
                        }
                    }
                    .disabled(syncService.isSyncing || store.drivers.isEmpty)
                    
                    if !store.drivers.isEmpty {
                        Button {
                            syncDriversOnly()
                        } label: {
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .font(.title3)
                                Text("Synchroniser les conducteurs seulement")
                                    .font(.headline)
                            }
                        }
                        .disabled(syncService.isSyncing)
                    }
                    
                    if let checklist = store.checklist {
                        Button {
                            syncChecklistOnly(checklist)
                        } label: {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .font(.title3)
                                Text("Synchroniser la checklist seulement")
                                    .font(.headline)
                            }
                        }
                        .disabled(syncService.isSyncing)
                    }
                    
                    // Bouton pour uploader les checklists par défaut (VP et TE)
                    Button {
                        uploadDefaultChecklists()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title3)
                            Text("Uploader les checklists VP et TE")
                                .font(.headline)
                        }
                    }
                    .disabled(syncService.isSyncing)
                } header: {
                    Text("Synchronisation")
                } footer: {
                    Text("Les données sont synchronisées vers SharePoint. Une copie 'latest' est toujours maintenue pour faciliter la récupération.")
                        .foregroundStyle(.secondary)
                }
                
                // Messages d'erreur
                if let error = syncService.syncError {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(SNCFColors.corail)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(SNCFColors.corail)
                        }
                    } header: {
                        Text("Erreur")
                    }
                }
            }
        }
        .navigationTitle("Synchronisation SharePoint")
        .navigationBarTitleDisplayMode(.inline)
        .alert(syncAlertTitle, isPresented: $showingSyncAlert) {
            Button("OK") { }
        } message: {
            Text(syncAlertMessage)
        }
    }
    
    private func syncAll() {
        Task { @MainActor in
            do {
                // Synchroniser les conducteurs
                if !store.drivers.isEmpty {
                    try await syncService.syncDrivers(store.drivers)
                }
                
                // Synchroniser la checklist si présente
                if let checklist = store.checklist {
                    try await syncService.syncChecklist(checklist)
                }
                
                syncAlertTitle = "Synchronisation réussie"
                syncAlertMessage = "Toutes les données ont été synchronisées vers SharePoint avec succès."
                showingSyncAlert = true
            } catch {
                syncAlertTitle = "Erreur de synchronisation"
                syncAlertMessage = error.localizedDescription
                showingSyncAlert = true
            }
        }
    }
    
    private func syncDriversOnly() {
        Task { @MainActor in
            do {
                try await syncService.syncDrivers(store.drivers)
                syncAlertTitle = "Synchronisation réussie"
                syncAlertMessage = "\(store.drivers.count) conducteur(s) synchronisé(s) vers SharePoint."
                showingSyncAlert = true
            } catch {
                syncAlertTitle = "Erreur de synchronisation"
                syncAlertMessage = error.localizedDescription
                showingSyncAlert = true
            }
        }
    }
    
    private func syncChecklistOnly(_ checklist: Checklist) {
        Task { @MainActor in
            do {
                try await syncService.syncChecklist(checklist)
                syncAlertTitle = "Synchronisation réussie"
                syncAlertMessage = "Checklist '\(checklist.title)' synchronisée vers SharePoint."
                showingSyncAlert = true
            } catch {
                syncAlertTitle = "Erreur de synchronisation"
                syncAlertMessage = error.localizedDescription
                showingSyncAlert = true
            }
        }
    }
    
    private func uploadDefaultChecklists() {
        Task { @MainActor in
            do {
                try await syncService.uploadDefaultChecklistsToSharePoint()
                syncAlertTitle = "Upload réussi"
                syncAlertMessage = "Les checklists VP et TE ont été uploadées vers SharePoint avec succès."
                showingSyncAlert = true
            } catch {
                syncAlertTitle = "Erreur d'upload"
                syncAlertMessage = error.localizedDescription
                showingSyncAlert = true
            }
        }
    }
}

