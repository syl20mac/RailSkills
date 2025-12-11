//
//  SharePointSetupView.swift
//  RailSkills
//
//  Vue de configuration SharePoint avec wizard en 3 étapes
//  Permet une configuration guidée et sécurisée de la synchronisation
//

import SwiftUI

/// Vue de configuration SharePoint avec wizard interactif
struct SharePointSetupView: View {
    private let azureADService = AzureADService.shared
    @StateObject private var sharePointService = SharePointSyncService.shared
    @EnvironmentObject private var toastManager: ToastNotificationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: WizardStep = .configure
    @State private var clientSecret: String = ""
    @State private var isTestingConnection: Bool = false
    @State private var testResult: TestResult?
    @State private var showingHelpSheet: Bool = false
    @State private var syncHistory: [SyncHistoryEntry] = []
    
    enum WizardStep: Int, CaseIterable {
        case configure = 0
        case test = 1
        case activate = 2
        
        var title: String {
            switch self {
            case .configure: return "Configuration"
            case .test: return "Test de connexion"
            case .activate: return "Activation"
            }
        }
        
        var icon: String {
            switch self {
            case .configure: return "gear"
            case .test: return "antenna.radiowaves.left.and.right"
            case .activate: return "checkmark.circle"
            }
        }
    }
    
    struct TestResult {
        let success: Bool
        let message: String
        let details: String?
    }
    
    struct SyncHistoryEntry: Identifiable {
        let id = UUID()
        let date: Date
        let status: SyncStatus
        let itemsCount: Int
        
        enum SyncStatus {
            case success
            case partial
            case failed
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // En-tête avec progression
                wizardProgressHeader
                
                // Contenu selon l'étape
                ScrollView {
                    VStack(spacing: 24) {
                        switch currentStep {
                        case .configure:
                            configurationStep
                        case .test:
                            testStep
                        case .activate:
                            activationStep
                        }
                    }
                    .padding()
                }
                
