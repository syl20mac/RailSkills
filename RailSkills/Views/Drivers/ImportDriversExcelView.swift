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
    @State private var importResults: ImportResults?
    @State private var importError: String?
    
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
                        Text("• Colonne \"Prénom\" (obligatoire)")
                        Text("• Colonne \"N° CP\" (obligatoire)")
                        Text("• Colonne \"Début triennale\" (optionnel)")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    Text("Note : Les noms de colonnes acceptent des variantes (ex: \"Prenom\", \"CP Number\", \"N CP\")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                } header: {
                    Text("Instructions")
                } footer: {
                    Text("Le fichier Excel doit contenir au minimum les colonnes Nom, Prénom et N° CP. La colonne Début triennale est optionnelle.")
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
            .sheet(isPresented: $showingResult) {
                ImportResultView(
                    success: importSuccess,
                    results: importResults,
                    error: importError,
                    onDismiss: {
                        if importSuccess {
                            dismiss()
                        }
                    }
                )
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
                // Note: Le fichier est envoyé au backend qui le traite et valide les colonnes
                // Le backend vérifie la présence des colonnes obligatoires : Nom, Prénom, N° CP
                let importResult = try await parseExcelFile(data: data)
                
                // Le backend a déjà créé les conducteurs dans SharePoint
                // On synchronise pour récupérer les nouveaux conducteurs
                if importResult.success {
                    let driversCountBefore = vm.store.drivers.count
                    Logger.info("Import Excel réussi, synchronisation des conducteurs depuis SharePoint... (avant: \(driversCountBefore) conducteurs)", category: "ImportExcel")
                    
                    // Attendre un court délai pour laisser le backend terminer la création dans SharePoint
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes
                    
                    // Synchroniser les conducteurs depuis SharePoint pour récupérer ceux qui viennent d'être importés
                    await vm.store.syncDriversBidirectional()
                    
                    // Si aucun nouveau conducteur n'a été trouvé, réessayer une fois après un délai supplémentaire
                    let driversCountAfterFirstSync = vm.store.drivers.count
                    if driversCountAfterFirstSync == driversCountBefore {
                        Logger.info("Aucun nouveau conducteur détecté lors de la première synchronisation, nouvelle tentative...", category: "ImportExcel")
                        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 secondes supplémentaires
                        await vm.store.syncDriversBidirectional()
                    }
                    
                    let driversCountAfter = vm.store.drivers.count
                    let newDriversCount = driversCountAfter - driversCountBefore
                    
                    if newDriversCount > 0 {
                        Logger.success("Synchronisation terminée : \(newDriversCount) nouveau(x) conducteur(s) récupéré(s) depuis SharePoint (total: \(driversCountAfter))", category: "ImportExcel")
                    } else {
                        Logger.warning("Synchronisation terminée mais aucun nouveau conducteur détecté (avant: \(driversCountBefore), après: \(driversCountAfter)). Les conducteurs peuvent apparaître après une synchronisation manuelle.", category: "ImportExcel")
                    }
                }
                
                // Afficher le résultat de l'import
                await MainActor.run {
                    if let results = importResult.results {
                        importResults = results
                        importSuccess = results.imported > 0
                        importError = nil
                    } else {
                        importResults = nil
                        importSuccess = true
                        importError = nil
                    }
                    showingResult = true
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    importSuccess = false
                    importResults = nil
                    
                    // Gérer spécifiquement l'erreur d'authentification
                    if let importErr = error as? ImportError,
                       case .authenticationRequired(let message) = importErr {
                        // Erreur d'authentification : l'utilisateur a été déconnecté automatiquement
                        // L'app va automatiquement rediriger vers LoginView grâce à WebAuthService
                        self.importError = message
                    } else {
                        // Autres erreurs : améliorer les messages d'erreur
                        var errorMsg = error.localizedDescription
                        
                        // Messages spécifiques pour les colonnes manquantes
                        if errorMsg.localizedCaseInsensitiveContains("prénom") ||
                           errorMsg.localizedCaseInsensitiveContains("prenom") ||
                           errorMsg.localizedCaseInsensitiveContains("firstname") {
                            errorMsg = "Colonne \"Prénom\" manquante ou invalide.\n\n" +
                                      "Le fichier Excel doit contenir une colonne \"Prénom\" (ou variantes : \"Prenom\", \"Firstname\", \"First name\").\n\n" +
                                      errorMsg
                        } else if errorMsg.localizedCaseInsensitiveContains("cp") ||
                                  errorMsg.localizedCaseInsensitiveContains("numéro") ||
                                  errorMsg.localizedCaseInsensitiveContains("numero") {
                            errorMsg = "Colonne \"N° CP\" manquante ou invalide.\n\n" +
                                      "Le fichier Excel doit contenir une colonne \"N° CP\" (ou variantes : \"CP Number\", \"CP\", \"Numéro CP\", \"N CP\").\n\n" +
                                      errorMsg
                        } else if errorMsg.localizedCaseInsensitiveContains("nom") &&
                                  !errorMsg.localizedCaseInsensitiveContains("prénom") &&
                                  !errorMsg.localizedCaseInsensitiveContains("cp") {
                            errorMsg = "Colonne \"Nom\" manquante ou invalide.\n\n" +
                                      "Le fichier Excel doit contenir une colonne \"Nom\".\n\n" +
                                      errorMsg
                        }
                        
                        importError = APIErrorHandler.formatErrorMessage(errorMsg)
                    }
                    
                    showingResult = true
                    isImporting = false
                }
            }
        }
    }
    
    /// Crée un JSONDecoder avec une stratégie de décodage de dates flexible
    /// Accepte plusieurs formats de dates :
    /// - ISO8601 complet ("2025-09-21T11:02:00Z")
    /// - ISO8601 sans fractions ("2025-09-21T11:02:00Z")
    /// - Format date simple YYYY-MM-DD ("1899-12-30", "1900-01-13")
    /// - Format français DD/MM/YYYY ("15/09/2023", "10/03/2024")
    /// - Timestamp numérique (nombre de secondes depuis 1970)
    /// - Returns: Un JSONDecoder configuré
    private func createFlexibleJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        
        // Stratégie personnalisée pour accepter plusieurs formats de dates
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            
            // Essayer d'abord de décoder comme un nombre (timestamp)
            if let timestamp = try? container.decode(TimeInterval.self) {
                // Timestamp en secondes depuis 1970
                let date = Date(timeIntervalSince1970: timestamp)
                Logger.debug("Date décodée depuis timestamp: \(timestamp) → \(date)", category: "ImportExcel")
                return date
            }
            
            // Sinon, essayer comme une chaîne
            let dateString = try container.decode(String.self)
            Logger.debug("Tentative de décodage de date depuis string: '\(dateString)'", category: "ImportExcel")
            
            // Essayer d'abord le format ISO8601 complet (avec heure et timezone)
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                Logger.debug("Date décodée en ISO8601 avec fractions: \(date)", category: "ImportExcel")
                return date
            }
            
            // Essayer le format ISO8601 sans fractions de secondes
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                Logger.debug("Date décodée en ISO8601 sans fractions: \(date)", category: "ImportExcel")
                return date
            }
            
            // Essayer le format date simple (YYYY-MM-DD)
            let dateOnlyFormatter = DateFormatter()
            dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
            dateOnlyFormatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
            dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = dateOnlyFormatter.date(from: dateString) {
                // Rejeter les dates suspectes en 1900 (probablement des erreurs de conversion Excel)
                // Les dates Excel mal converties apparaissent souvent comme "1900-01-XX"
                let calendar = Calendar.current
                let year = calendar.component(.year, from: date)
                if year == 1900 {
                    Logger.warning("Date suspecte rejetée (probable erreur de conversion Excel): '\(dateString)' → \(date)", category: "ImportExcel")
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Date suspecte '\(dateString)' (année 1900) - probablement une erreur de conversion Excel. Le backend doit corriger la conversion des dates Excel."
                    )
                }
                Logger.debug("Date décodée en YYYY-MM-DD: \(date)", category: "ImportExcel")
                return date
            }
            
            // Essayer le format français (DD/MM/YYYY) - utilisé dans les fichiers Excel français
            let frenchDateFormatter = DateFormatter()
            frenchDateFormatter.dateFormat = "dd/MM/yyyy"
            frenchDateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
            frenchDateFormatter.locale = Locale(identifier: "fr_FR")
            if let date = frenchDateFormatter.date(from: dateString) {
                Logger.debug("Date décodée en DD/MM/YYYY: \(date)", category: "ImportExcel")
                return date
            }
            
            // Essayer d'autres formats possibles
            // Format avec slash inversé (MM/DD/YYYY - format américain)
            let usDateFormatter = DateFormatter()
            usDateFormatter.dateFormat = "MM/dd/yyyy"
            usDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            usDateFormatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = usDateFormatter.date(from: dateString) {
                Logger.debug("Date décodée en MM/DD/YYYY: \(date)", category: "ImportExcel")
                return date
            }
            
            // Essayer avec des formats avec heures (si le backend ajoute une heure)
            let dateTimeFormatter = DateFormatter()
            dateTimeFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
            dateTimeFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            dateTimeFormatter.locale = Locale(identifier: "fr_FR")
            if let date = dateTimeFormatter.date(from: dateString) {
                Logger.debug("Date décodée en DD/MM/YYYY HH:mm:ss: \(date)", category: "ImportExcel")
                return date
            }
            
            // Si aucun format ne fonctionne, logger l'erreur et lancer une exception
            Logger.error("Impossible de décoder la date '\(dateString)' - aucun format reconnu", category: "ImportExcel")
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Date string '\(dateString)' ne correspond à aucun format attendu (ISO8601, YYYY-MM-DD, DD/MM/YYYY, MM/DD/YYYY, ou timestamp)"
            )
        }
        
        return decoder
    }
    
    /// Parse le fichier Excel (envoie au backend pour traitement et validation)
    /// Le backend valide la présence des colonnes obligatoires : Nom, Prénom, N° CP
    /// Retourne les résultats de l'import avec les détails des erreurs
    private func parseExcelFile(data: Data) async throws -> ImportResponse {
        // Envoyer le fichier au backend qui le traitera
        guard BackendConfig.isConfigured else {
            Logger.error("Backend non configuré", category: "ImportExcel")
            throw ImportError.backendNotConfigured
        }
        
        // Vérifier que l'utilisateur est authentifié ET que le token est valide
        guard WebAuthService.shared.isAuthenticated else {
            Logger.warning("Utilisateur non authentifié pour l'import Excel", category: "ImportExcel")
            await WebAuthService.shared.logout()
            throw ImportError.authenticationRequired("Votre session a expiré. Veuillez vous reconnecter.")
        }
        
        // Vérifier que le token est valide (non expiré)
        guard WebAuthService.shared.isTokenValid() else {
            Logger.warning("Token JWT expiré pour l'import Excel", category: "ImportExcel")
            await WebAuthService.shared.logout()
            throw ImportError.authenticationRequired("Votre session a expiré. Veuillez vous reconnecter.")
        }
        
        // Obtenir le token JWT d'authentification web (pas le token SharePoint)
        // Utiliser getValidToken() qui vérifie aussi l'expiration
        guard let jwtToken = WebAuthService.shared.getValidToken() else {
            Logger.error("Token JWT manquant ou expiré", category: "ImportExcel")
            await WebAuthService.shared.logout()
            throw ImportError.authenticationRequired("Votre session a expiré. Veuillez vous reconnecter.")
        }
        
        // Construire l'URL de manière sécurisée
        let endpointURL = "\(BackendConfig.backendURL)/api/drivers/import/excel"
        Logger.info("Envoi du fichier Excel à l'endpoint: \(endpointURL)", category: "ImportExcel")
        
        guard let url = URL(string: endpointURL) else {
            Logger.error("URL invalide: \(endpointURL)", category: "ImportExcel")
            throw ImportError.backendError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60 // Timeout de 60 secondes pour les gros fichiers
        
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
        
        Logger.info("Envoi de la requête d'import Excel (taille: \(data.count) bytes)", category: "ImportExcel")
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            Logger.error("Réponse HTTP invalide", category: "ImportExcel")
            throw ImportError.backendError
        }
        
        Logger.info("Réponse reçue: HTTP \(httpResponse.statusCode)", category: "ImportExcel")
        
        // Gérer les codes d'erreur HTTP (spécifiquement l'erreur 401)
        guard httpResponse.statusCode == 200 else {
            // Gérer spécifiquement l'erreur 401 (token expiré)
            if httpResponse.statusCode == 401 {
                // Utiliser le handler centralisé pour gérer l'erreur 401
                do {
                    let errorMessage = try await APIErrorHandler.handleHTTPError(
                        statusCode: httpResponse.statusCode,
                        data: responseData
                    )
                    throw ImportError.authenticationRequired(errorMessage)
                } catch APIError.authenticationRequired(let message) {
                    // L'utilisateur a été déconnecté automatiquement
                    throw ImportError.authenticationRequired(message)
                } catch {
                    throw ImportError.authenticationRequired("Votre session a expiré. Veuillez vous reconnecter.")
                }
            }
            
            // Autres erreurs HTTP
            do {
                let errorMessage = try await APIErrorHandler.handleHTTPError(
                    statusCode: httpResponse.statusCode,
                    data: responseData
                )
                throw ImportError.importFailed(errorMessage)
            } catch APIError.authenticationRequired(let message) {
                // Si c'est une erreur d'authentification (ne devrait pas arriver ici car déjà géré plus haut)
                throw ImportError.authenticationRequired(message)
            } catch {
                // En cas d'erreur dans le handler, utiliser un message par défaut
                let errorMessage = String(data: responseData, encoding: .utf8) ?? "Erreur HTTP \(httpResponse.statusCode)"
                throw ImportError.importFailed(errorMessage)
            }
        }
        
        // Logger la réponse brute pour diagnostic
        if let responseString = String(data: responseData, encoding: .utf8) {
            Logger.debug("Réponse backend (premiers 500 caractères): \(String(responseString.prefix(500)))", category: "ImportExcel")
        }
        
        // Parser la réponse avec un décodeur flexible pour les dates
        let decoder = createFlexibleJSONDecoder()
        let result = try decoder.decode(ImportResponse.self, from: responseData)
        
        // Logger les dates des conducteurs importés pour diagnostic
        if let drivers = result.results?.drivers {
            for driver in drivers.prefix(5) {
                if let date = driver.triennialStart {
                    Logger.debug("Conducteur '\(driver.name)': date décodée = \(date) (format ISO: \(ISO8601DateFormatter().string(from: date)))", category: "ImportExcel")
                } else {
                    Logger.debug("Conducteur '\(driver.name)': pas de date", category: "ImportExcel")
                }
            }
        }
        
        Logger.info("Import Excel terminé - Succès: \(result.success), Message: \(result.message)", category: "ImportExcel")
        
        if !result.success {
            // Améliorer le message d'erreur pour être plus explicite
            var errorMessage = result.message
            
            // Si le message contient des informations sur les colonnes manquantes, les mettre en évidence
            if errorMessage.localizedCaseInsensitiveContains("prénom") || 
               errorMessage.localizedCaseInsensitiveContains("prenom") ||
               errorMessage.localizedCaseInsensitiveContains("firstname") {
                errorMessage = "Colonne \"Prénom\" manquante ou invalide. " + errorMessage
            }
            
            if errorMessage.localizedCaseInsensitiveContains("cp") ||
               errorMessage.localizedCaseInsensitiveContains("numéro") ||
               errorMessage.localizedCaseInsensitiveContains("numero") {
                errorMessage = "Colonne \"N° CP\" manquante ou invalide. " + errorMessage
            }
            
            if errorMessage.localizedCaseInsensitiveContains("nom") {
                errorMessage = "Colonne \"Nom\" manquante ou invalide. " + errorMessage
            }
            
            throw ImportError.importFailed(errorMessage)
        }
        
        // Retourner la réponse complète avec les résultats détaillés
        // Le backend a déjà créé les conducteurs dans SharePoint
        // On déclenchera une synchronisation pour les récupérer si nécessaire
        return result
    }
}

