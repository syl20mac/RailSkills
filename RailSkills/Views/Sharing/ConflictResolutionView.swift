//
//  ConflictResolutionView.swift
//  RailSkills
//
//  Vue pour résoudre les conflits de synchronisation SharePoint
//  Permet de choisir la stratégie de résolution pour chaque conflit
//

import SwiftUI

/// Vue de résolution des conflits de synchronisation
struct ConflictResolutionView: View {
    @StateObject private var sharePointService = SharePointSyncService.shared
    @EnvironmentObject private var toastManager: ToastNotificationManager
    @Environment(\.dismiss) private var dismiss
    
    let conflicts: [SyncConflict]
    let onResolve: ([DriverRecord]) -> Void
    
    @State private var selectedResolutions: [UUID: ConflictResolution] = [:]
    @State private var isResolving: Bool = false
    
    enum ConflictResolution {
        case useLocal
        case useRemote
        case merge
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // En-tête avec résumé
                conflictSummaryHeader
                
                // Liste des conflits
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(conflicts) { conflict in
                            ConflictCardView(
                                conflict: conflict,
                                selectedResolution: Binding(
                                    get: { selectedResolutions[conflict.driverId] ?? .merge },
                                    set: { selectedResolutions[conflict.driverId] = $0 }
                                )
                            )
                        }
                    }
                    .padding()
                }
                
                // Boutons d'action
                actionButtons
            }
            .navigationTitle("Conflits de synchronisation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Summary Header
    
    private var conflictSummaryHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(SNCFColors.safran)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Conflits détectés")
                        .font(.avenirHeadline)
                        .foregroundStyle(.primary)
                    
                    Text("\(conflicts.count) conducteur(s) modifié(s) simultanément")
                        .font(.avenirCaption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Recommandation
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(SNCFColors.ceruleen)
                
                Text("Recommandation : la fusion intelligente combine les meilleures données des deux versions")
                    .font(.avenirCaption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(SNCFColors.ceruleen.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Appliquer la résolution
            Button(action: resolveConflicts) {
                HStack {
                    if isResolving {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Résoudre les conflits")
                    }
                }
                .font(.avenirHeadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(SNCFColors.menthe)
                .cornerRadius(12)
            }
            .disabled(isResolving)
            
            // Résolution rapide: tout fusionner
            Button(action: resolveAllWithMerge) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("Tout fusionner (recommandé)")
                }
                .font(.avenirBody)
                .foregroundStyle(SNCFColors.ceruleen)
                .frame(maxWidth: .infinity)
                .padding()
                .background(SNCFColors.ceruleen.opacity(0.1))
                .cornerRadius(12)
            }
            .disabled(isResolving)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
    }
    
    // MARK: - Actions
    
    private func resolveConflicts() {
        isResolving = true
        
        Task {
            var resolvedDrivers: [DriverRecord] = []
            
            for conflict in conflicts {
                let resolution = selectedResolutions[conflict.driverId] ?? .merge
                
                let resolved: DriverRecord
                switch resolution {
                case .useLocal:
                    resolved = conflict.localVersion
                case .useRemote:
                    resolved = conflict.remoteVersion
                case .merge:
                    resolved = sharePointService.mergeDriverRecords(
                        local: conflict.localVersion,
                        remote: conflict.remoteVersion
                    )
                }
                
                resolvedDrivers.append(resolved)
            }
            
            await MainActor.run {
                onResolve(resolvedDrivers)
                isResolving = false
                toastManager.show("Conflits résolus avec succès", type: .success)
                dismiss()
            }
        }
    }
    
    private func resolveAllWithMerge() {
        // Sélectionner "Fusionner" pour tous les conflits
        for conflict in conflicts {
            selectedResolutions[conflict.driverId] = .merge
        }
        
        // Appliquer immédiatement
        resolveConflicts()
    }
}

// MARK: - Conflict Card View

struct ConflictCardView: View {
    let conflict: SyncConflict
    @Binding var selectedResolution: ConflictResolutionView.ConflictResolution
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // En-tête avec nom du conducteur
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(SNCFColors.ceruleen)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(conflict.driverName)
                        .font(.avenirHeadline)
                        .foregroundStyle(.primary)
                    
                    Text("Modifié sur iPad et SharePoint")
                        .font(.avenirCaption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Comparaison des versions
            HStack(spacing: 12) {
                versionCard(
                    title: "iPad",
                    date: conflict.localModifiedDate,
                    isNewer: conflict.localIsNewer,
                    isSelected: selectedResolution == .useLocal
                ) {
                    selectedResolution = .useLocal
                }
                
                versionCard(
                    title: "SharePoint",
                    date: conflict.remoteModifiedDate,
                    isNewer: !conflict.localIsNewer,
                    isSelected: selectedResolution == .useRemote
                ) {
                    selectedResolution = .useRemote
                }
            }
            
            // Option de fusion (recommandée)
            Button(action: {
                selectedResolution = .merge
            }) {
                HStack {
                    Image(systemName: selectedResolution == .merge ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selectedResolution == .merge ? SNCFColors.menthe : .secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Fusionner intelligemment")
                                .font(.avenirBody)
                                .foregroundStyle(.primary)
                            
                            Text("RECOMMANDÉ")
                                .font(.avenirCaption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(SNCFColors.menthe)
                                .cornerRadius(4)
                        }
                        
                        Text("Combine les meilleures données des deux versions")
                            .font(.avenirCaption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedResolution == .merge ? SNCFColors.menthe.opacity(0.1) : Color(uiColor: .secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedResolution == .merge ? SNCFColors.menthe : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func versionCard(title: String, date: Date, isNewer: Bool, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Badge "Plus récent" si applicable
                if isNewer {
                    Text("Plus récent")
                        .font(.avenirCaption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(SNCFColors.ceruleen)
                        .cornerRadius(4)
                } else {
                    Spacer()
                        .frame(height: 20)
                }
                
                // Icône de sélection
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundStyle(isSelected ? SNCFColors.ceruleen : .secondary)
                
                // Titre
                Text(title)
                    .font(.avenirBody)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                // Date
                Text(formatRelativeDate(date))
                    .font(.avenirCaption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? SNCFColors.ceruleen.opacity(0.1) : Color(uiColor: .secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? SNCFColors.ceruleen : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    let sampleConflicts = [
        SyncConflict(
            driverName: "Jean Dupont",
            driverId: UUID(),
            localVersion: DriverRecord(name: "Jean Dupont"),
            remoteVersion: DriverRecord(name: "Jean Dupont"),
            localModifiedDate: Date().addingTimeInterval(-7200), // 2h ago
            remoteModifiedDate: Date().addingTimeInterval(-3600) // 1h ago
        ),
        SyncConflict(
            driverName: "Marie Martin",
            driverId: UUID(),
            localVersion: DriverRecord(name: "Marie Martin"),
            remoteVersion: DriverRecord(name: "Marie Martin"),
            localModifiedDate: Date().addingTimeInterval(-3600),
            remoteModifiedDate: Date().addingTimeInterval(-7200)
        )
    ]
    
    ConflictResolutionView(conflicts: sampleConflicts) { _ in }
        .environmentObject(ToastNotificationManager())
}





