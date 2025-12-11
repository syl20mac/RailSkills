//
//  AzureADConfigView.swift
//  RailSkills
//
//  Vue de configuration de la synchronisation SharePoint via le backend
//  Le Client Secret est géré côté serveur pour plus de sécurité
//

import SwiftUI

struct AzureADConfigView: View {
    @State private var backendURL: String = ""
    @State private var isTestingConnection = false
    @State private var connectionStatus: ConnectionStatus = .unknown
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    @Environment(\.dismiss) private var dismiss
    
    enum ConnectionStatus {
        case unknown
        case testing
        case success
        case failed(String)
        
        var icon: String {
            switch self {
            case .unknown: return "questionmark.circle"
            case .testing: return "arrow.clockwise"
            case .success: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .unknown: return .secondary
            case .testing: return SNCFColors.ceruleen
            case .success: return SNCFColors.menthe
            case .failed: return SNCFColors.corail
            }
        }
        
        var message: String {
            switch self {
            case .unknown: return "Non testé"
            case .testing: return "Test en cours..."
            case .success: return "Backend connecté ✓"
            case .failed(let msg): return msg
            }
        }
    }
    
    var body: some View {
        Form {
            // Section information
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "cloud.fill")
                            .foregroundStyle(SNCFColors.ceruleen)
                        Text("Synchronisation automatique")
                            .font(.headline)
                    }
                    
                    Text("RailSkills utilise un serveur backend sécurisé pour synchroniser vos données avec SharePoint. Le Client Secret Azure AD est géré côté serveur, vous n'avez rien à configurer.")
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
                    Image(systemName: connectionStatus.icon)
                        .foregroundStyle(connectionStatus.color)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("État de la connexion")
                            .font(.headline)
                        Text(connectionStatus.message)
                            .font(.caption)
                            .foregroundStyle(connectionStatus.color)
                    }
                    
                    Spacer()
                    
                    if case .testing = connectionStatus {
                        ProgressView()
                    }
                }
                
                Button {
                    testConnection()
                } label: {
                    HStack {
                        Image(systemName: "network")
                            .font(.title3)
                        Text("Tester la connexion")
                            .font(.headline)
                    }
                }
                .disabled(isTestingConnection)
            } header: {
                Text("Statut")
            }
            
            // Section configuration avancée (pliable)
            Section {
                DisclosureGroup("Configuration du serveur") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("URL du backend")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextField("https://railskills-backend.sncf.fr", text: $backendURL)
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)
                        
                        HStack {
                            Button("Réinitialiser") {
                                BackendConfig.resetToDefault()
                                backendURL = BackendConfig.backendURL
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Button("Enregistrer") {
                                saveBackendURL()
                            }
                            .font(.caption.bold())
                            .foregroundStyle(SNCFColors.ceruleen)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 8)
                }
            } header: {
                Text("Avancé")
            } footer: {
                Text("Ne modifiez l'URL que si votre organisation utilise un serveur personnalisé.")
                    .foregroundStyle(.secondary)
            }
            
            // Section aide
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(SNCFColors.safran)
                        Text("Besoin d'aide ?")
                            .font(.headline)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        helpRow(icon: "1.circle.fill", text: "Vérifiez votre connexion Internet")
                        helpRow(icon: "2.circle.fill", text: "Contactez votre administrateur IT")
                        helpRow(icon: "3.circle.fill", text: "Vérifiez que le serveur est en ligne")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Synchronisation SharePoint")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            backendURL = BackendConfig.backendURL
            // Test automatique au chargement
            testConnection()
        }
        .alert("Configuration enregistrée", isPresented: $showingSuccessAlert) {
            Button("OK") {}
        } message: {
            Text("L'URL du serveur a été mise à jour.")
        }
        .alert("Erreur", isPresented: $showingErrorAlert) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func helpRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(SNCFColors.ceruleen)
            Text(text)
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        connectionStatus = .testing
        
        Task {
            let isConnected = await BackendTokenService.shared.testBackendConnection()
            
            await MainActor.run {
                isTestingConnection = false
                
                if isConnected {
                    connectionStatus = .success
                    Logger.success("Backend connecté", category: "AzureADConfigView")
                } else {
                    connectionStatus = .failed("Serveur inaccessible")
                    Logger.warning("Backend inaccessible", category: "AzureADConfigView")
                }
            }
        }
    }
    
    private func saveBackendURL() {
        let trimmedURL = backendURL.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedURL.isEmpty else {
            errorMessage = "L'URL ne peut pas être vide"
            showingErrorAlert = true
            return
        }
        
        guard URL(string: trimmedURL) != nil else {
            errorMessage = "URL invalide"
            showingErrorAlert = true
            return
        }
        
        BackendConfig.backendURL = trimmedURL
        showingSuccessAlert = true
        
        // Retester la connexion
        testConnection()
    }
}

#Preview {
    NavigationStack {
        AzureADConfigView()
    }
}
