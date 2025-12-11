//
//  SettingsView.swift
//  RailSkills
//
//  Vue des paramètres de l'application - Version simplifiée
//  Les options techniques sont masquées par défaut (mode avancé)
//

import SwiftUI
import Foundation

/// Vue des paramètres de l'application
struct SettingsView: View {
    @ObservedObject var vm: ViewModel
    @AppStorage("interactionMode") private var interactionMode: String = InteractionMode.toggle.rawValue
    @State private var previewState: Int = 2
    @EnvironmentObject private var toastManager: ToastNotificationManager
    
    // Mode avancé (pour admins IT) - persisté entre sessions
    // Débloqué par 5 taps sur la version en bas des réglages
    @AppStorage("advancedModeEnabled") private var advancedModeEnabled: Bool = false
    @State private var versionTapCount: Int = 0
    @State private var showingAdvancedModeAlert: Bool = false
    @State private var showingResetAlert: Bool = false
    @State private var isResetting: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                // ═══════════════════════════════════════════
                // SECTION UTILISATEUR : Profil CTT
                // ═══════════════════════════════════════════
                Section {
                    NavigationLink {
                        CTTProfileView()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(SNCFColors.ceruleen.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(SNCFColors.ceruleen)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                if SNCFIdentityService.shared.isAuthenticated {
                                    Text(SNCFIdentityService.shared.sncfName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    Text(SNCFIdentityService.shared.sncfIdentity)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Configurer votre profil")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    Text("Identifiez-vous pour activer la synchronisation")
                                        .font(.caption)
                                        .foregroundStyle(SNCFColors.safran)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Profil CTT")
                }
                
                // ═══════════════════════════════════════════
                // SECTION UTILISATEUR : Mode d'interaction
                // ═══════════════════════════════════════════
                Section {
                    // Prévisualisation
                    VStack(spacing: 16) {
                        Text("Aperçu en temps réel")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        StateInteractionView(
                            state: $previewState,
                            mode: InteractionMode(rawValue: interactionMode) ?? .toggle
                        )
                        
                        Text(stateLabel(for: previewState))
                            .font(.caption)
                            .foregroundStyle(Color.forState(previewState))
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    
                    // Sélection du mode
                    ForEach(InteractionMode.allCases) { mode in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                interactionMode = mode.rawValue
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: mode.icon)
                                    .font(.title3)
                                    .foregroundStyle(interactionMode == mode.rawValue ? SNCFColors.ceruleen : .secondary)
                                    .frame(width: 28)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mode.title)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    
                                    Text(mode.description)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                if interactionMode == mode.rawValue {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(SNCFColors.ceruleen)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Mode d'interaction")
                }
                
                // ═══════════════════════════════════════════
                // SECTION UTILISATEUR : Statistiques
                // ═══════════════════════════════════════════
                if let cl = vm.store.checklist {
                    Section {
                        statRow(icon: "doc.text.fill", label: "Questions avec notes", value: "\(vm.notesCount())", color: SNCFColors.lavande)
                        statRow(icon: "list.bullet.clipboard.fill", label: "Total des questions", value: "\(cl.questions.count)", color: SNCFColors.ceruleen)
                        statRow(icon: "person.2.fill", label: "Conducteurs suivis", value: "\(vm.store.drivers.count)", color: SNCFColors.menthe)
                    } header: {
                        Text("Statistiques")
                    }
                }
                
                // ═══════════════════════════════════════════
                // SECTION UTILISATEUR : Checklists
                // ═══════════════════════════════════════════
                Section {
                    // État des checklists
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Checklist Triennale")
                                .font(.subheadline.weight(.medium))
                            Text(vm.store.checklist != nil ? "Chargée" : "Non chargée")
                                .font(.caption)
                                .foregroundStyle(vm.store.checklist != nil ? SNCFColors.menthe : .secondary)
                        }
                        Spacer()
                        if vm.store.checklist != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(SNCFColors.menthe)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Checklist VP")
                                .font(.subheadline.weight(.medium))
                            Text(vm.store.checklistVP != nil ? "Chargée" : "Non chargée")
                                .font(.caption)
                                .foregroundStyle(vm.store.checklistVP != nil ? SNCFColors.menthe : .secondary)
                        }
                        Spacer()
                        if vm.store.checklistVP != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(SNCFColors.menthe)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Checklist TE")
                                .font(.subheadline.weight(.medium))
                            Text(vm.store.checklistTE != nil ? "Chargée" : "Non chargée")
                                .font(.caption)
                                .foregroundStyle(vm.store.checklistTE != nil ? SNCFColors.menthe : .secondary)
                        }
                        Spacer()
                        if vm.store.checklistTE != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(SNCFColors.menthe)
                        }
                    }
                    
                    // Bouton pour uploader les checklists par défaut (uniquement si SharePoint est configuré)
                    if SharePointSyncService.shared.isConfigured {
                        Button {
                            uploadDefaultChecklists()
                        } label: {
                            HStack {
                                if isUploadingChecklists {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .foregroundStyle(SNCFColors.ceruleen)
                                }
                                Text(isUploadingChecklists ? "Upload en cours..." : "Uploader les checklists VP et TE vers SharePoint")
                                    .font(.subheadline.weight(.medium))
                            }
                        }
                        .disabled(SharePointSyncService.shared.isSyncing || isUploadingChecklists)
                    } else {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text("Configurez SharePoint pour uploader les checklists")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Checklists")
                } footer: {
                    if SharePointSyncService.shared.isConfigured {
                        Text("Les checklists VP et TE seront uploadées vers SharePoint pour être disponibles pour tous les CTT.")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Activez le mode avancé et configurez SharePoint pour uploader les checklists.")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // ═══════════════════════════════════════════
                // SECTION UTILISATEUR : Mode démonstration
                // ═══════════════════════════════════════════
                if UserDefaults.standard.bool(forKey: "demo_mode_enabled") {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .foregroundStyle(SNCFColors.menthe)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Mode démonstration actif")
                                    .font(.subheadline.weight(.medium))
                                Text("Vous utilisez des données de démonstration")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Button(role: .destructive) {
                            disableDemoMode()
                        } label: {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                Text("Désactiver le mode démonstration")
                            }
                        }
                    } header: {
                        Text("Mode démonstration")
                    } footer: {
                        Text("Le mode démonstration utilise des données fictives pour les reviewers Apple. Désactivez-le pour utiliser vos vraies données.")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // ═══════════════════════════════════════════
                // SECTION UTILISATEUR : Compte
                // ═══════════════════════════════════════════
                Section {
                    if WebAuthService.shared.isAuthenticated {
                        if let user = WebAuthService.shared.currentUser {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(SNCFColors.menthe)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.email)
                                        .font(.subheadline.weight(.medium))
                                    Text("Compte vérifié")
                                        .font(.caption)
                                        .foregroundStyle(SNCFColors.menthe)
                                }
                            }
                        }
                        
                        Button(role: .destructive) {
                            Task {
                                await WebAuthService.shared.logout()
                                toastManager.show("Déconnexion réussie", type: .success)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Se déconnecter")
                            }
                        }
                    } else {
                        NavigationLink {
                            LoginView()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.badge.plus")
                                    .foregroundStyle(SNCFColors.ceruleen)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Se connecter")
                                        .font(.subheadline.weight(.medium))
                                    Text("Créer un compte ou se connecter")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Bouton réinitialisation complète
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Réinitialiser l'application")
                        }
                    }
                } header: {
                    Text("Compte")
                } footer: {
                    Text("La réinitialisation supprime toutes les données locales et vous déconnecte.")
                        .foregroundStyle(.secondary)
                }
                
