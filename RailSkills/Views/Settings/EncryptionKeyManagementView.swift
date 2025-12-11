//
//  EncryptionKeyManagementView.swift
//  RailSkills
//
//  Vue de gestion du secret organisationnel pour le chiffrement
//  Le secret est synchronisé automatiquement via le backend
//

import SwiftUI

/// Vue de gestion du secret organisationnel pour le chiffrement
struct EncryptionKeyManagementView: View {
    @StateObject private var secretService = OrganizationSecretService.shared
    @State private var showingManualEntry = false
    @State private var manualSecret = ""
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            // Section information
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(SNCFColors.menthe)
                        Text("Chiffrement des données")
                            .font(.headline)
                    }
                    
                    Text("Les fichiers d'export sont automatiquement chiffrés avec le secret de votre organisation. Ce secret est synchronisé depuis le serveur pour tous les CTT de votre équipe.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            } header: {
                Text("Information")
            }
            
            // Section statut
            Section {
                HStack {
                    Image(systemName: secretService.isSynced ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(secretService.isSynced ? SNCFColors.menthe : SNCFColors.safran)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("État du secret")
                            .font(.headline)
                        
                        if secretService.isSynced {
                            if let orgName = secretService.organizationName {
                                Text("Synchronisé (\(orgName))")
                                    .font(.caption)
                                    .foregroundStyle(SNCFColors.menthe)
                            } else {
                                Text("Synchronisé")
                                    .font(.caption)
                                    .foregroundStyle(SNCFColors.menthe)
                            }
                        } else {
                            Text("Secret par défaut utilisé")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if secretService.isLoading {
                        ProgressView()
                    }
                }
                
                Button {
                    syncSecret()
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title3)
                        Text("Synchroniser le secret")
                            .font(.headline)
                    }
                }
                .disabled(secretService.isLoading)
            } header: {
                Text("Synchronisation")
            } footer: {
                if let error = secretService.errorMessage {
                    Text("⚠️ \(error)")
                        .foregroundStyle(SNCFColors.corail)
                } else {
                    Text("Le secret est automatiquement synchronisé au démarrage de l'application.")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Section configuration manuelle (pour mode hors-ligne)
            Section {
                DisclosureGroup("Configuration manuelle") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Si vous n'avez pas accès au serveur, vous pouvez saisir le secret manuellement.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        SecureField("Secret organisationnel", text: $manualSecret)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)
                        
                        HStack {
                            Button("Réinitialiser") {
                                resetToDefault()
                            }
                            .font(.caption)
                            .foregroundStyle(SNCFColors.corail)
                            
                            Spacer()
                            
                            Button("Appliquer") {
                                saveManualSecret()
                            }
                            .font(.caption.bold())
                            .foregroundStyle(SNCFColors.ceruleen)
                            .disabled(manualSecret.isEmpty)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 8)
                }
            } header: {
                Text("Mode hors-ligne")
            } footer: {
                Text("⚠️ En mode manuel, assurez-vous d'utiliser le même secret que vos collègues.")
                    .foregroundStyle(.secondary)
            }
            
            // Section aide
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(SNCFColors.safran)
                        Text("Comment ça fonctionne ?")
                            .font(.headline)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        helpRow(number: 1, text: "Le secret est stocké sur le serveur de l'organisation")
                        helpRow(number: 2, text: "Tous les CTT de la même organisation partagent le même secret")
                        helpRow(number: 3, text: "Les fichiers exportés sont chiffrés avec ce secret")
                        helpRow(number: 4, text: "Seuls les appareils avec le même secret peuvent les lire")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Secret organisationnel")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await secretService.checkSyncStatus()
            }
        }
        .alert("Succès", isPresented: $showingSuccessAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
        .alert("Erreur", isPresented: $showingErrorAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private func helpRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .foregroundStyle(SNCFColors.ceruleen)
                .fontWeight(.bold)
            Text(text)
        }
    }
    
    private func syncSecret() {
        Task {
            do {
                _ = try await secretService.syncSecretFromBackend()
                alertMessage = "Secret synchronisé avec succès"
                showingSuccessAlert = true
            } catch {
                alertMessage = error.localizedDescription
                showingErrorAlert = true
            }
        }
    }
    
    private func saveManualSecret() {
        let trimmed = manualSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        EncryptionService.setOrganizationSecret(trimmed)
        manualSecret = ""
        alertMessage = "Secret enregistré en mode manuel"
        showingSuccessAlert = true
    }
    
    private func resetToDefault() {
        EncryptionService.resetToDefaultSecret()
        secretService.clearCache()
        manualSecret = ""
        alertMessage = "Secret réinitialisé au secret par défaut"
        showingSuccessAlert = true
    }
}

#Preview {
    NavigationStack {
        EncryptionKeyManagementView()
    }
}