// MARK: - Types d'erreur
enum ImportError: LocalizedError {
    case fileAccessDenied
    case backendNotConfigured
    case backendError
    case importFailed(String)
    case authenticationRequired(String)
    
    var errorDescription: String? {
        switch self {
        case .fileAccessDenied:
            return "Accès au fichier refusé"
        case .backendNotConfigured:
            return "Backend non configuré"
        case .backendError:
            return "Erreur lors de la communication avec le backend"
        case .importFailed(let message):
            return APIErrorHandler.formatErrorMessage(message)
        case .authenticationRequired(let message):
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
    let drivers: [ImportedDriver]?  // Liste des conducteurs importés (si disponible)
}

struct ImportedDriver: Codable, Identifiable {
    let id: UUID?
    let name: String
    let firstName: String?
    let cpNumber: String?
    let triennialStart: Date?
}

// MARK: - Vue de résultat d'import

struct ImportResultView: View {
    let success: Bool
    let results: ImportResults?
    let error: String?
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // En-tête avec icône
                    headerView
                    
                    if let error = error {
                        errorView(error)
                    } else if let results = results {
                        resultsView(results)
                    } else {
                        successView
                    }
                }
                .padding()
            }
            .navigationTitle("Résultat de l'import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") {
                        onDismiss()
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - En-tête
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(success ? .green : .orange)
            
            Text(success ? "Import réussi" : "Import terminé")
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding(.vertical)
    }
    