                // Boutons de navigation
                navigationButtons
            }
            .navigationTitle("Configuration SharePoint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingHelpSheet = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(SNCFColors.ceruleen)
                    }
                }
            }
            .sheet(isPresented: $showingHelpSheet) {
                helpSheet
            }
            .onAppear {
                loadSyncHistory()
                // Pré-remplir le secret s'il existe
                if let existingSecret = SecretManager.shared.getClientSecret() {
                    clientSecret = existingSecret
                }
            }
        }
    }
    
    // MARK: - Wizard Progress Header
    
    private var wizardProgressHeader: some View {
        VStack(spacing: 16) {
            // Indicateur de progression
            HStack(spacing: 8) {
                ForEach(WizardStep.allCases, id: \.self) { step in
                    stepIndicator(for: step)
                    
                    if step != WizardStep.allCases.last {
                        Rectangle()
                            .fill(step.rawValue < currentStep.rawValue ? SNCFColors.menthe : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            .padding(.horizontal)
            
            // Titre de l'étape actuelle
            VStack(spacing: 4) {
                Text(currentStep.title)
                    .font(.avenirTitle2)
                    .fontWeight(.bold)
                
                Text("Étape \(currentStep.rawValue + 1) sur \(WizardStep.allCases.count)")
                    .font(.avenirCaption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical)
        .background(Color(uiColor: .secondarySystemBackground))
    }
    
    private func stepIndicator(for step: WizardStep) -> some View {
        ZStack {
            Circle()
                .fill(step.rawValue <= currentStep.rawValue ? SNCFColors.menthe : Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
            
            if step.rawValue < currentStep.rawValue {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Image(systemName: step.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(step == currentStep ? .white : .secondary)
            }
        }
    }
    
    // MARK: - Step 1: Configuration
    
    private var configurationStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Info card
            infoCard(
                icon: "info.circle.fill",
                title: "Client Secret Azure AD",
                description: "Le Client Secret permet à l'application d'accéder automatiquement à SharePoint pour synchroniser les données de manière sécurisée.",
                color: SNCFColors.ceruleen
            )
            
            // Saisie du Client Secret
            VStack(alignment: .leading, spacing: 12) {
                Text("Client Secret")
                    .font(.avenirHeadline)
                
                SecureField("Saisissez le Client Secret", text: $clientSecret)
                    .textFieldStyle(.roundedBorder)
                    .font(.avenirBody)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                if !clientSecret.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(SNCFColors.menthe)
                        Text("Secret saisi (\(clientSecret.count) caractères)")
                            .font(.avenirCaption)
                            .foregroundStyle(SNCFColors.menthe)
                    }
                }
            }
            .padding()
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            
            // Informations de configuration
            VStack(alignment: .leading, spacing: 12) {
                Text("Configuration Azure AD")
                    .font(.avenirHeadline)
                
                configInfoRow(label: "Tenant ID", value: "4a7c8238-5799-4b16-9fc6-9ad8fce5a7d9")
                configInfoRow(label: "App ID", value: "bd394412-97bf-4513-a59f-e023b010dff7")
                configInfoRow(label: "Site SharePoint", value: "sncf.sharepoint.com:/sites/railskillsgrpo365")
            }
            .padding()
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    private func configInfoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.avenirCaption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.avenirFootnote)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
    }
    
    // MARK: - Step 2: Test
    
    private var testStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Info card
            infoCard(
                icon: "antenna.radiowaves.left.and.right",
                title: "Test de connexion",
                description: "Nous allons maintenant tester la connexion à SharePoint avec le Client Secret fourni.",
                color: SNCFColors.safran
            )
            
            // Zone de test
            VStack(spacing: 16) {
                if isTestingConnection {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Test de connexion en cours...")
                            .font(.avenirBody)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if let result = testResult {
                    testResultView(result: result)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "antenna.radiowaves.left.and.right.circle")
                            .font(.system(size: 60))
                            .foregroundStyle(SNCFColors.ceruleen.opacity(0.5))
                        
                        Text("Prêt à tester")
                            .font(.avenirHeadline)
                        
                        Text("Cliquez sur 'Tester la connexion' pour vérifier la configuration")
                            .font(.avenirCaption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: testConnection) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Tester la connexion")
                            }
                            .font(.avenirHeadline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(SNCFColors.ceruleen)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    private func testResultView(result: TestResult) -> some View {
        VStack(spacing: 16) {
            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(result.success ? SNCFColors.menthe : SNCFColors.corail)
            
            Text(result.success ? "Connexion réussie !" : "Échec de connexion")
                .font(.avenirTitle2)
                .fontWeight(.bold)
            
            Text(result.message)
                .font(.avenirBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if let details = result.details {
                Text(details)
                    .font(.avenirCaption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(8)
            }
            
            if !result.success {
                Button(action: testConnection) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Réessayer")
                    }
                    .font(.avenirBody)
                    .foregroundStyle(SNCFColors.ceruleen)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(SNCFColors.ceruleen.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Step 3: Activation
    
    private var activationStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Success card
            infoCard(
                icon: "checkmark.circle.fill",
                title: "Configuration terminée",
                description: "SharePoint est maintenant configuré et prêt à synchroniser vos données.",
                color: SNCFColors.menthe
            )
            
            // Historique de synchronisation
            if !syncHistory.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Historique de synchronisation")
                        .font(.avenirHeadline)
                    
                    ForEach(syncHistory.prefix(5)) { entry in
                        syncHistoryRow(entry: entry)
                    }
                }
                .padding()
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            }
            
            // Actions disponibles
            VStack(spacing: 12) {
                Text("Actions disponibles")
                    .font(.avenirHeadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                actionButton(
                    icon: "arrow.clockwise.circle.fill",
                    title: "Synchroniser maintenant",
                    description: "Lance une synchronisation manuelle",
                    color: SNCFColors.ceruleen
                ) {
                    // Navigation vers SharePointSyncView
                    dismiss()
                }
                
                actionButton(
                    icon: "gearshape.fill",
                    title: "Synchronisation automatique",
                    description: "Active la sync en arrière-plan",
                    color: SNCFColors.menthe
                ) {
                    // Toggle auto-sync
                }
            }
        }
    }
    
    private func syncHistoryRow(entry: SyncHistoryEntry) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(colorForStatus(entry.status))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(DateFormatHelper.formatDate(entry.date, style: .medium))
                    .font(.avenirCaption)
                    .foregroundStyle(.primary)
                
                Text("\(entry.itemsCount) élément(s) synchronisé(s)")
                    .font(.avenirFootnote)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: iconForStatus(entry.status))
                .foregroundStyle(colorForStatus(entry.status))
        }
        .padding(.vertical, 8)
    }
    
    private func colorForStatus(_ status: SyncHistoryEntry.SyncStatus) -> Color {
        switch status {
        case .success: return SNCFColors.menthe
        case .partial: return SNCFColors.safran
        case .failed: return SNCFColors.corail
        }
    }
    
    private func iconForStatus(_ status: SyncHistoryEntry.SyncStatus) -> String {
        switch status {
        case .success: return "checkmark.circle.fill"
        case .partial: return "exclamationmark.triangle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    private func actionButton(icon: String, title: String, description: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.avenirHeadline)
                        .foregroundStyle(.primary)
                    
                    Text(description)
                        .font(.avenirCaption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep != .configure {
                Button(action: previousStep) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Précédent")
                    }
                    .font(.avenirBody)
                    .foregroundStyle(SNCFColors.ceruleen)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(SNCFColors.ceruleen.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            Button(action: nextStep) {
                HStack {
                    Text(currentStep == .activate ? "Terminer" : "Suivant")
                    if currentStep != .activate {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.avenirHeadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canProceed ? SNCFColors.ceruleen : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!canProceed)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
    }
    
    // MARK: - Helper Views
    
    private func infoCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.avenirHeadline)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.avenirCaption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var helpSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    helpSection(
                        title: "Où trouver le Client Secret ?",
                        steps: [
                            "Connectez-vous au portail Azure (portal.azure.com)",
                            "Accédez à Azure Active Directory → App registrations",
                            "Sélectionnez l'application RailSkills",
                            "Dans 'Certificates & secrets', copiez le Client Secret"
                        ]
                    )
                    
                    helpSection(
                        title: "Sécurité du Client Secret",
                        steps: [
                            "Le Client Secret est stocké de manière sécurisée dans la Keychain iOS",
                            "Il n'est jamais transmis en clair",
                            "Seul l'administrateur Azure peut le régénérer",
                            "Ne le partagez jamais avec des personnes non autorisées"
                        ]
                    )
                    
                    helpSection(
                        title: "Résolution des problèmes",
                        steps: [
                            "Vérifiez que le Client Secret est correct (respectez la casse)",
                            "Assurez-vous que votre iPad a une connexion Internet",
                            "Vérifiez que les permissions SharePoint sont configurées",
                            "Contactez l'administrateur si le problème persiste"
                        ]
                    )
                }
                .padding()
            }
            .navigationTitle("Aide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        showingHelpSheet = false
                    }
                }
            }
        }
    }
    
    private func helpSection(title: String, steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.avenirHeadline)
            
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1).")
                        .font(.avenirBody)
                        .foregroundStyle(SNCFColors.ceruleen)
                        .fontWeight(.bold)
                    
                    Text(step)
                        .font(.avenirBody)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    // MARK: - Logic
    
    private var canProceed: Bool {
        switch currentStep {
        case .configure:
            return !clientSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .test:
            return testResult?.success == true
        case .activate:
            return true
        }
    }
    
    private func nextStep() {
        switch currentStep {
        case .configure:
            // Sauvegarder le secret
            try? SecretManager.shared.saveClientSecret(clientSecret)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                currentStep = .test
            }
            Logger.info("Configuration Azure AD enregistrée", category: "SharePointSetup")
            
        case .test:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                currentStep = .activate
            }
            
        case .activate:
            toastManager.show("Configuration SharePoint terminée avec succès", type: .success)
            dismiss()
        }
    }
    
    private func previousStep() {
        guard let previousStep = WizardStep(rawValue: currentStep.rawValue - 1) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentStep = previousStep
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        testResult = nil
        
        Task {
            do {
                // Tester la récupération de l'ID du site
                let siteId = try await sharePointService.getSiteId()
                
                await MainActor.run {
                    testResult = TestResult(
                        success: true,
                        message: "La connexion à SharePoint a été établie avec succès",
                        details: "Site ID: \(siteId.prefix(20))..."
                    )
                    isTestingConnection = false
                    Logger.success("Test de connexion SharePoint réussi", category: "SharePointSetup")
                }
            } catch {
                await MainActor.run {
                    testResult = TestResult(
                        success: false,
                        message: "Impossible de se connecter à SharePoint",
                        details: error.localizedDescription
                    )
                    isTestingConnection = false
                    Logger.error("Échec du test de connexion SharePoint: \(error.localizedDescription)", category: "SharePointSetup")
                }
            }
        }
    }
    
    private func loadSyncHistory() {
        // Charger l'historique depuis UserDefaults ou autre source
        // Pour l'instant, données d'exemple
        if let lastSyncDate = sharePointService.lastSyncDate {
            syncHistory = [
                SyncHistoryEntry(date: lastSyncDate, status: .success, itemsCount: 12)
            ]
        }
    }
}

#Preview {
    SharePointSetupView()
        .environmentObject(ToastNotificationManager())
}


