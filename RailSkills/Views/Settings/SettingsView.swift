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
                // SECTION UTILISATEUR : Profil
                // ═══════════════════════════════════════════
                Section {
                    NavigationLink {
                        CTTProfileView()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                if OrganizationIdentityService.shared.isAuthenticated {
                                    Text(OrganizationIdentityService.shared.displayName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    Text(OrganizationIdentityService.shared.userId)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Configurer votre profil")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    Text("Identifiez-vous pour activer la synchronisation")
                                        .font(.caption)
                                        .foregroundStyle(Color.orange)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Profil")
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
                                    .foregroundStyle(interactionMode == mode.rawValue ? Color.blue : .secondary)
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
                                        .foregroundStyle(Color.blue)
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
                        statRow(icon: "doc.text.fill", label: "Questions avec notes", value: "\(vm.notesCount())", color: Color.purple)
                        statRow(icon: "list.bullet.clipboard.fill", label: "Total des questions", value: "\(cl.questions.count)", color: Color.blue)
                        statRow(icon: "person.2.fill", label: "Conducteurs suivis", value: "\(vm.store.drivers.count)", color: Color.green)
                    } header: {
                        Text("Statistiques")
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
                                    .foregroundStyle(Color.green)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.email)
                                        .font(.subheadline.weight(.medium))
                                    Text("Compte vérifié")
                                        .font(.caption)
                                        .foregroundStyle(Color.green)
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
                        // N'afficher l'option de connexion que si on n'est PAS en mode local
                        if !AppConfigurationService.shared.isLocalMode {
                            NavigationLink {
                                LoginView()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.badge.plus")
                                        .foregroundStyle(Color.blue)
                                    
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
                // SECTION PERSONNALISATION
                // ═══════════════════════════════════════════
                Section {
                    NavigationLink {
                        NoteTemplatesManagerView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "note.text")
                                .foregroundStyle(Color.blue)
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
                                color: Color.blue
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
                                    color: Color.green
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
                                color: Color.purple
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
                                color: Color.orange
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
                                    .foregroundStyle(Color.red)
                                Text("Masquer les options avancées")
                                    .foregroundStyle(Color.red)
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver.fill")
                            Text("Options avancées")
                        }
                    } footer: {
                        Text("⚠️ Ces options sont réservées aux administrateurs IT. Modifiez-les avec précaution.")
                            .foregroundStyle(Color.orange)
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
                                .foregroundStyle(Color.blue)
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
                                .foregroundStyle(Color.green)
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
                Text("Cette action supprimera :\n• Votre profil\n• Tous les conducteurs\n• Toutes les notes\n• Tous les réglages\n\nCette action est irréversible.")
            }
        }
    }
    
    // MARK: - Réinitialisation complète
    
    /// Supprime TOUTES les données locales de l'application
    private func performFullReset() {
        isResetting = true
        
        // 1. Déconnexion du service web
        Task {
            await WebAuthService.shared.logout()
        }
        
        // 2. Effacer le profil
        OrganizationIdentityService.shared.clearIdentity()
        
        // 3. Effacer les tokens de la Keychain
        try? SecretManager.shared.deleteClientSecret()
        
        // 4. Effacer le cache du secret organisationnel
        OrganizationSecretService.shared.clearCache()
        
        // 5. Effacer toutes les données UserDefaults
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        // 6. Réinitialiser le Store (conducteurs, checklist)
        vm.store.resetAllData()
        
        // 7. Feedback et notification
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
}