    // MARK: - Vue de succès simple
    
    private var successView: some View {
        VStack(spacing: 16) {
            Text("✅ Les conducteurs ont été importés avec succès")
                .font(.headline)
                .foregroundStyle(.green)
                .multilineTextAlignment(.center)
            
            Text("Les conducteurs sont maintenant disponibles dans votre liste.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Vue de résultats détaillés
    
    private func resultsView(_ results: ImportResults) -> some View {
        VStack(spacing: 20) {
            // Statistiques
            statisticsView(results)
            
            // Liste des conducteurs importés (si disponible)
            if let drivers = results.drivers, !drivers.isEmpty {
                importedDriversList(drivers)
            }
            
            // Liste des erreurs
            if !results.errors.isEmpty {
                errorsList(results.errors)
            }
        }
    }
    
    // MARK: - Statistiques
    
    private func statisticsView(_ results: ImportResults) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatCard(
                    title: "Importés",
                    value: "\(results.imported)",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                if results.skipped > 0 {
                    StatCard(
                        title: "Ignorés",
                        value: "\(results.skipped)",
                        color: .orange,
                        icon: "exclamationmark.triangle.fill"
                    )
                }
                
                if !results.errors.isEmpty {
                    StatCard(
                        title: "Erreurs",
                        value: "\(results.errors.count)",
                        color: .red,
                        icon: "xmark.circle.fill"
                    )
                }
            }
            
            Text("Total traité : \(results.total) ligne(s)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Liste des conducteurs importés
    
    private func importedDriversList(_ drivers: [ImportedDriver]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.green)
                Text("Conducteurs importés")
                    .font(.headline)
            }
            
            ForEach(drivers.prefix(20)) { driver in
                DriverRow(driver: driver)
            }
            
            if drivers.count > 20 {
                Text("... et \(drivers.count - 20) autre(s) conducteur(s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 32)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Liste des erreurs
    
    private func errorsList(_ errors: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text("Erreurs rencontrées")
                    .font(.headline)
            }
            
            ForEach(Array(errors.prefix(10).enumerated()), id: \.offset) { index, error in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 24, alignment: .leading)
                    
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 4)
            }
            
            if errors.count > 10 {
                Text("... et \(errors.count - 10) autre(s) erreur(s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 32)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Vue d'erreur
    
    private func errorView(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text("Erreur d'import")
                    .font(.headline)
            }
            
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Carte de statistique

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Ligne de conducteur

struct DriverRow: View {
    let driver: ImportedDriver
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title3)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(driver.fullName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if let cpNumber = driver.cpNumber, !cpNumber.isEmpty {
                    Text("CP: \(cpNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

extension ImportedDriver {
    var fullName: String {
        if let firstName = firstName, !firstName.isEmpty {
            return "\(firstName) \(name)"
        }
        return name
    }
}

