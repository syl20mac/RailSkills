//
//  ImportDriversExcelView.swift
//  RailSkills
//
//  Vue d'import de conducteurs depuis un fichier Excel
//

import SwiftUI
import UniformTypeIdentifiers

/// Vue d'import de conducteurs depuis un fichier Excel
struct ImportDriversExcelView: View {
    @ObservedObject var vm: ViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDocumentPicker = false
    @State private var isImporting = false
    @State private var importSuccess: Bool = false
    @State private var importMessage: String?
    @State private var showingResult = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Importez une liste de conducteurs depuis un fichier Excel (.xlsx ou .xls).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Format attendu :")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Colonne \"Nom\" (obligatoire)")
                        Text("• Colonne \"Début triennale\" (optionnel)")
                        Text("• Colonne \"Dernière évaluation\" (optionnel)")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                } header: {
                    Text("Instructions")
                }
                
                Section {
                    Button {
                        showingDocumentPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text("Sélectionner un fichier Excel")
                        }
                    }
                    .disabled(isImporting)
                } header: {
                    Text("Fichier")
                }
                
                if isImporting {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Import en cours...")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Importer depuis Excel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingDocumentPicker,
                allowedContentTypes: [.spreadsheet, UTType(filenameExtension: "xls")!],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .alert("Résultat de l'import", isPresented: $showingResult) {
                Button("OK") {
                    if importSuccess {
                        dismiss()
                    }
                }
            } message: {
                if let message = importMessage {
                    Text(message)
                }
            }
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importFromFile(url: url)
        case .failure(let error):
            importSuccess = false
            importMessage = "Erreur lors de la sélection du fichier : \(error.localizedDescription)"
            showingResult = true
        }
    }
    
    private func importFromFile(url: URL) {
        isImporting = true
        
        Task {
            do {
                // Accéder au fichier (nécessaire pour les fichiers iCloud)
                guard url.startAccessingSecurityScopedResource() else {
                    throw ImportError.fileAccessDenied
                }
                defer { url.stopAccessingSecurityScopedResource() }
                
                // Lire le fichier
                let data = try Data(contentsOf: url)
                
                // Parser le fichier Excel
                // Note: Pour iOS, on peut utiliser une bibliothèque comme CoreXLSX ou envoyer au backend
                // Pour simplifier, on envoie le fichier au backend qui le traitera
                let importedDrivers = try await parseExcelFile(data: data)
                
                // Ajouter les conducteurs au store
                await MainActor.run {
                    vm.store.drivers.append(contentsOf: importedDrivers)
                    importSuccess = true
                    importMessage = "\(importedDrivers.count) conducteur(s) importé(s) avec succès"
                    showingResult = true
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    importSuccess = false
                    importMessage = "Erreur lors de l'import : \(error.localizedDescription)"
                    showingResult = true
                    isImporting = false
                }
            }
        }
    }
    
    /// Parse le fichier Excel (version simplifiée - envoie au backend pour traitement)
    private func parseExcelFile(data: Data) async throws -> [DriverRecord] {
        // Envoyer le fichier au backend qui le traitera
        guard BackendConfig.isConfigured else {
            throw ImportError.backendNotConfigured
        }
        
        // Obtenir le token d'authentification
        let token = try await BackendTokenService.shared.getValidToken()
        
        // Construire l'URL de manière sécurisée
        guard let url = URL(string: "\(BackendConfig.backendURL)/api/drivers/import/excel") else {
            throw ImportError.backendError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Construire le body de manière sécurisée
        var body = Data()
        guard let boundaryData = "--\(boundary)\r\n".data(using: .utf8),
              let contentDisposition = "Content-Disposition: form-data; name=\"file\"; filename=\"import.xlsx\"\r\n".data(using: .utf8),
              let contentType = "Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet\r\n\r\n".data(using: .utf8),
              let endBoundary = "\r\n--\(boundary)--\r\n".data(using: .utf8) else {
            throw ImportError.backendError
        }
        
        body.append(boundaryData)
        body.append(contentDisposition)
        body.append(contentType)
        body.append(data)
        body.append(endBoundary)
        
        request.httpBody = body
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ImportError.backendError
        }
        
        // Parser la réponse
        let result = try JSONDecoder().decode(ImportResponse.self, from: responseData)
        
        if !result.success {
            throw ImportError.importFailed(result.message)
        }
        
        // Le backend a déjà créé les conducteurs dans SharePoint
        // On déclenche une synchronisation pour les récupérer
        // Note: La synchronisation se fera automatiquement via le service SharePoint
        // ou on peut forcer une synchronisation manuelle
        
        // Retourner un tableau vide car les conducteurs seront chargés via la synchronisation
        return []
    }
}

// MARK: - Types d'erreur
enum ImportError: LocalizedError {
    case fileAccessDenied
    case backendNotConfigured
    case backendError
    case importFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .fileAccessDenied:
            return "Accès au fichier refusé"
        case .backendNotConfigured:
            return "Backend non configuré"
        case .backendError:
            return "Erreur lors de la communication avec le backend"
        case .importFailed(let message):
            return message
        }
    }
}

// MARK: - Types de réponse
struct ImportResponse: Codable {
    let success: Bool
    let message: String
    let results: ImportResults?
}

struct ImportResults: Codable {
    let imported: Int
    let errors: [String]
    let skipped: Int
    let total: Int
}

