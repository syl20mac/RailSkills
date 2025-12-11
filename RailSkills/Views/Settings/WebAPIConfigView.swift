//
//  WebAPIConfigView.swift
//  RailSkills
//
//  Vue pour configurer l'URL de l'API web
//

import SwiftUI

struct WebAPIConfigView: View {
    @StateObject private var authService = WebAuthService.shared
    @EnvironmentObject private var toastManager: ToastNotificationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var apiURL: String = ""
    @State private var isLoading = false
    
    var body: some View {
        Form {
            Section {
                TextField("URL de l'API web", text: $apiURL)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            } header: {
                Text("Configuration")
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Entrez l'URL complète de l'API web (ex: https://railskills.syl20.org/api)")
                    Text("URL actuelle: \(authService.baseURL)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Button(action: {
                    saveConfiguration()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Enregistrer")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(isLoading || apiURL.isEmpty)
            }
        }
        .navigationTitle("Configuration API web")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            apiURL = authService.baseURL
        }
    }
    
    private func saveConfiguration() {
        guard !apiURL.isEmpty else { return }
        
        // Valider l'URL
        guard URL(string: apiURL) != nil else {
            toastManager.show("URL invalide", type: .error)
            return
        }
        
        authService.setBaseURL(apiURL)
        toastManager.show("Configuration enregistrée", type: .success)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        WebAPIConfigView()
            .environmentObject(ToastNotificationManager())
    }
}