                // ═══════════════════════════════════════════
                // SECTION UTILISATEUR : Partage & Export
                // ═══════════════════════════════════════════
                Section {
                    NavigationLink {
                        SharingView(vm: vm)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(SNCFColors.ceruleen)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Partage & Export")
                                    .font(.subheadline.weight(.medium))
                                Text("Exporter et importer des données")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Partage")
                } footer: {
                    Text("Exportez vos conducteurs en JSON ou CSV, importez depuis un fichier")
                }
                
                // ═══════════════════════════════════════════
                // SECTION PERSONNALISATION
                // ═══════════════════════════════════════════
                Section {
                    NavigationLink {
                        NoteTemplatesManagerView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "note.text")
                                .foregroundStyle(SNCFColors.ceruleen)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Templates de notes")
                                    .font(.subheadline.weight(.medium))
                                Text("Personnaliser les templates rapides")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Personnalisation")
                } footer: {
                    Text("Créez et modifiez vos templates de notes pour une saisie plus rapide")
                }
                
                // ═══════════════════════════════════════════
                // SECTION AVANCÉE (visible uniquement si débloquée)
                // ═══════════════════════════════════════════
                if advancedModeEnabled {
                    Section {
                        // Configuration Azure AD / SharePoint
                        NavigationLink {
                            AzureADConfigView()
                        } label: {
                            advancedRow(
                                icon: "cloud.fill",
                                title: "Configuration SharePoint",
                                subtitle: AzureADService.shared.isConfigured ? "Configuré ✓" : "Non configuré",
                                color: SNCFColors.ceruleen
                            )
                        }
                        
                        // Synchronisation manuelle
                        if SharePointSyncService.shared.isConfigured {
                            NavigationLink {
                                SharePointSyncView(store: vm.store)
                            } label: {
                                advancedRow(
                                    icon: "arrow.triangle.2.circlepath",
                                    title: "Synchronisation manuelle",
                                    subtitle: "Forcer la synchronisation",
                                    color: SNCFColors.menthe
                                )
                            }
                        }
                        
                        // Secret organisationnel
                        NavigationLink {
                            EncryptionKeyManagementView()
                        } label: {
                            advancedRow(
                                icon: "lock.shield.fill",
                                title: "Secret organisationnel",
                                subtitle: "Chiffrement des exports",
                                color: SNCFColors.lavande
                            )
                        }
                        
                        // Configuration API Web
                        NavigationLink {
                            WebAPIConfigView()
                        } label: {
                            advancedRow(
                                icon: "link",
                                title: "Configuration API",
                                subtitle: "URL du serveur backend",
                                color: SNCFColors.safran
                            )
                        }
                        
                        // Désactiver le mode avancé
                        Button {
                            withAnimation {
                                advancedModeEnabled = false
                                toastManager.show("Mode avancé désactivé", type: .info)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "eye.slash")
                                    .foregroundStyle(SNCFColors.corail)
                                Text("Masquer les options avancées")
                                    .foregroundStyle(SNCFColors.corail)
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver.fill")
                            Text("Options avancées")
                        }
                    } footer: {
                        Text("⚠️ Ces options sont réservées aux administrateurs IT. Modifiez-les avec précaution.")
                            .foregroundStyle(SNCFColors.safran)
                    }
                }
                
                // ═══════════════════════════════════════════
                // SECTION LÉGALE : CGU et Mentions
                // ═══════════════════════════════════════════
                Section {
                    NavigationLink {
                        TermsOfServiceView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(SNCFColors.ceruleen)
                                .frame(width: 24)
                            
                            Text("Conditions Générales d'Utilisation")
                                .font(.subheadline)
                        }
                    }
                } header: {
                    Text("Légal")
                }
                
                // ═══════════════════════════════════════════
                // FOOTER : Version (tap secret pour mode avancé)
                // ═══════════════════════════════════════════
                Section {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 8) {
                            Image("railskills-logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .accessibilityLabel("Logo RailSkills")
                            
                            Text("RailSkills v2.0")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if !advancedModeEnabled {
                                Text("Tap \(5 - versionTapCount)x pour options avancées")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .opacity(versionTapCount > 0 ? 1 : 0)
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "wrench.and.screwdriver.fill")
                                    Text("Mode avancé activé")
                                }
                                .font(.caption2)
                                .foregroundStyle(SNCFColors.menthe)
                            }
                        }
                        .onTapGesture {
                            handleVersionTap()
                        }
                        
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .alert("🔧 Mode avancé débloqué", isPresented: $showingAdvancedModeAlert) {
                Button("Activer") {
                    withAnimation {
                        advancedModeEnabled = true
                    }
                }
                Button("Annuler", role: .cancel) {
                    versionTapCount = 0
                }
            } message: {
                Text("Vous allez accéder aux options de configuration avancées. Ces paramètres sont destinés aux administrateurs IT.")
            }
            .alert("⚠️ Réinitialiser l'application ?", isPresented: $showingResetAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Réinitialiser", role: .destructive) {
                    performFullReset()
                }
            } message: {
                Text("Cette action supprimera :\n• Votre profil CTT\n• Tous les conducteurs\n• Toutes les notes\n• Tous les réglages\n\nCette action est irréversible.")
            }
            .alert(uploadAlertTitle, isPresented: $showingUploadAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(uploadAlertMessage)
            }
        }
    }
    
    // MARK: - Désactivation du mode démo
    
    /// Désactive le mode démonstration
    private func disableDemoMode() {
        // Désactiver le mode démo
        UserDefaults.standard.set(false, forKey: "demo_mode_enabled")
        
        // Déconnecter le profil de démo
        Task {
            await WebAuthService.shared.logout()
        }
        
        // Réinitialiser les données de démo
        vm.store.resetAllData()
        
        // Feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        toastManager.show("Mode démonstration désactivé", type: .success)
        Logger.info("Mode démonstration désactivé", category: "SettingsView")
    }
    
    // MARK: - Réinitialisation complète
    
    /// Supprime TOUTES les données locales de l'application
    private func performFullReset() {
        isResetting = true
        
        // 1. Désactiver le mode démo si actif
        UserDefaults.standard.set(false, forKey: "demo_mode_enabled")
        
        // 2. Déconnexion du service web
        Task {
            await WebAuthService.shared.logout()
        }
        
        // 3. Effacer le profil CTT
        SNCFIdentityService.shared.clearIdentity()
        
        // 4. Effacer les tokens de la Keychain
        try? SecretManager.shared.deleteClientSecret()
        
        // 5. Effacer le cache du secret organisationnel
        OrganizationSecretService.shared.clearCache()
        
        // 6. Effacer toutes les données UserDefaults
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        // 7. Réinitialiser le Store (conducteurs, checklist)
        vm.store.resetAllData()
        
        // 8. Feedback et notification
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        isResetting = false
        toastManager.show("Application réinitialisée", type: .success)
        
        Logger.info("Application réinitialisée complètement", category: "SettingsView")
    }
    
    // MARK: - Gestion du tap secret sur la version
    
    private func handleVersionTap() {
        guard !advancedModeEnabled else { return }
        
        versionTapCount += 1
        
        // Feedback haptique léger
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        if versionTapCount >= 5 {
            // Feedback haptique de succès
            let successGenerator = UINotificationFeedbackGenerator()
            successGenerator.notificationOccurred(.success)
            
            showingAdvancedModeAlert = true
        }
        
        // Reset après 3 secondes d'inactivité
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if versionTapCount < 5 {
                withAnimation {
                    versionTapCount = 0
                }
            }
        }
    }
    
    // MARK: - Composants réutilisables
    
    private func statRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
    
    private func advancedRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func stateLabel(for state: Int) -> String {
        switch state {
        case 3: return "Non traité"
        case 2: return "Validé"
        case 1: return "Partiel"
        default: return "Non validé"
        }
    }
    
    // MARK: - Upload des checklists par défaut
    
    @State private var isUploadingChecklists = false
    @State private var uploadAlertTitle = ""
    @State private var uploadAlertMessage = ""
    @State private var showingUploadAlert = false
    
    private func uploadDefaultChecklists() {
        isUploadingChecklists = true
        Task {
            do {
                try await SharePointSyncService.shared.uploadDefaultChecklistsToSharePoint()
                await MainActor.run {
                    isUploadingChecklists = false
                    uploadAlertTitle = "Upload réussi"
                    uploadAlertMessage = "Les checklists VP et TE ont été uploadées vers SharePoint avec succès."
                    showingUploadAlert = true
                    toastManager.show("Checklists uploadées avec succès", type: .success)
                }
            } catch {
                await MainActor.run {
                    isUploadingChecklists = false
                    uploadAlertTitle = "Erreur d'upload"
                    uploadAlertMessage = error.localizedDescription
                    showingUploadAlert = true
                    toastManager.show("Erreur lors de l'upload", type: .error)
                }
            }
        }
    }
}
