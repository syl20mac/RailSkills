//
//  OnboardingView.swift
//  RailSkills
//
//  Assistant d'intégration simplifié pour les nouveaux utilisateurs
//  Combine création de compte, profil CTT et configuration en un seul flux
//

import SwiftUI

/// Vue d'onboarding simplifiée pour les nouveaux utilisateurs
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = WebAuthService.shared
    @StateObject private var identityService = SNCFIdentityService.shared
    @EnvironmentObject private var toastManager: ToastNotificationManager
    
    // MARK: - États du flux
    
    /// Étape actuelle du processus (0-3)
    @State private var currentStep: Int = 0
    
    // Étape 1 : Informations de base
    @State private var email: String = ""
    @State private var fullName: String = ""
    @State private var hasAutoFilledName: Bool = false
    @State private var cguAccepted: Bool = false
    @State private var showingCGU: Bool = false
    @State private var emailError: String? = nil
    
    // Étape 2 : Vérification email
    @State private var verificationCode: String = ""
    @State private var isCodeSent: Bool = false
    
    // Étape 3 : Mot de passe
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    // États généraux
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showingSuccess: Bool = false
    
    // Callback de fin
    var onComplete: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fond avec gradient SNCF
                LinearGradient(
                    colors: [SNCFColors.ceruleen.opacity(0.05), SNCFColors.lavande.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Indicateur de progression
                    progressIndicator
                        .padding(.top, 20)
                        .padding(.horizontal)
                    
                    // Contenu de l'étape actuelle
                    TabView(selection: $currentStep) {
                        step1InfosView.tag(0)
                        step2VerificationView.tag(1)
                        step3PasswordView.tag(2)
                        step4SuccessView.tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                }
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if currentStep < 3 {
                        Button("Annuler") {
                            dismiss()
                        }
                    }
                }
            }
            .alert("Erreur", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showingCGU) {
                NavigationStack {
                    TermsOfServiceView()
                }
            }
        }
    }
    
    // MARK: - Titre de l'étape
    
    private var stepTitle: String {
        switch currentStep {
        case 0: return "Bienvenue"
        case 1: return "Vérification"
        case 2: return "Sécurité"
        case 3: return "Terminé !"
        default: return "Configuration"
        }
    }
    
    // MARK: - Indicateur de progression
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<4) { step in
                Capsule()
                    .fill(step <= currentStep ? SNCFColors.ceruleen : Color.secondary.opacity(0.3))
                    .frame(height: 4)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Validation Email
    
    /// Vérifie si l'email est un email @sncf.fr valide
    private var isSNCFEmail: Bool {
        email.isSNCFEmailValid
    }
    
    /// Valide l'email et met à jour le message d'erreur
    private func validateEmail() -> Bool {
        let validation = email.isValidSNCFEmail()
        emailError = validation.errorMessage
        return validation.isValid
    }
    
    /// Extrait le nom depuis l'email (prenom.nom@sncf.fr → Prénom NOM)
    private var extractedNameFromEmail: String? {
        guard email.contains("@") else { return nil }
        
        let localPart = email.components(separatedBy: "@").first ?? ""
        
        // Patterns courants : prenom.nom, prenom-nom, pnom, etc.
        let separators = CharacterSet(charactersIn: ".-_")
        let parts = localPart.components(separatedBy: separators)
        
        guard parts.count >= 2 else { return nil }
        
        // Formater : Prénom NOM
        let firstName = parts[0].capitalized
        let lastName = parts.dropFirst().joined(separator: " ").uppercased()
        
        return "\(firstName) \(lastName)"
    }
    
    // MARK: - Étape 1 : Informations de base
    
    private var step1InfosView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Icône
                ZStack {
                    Circle()
                        .fill(SNCFColors.ceruleen.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(SNCFColors.ceruleen)
                }
                .padding(.top, 40)
                
                // Texte d'introduction
                VStack(spacing: 8) {
                    Text("Créez votre profil CTT")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text("Saisissez vos informations pour configurer RailSkills et activer la synchronisation")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Formulaire
                VStack(spacing: 20) {
                    // Email avec détection automatique
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label("Email professionnel", systemImage: "envelope.fill")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            // Badge de validation domaine SNCF
                            if isSNCFEmail {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.seal.fill")
                                    Text("SNCF")
                                }
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(SNCFColors.menthe)
                                .cornerRadius(8)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        
                        TextField("prenom.nom@sncf.fr", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        emailError != nil ? SNCFColors.corail : 
                                        (isSNCFEmail ? SNCFColors.menthe : Color.clear), 
                                        lineWidth: 2
                                    )
                            )
                            .onChange(of: email) { _, newValue in
                                // Valider l'email en temps réel
                                if !newValue.isEmpty {
                                    _ = validateEmail()
                                } else {
                                    emailError = nil
                                }
                                
                                // Auto-remplir le nom si email SNCF détecté
                                if !hasAutoFilledName, let extractedName = extractedNameFromEmail {
                                    withAnimation(.spring(response: 0.3)) {
                                        fullName = extractedName
                                        hasAutoFilledName = true
                                    }
                                }
                            }
                        
                        // Message d'aide
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundStyle(SNCFColors.ceruleen)
                            Text("Seules les adresses email @sncf.fr sont autorisées")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 1)
                        
                        // Message d'erreur
                        if let error = emailError {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(SNCFColors.corail)
                                Text(error)
                                    .font(.caption2)
                                    .foregroundStyle(SNCFColors.corail)
                            }
                            .padding(.top, 1)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Bouton de suggestion @sncf.fr si email incomplet
                        if !email.isEmpty && !email.contains("@") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("💡 Cliquez pour compléter :")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Button {
                                    withAnimation(.spring(response: 0.2)) {
                                        email = email + "@sncf.fr"
                                        _ = validateEmail()
                                    }
                                } label: {
                                    Text(email + "@sncf.fr")
                                        .font(.caption)
                                        .foregroundStyle(SNCFColors.ceruleen)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(SNCFColors.ceruleen.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    
                    // Nom complet avec auto-remplissage
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Votre nom complet", systemImage: "person.fill")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            // Indicateur d'auto-remplissage
                            if hasAutoFilledName && !fullName.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "wand.and.stars")
                                    Text("Auto")
                                }
                                .font(.caption)
                                .foregroundStyle(SNCFColors.lavande)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        
                        TextField("Jean DUPONT", text: $fullName)
                            .textContentType(.name)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(hasAutoFilledName && !fullName.isEmpty ? SNCFColors.lavande.opacity(0.5) : Color.clear, lineWidth: 1)
                            )
                            .onChange(of: fullName) { _, _ in
                                // Si l'utilisateur modifie le nom, désactiver l'auto-fill
                                // (ne rien faire pour permettre la modification)
                            }
                        
                        if hasAutoFilledName {
                            Text("Nom extrait automatiquement de votre email. Vous pouvez le modifier si nécessaire.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .animation(.spring(response: 0.3), value: isSNCFEmail)
                .animation(.spring(response: 0.3), value: hasAutoFilledName)
                
                // Message d'information sur la visibilité des données
                ModernCard {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.title3)
                            .foregroundStyle(SNCFColors.ceruleen)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Visibilité des données")
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                            
                            Text("Les données saisies dans RailSkills pourront être consultées par votre encadrement pour le suivi triennal réglementaire.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .padding(.horizontal)
                
                // Acceptation des CGU
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Button {
                            cguAccepted.toggle()
                        } label: {
                            Image(systemName: cguAccepted ? "checkmark.square.fill" : "square")
                                .font(.title3)
                                .foregroundStyle(cguAccepted ? SNCFColors.ceruleen : Color.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text("J'accepte les")
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                
                                Button {
                                    showingCGU = true
                                } label: {
                                    Text("Conditions Générales d'Utilisation")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(SNCFColors.ceruleen)
                                        .underline()
                                }
                            }
                            
                            Text("L'utilisation de l'application implique l'acceptation pleine et entière des CGU.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 20)
                
                // Bouton suivant
                Button(action: {
                    Task { await sendVerificationCode() }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            HStack(spacing: 8) {
                                Text("Continuer")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isStep1Valid ? SNCFColors.ceruleen : Color.secondary.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isStep1Valid || isLoading)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }
    
    private var isStep1Valid: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedName = fullName.trimmingCharacters(in: .whitespaces)
        
        // Valider l'email @sncf.fr
        let emailValidation = email.isValidSNCFEmail()
        
        return !trimmedEmail.isEmpty &&
               emailValidation.isValid &&
               !trimmedName.isEmpty &&
               trimmedName.count >= 3 &&
               cguAccepted
    }
    
    // MARK: - Étape 2 : Vérification email
    
    private var step2VerificationView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Icône
                ZStack {
                    Circle()
                        .fill(SNCFColors.menthe.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "envelope.badge.shield.half.filled")
                        .font(.system(size: 48))
                        .foregroundStyle(SNCFColors.menthe)
                }
                .padding(.top, 40)
                
                // Texte
                VStack(spacing: 8) {
                    Text("Vérifiez votre email")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text("Un code de vérification a été envoyé à")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(email)
                        .font(.headline)
                        .foregroundStyle(SNCFColors.ceruleen)
                }
                
                // Code de vérification
                VStack(alignment: .leading, spacing: 8) {
                    Label("Code de vérification", systemImage: "number")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    TextField("123456", text: $verificationCode)
                        .keyboardType(.numberPad)
                        .font(.system(.title, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Renvoyer le code
                Button("Renvoyer le code") {
                    Task { await resendCode() }
                }
                .font(.subheadline)
                .foregroundStyle(SNCFColors.ceruleen)
                .disabled(isLoading)
                
                Spacer(minLength: 20)
                
                // Boutons
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation { currentStep = 0 }
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Retour")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        Task { await verifyCode() }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Vérifier")
                                    .fontWeight(.semibold)
                                Image(systemName: "checkmark")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(verificationCode.count >= 4 ? SNCFColors.menthe : Color.secondary.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(verificationCode.count < 4 || isLoading)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Étape 3 : Mot de passe
    
    private var step3PasswordView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Icône
                ZStack {
                    Circle()
                        .fill(SNCFColors.lavande.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(SNCFColors.lavande)
                }
                .padding(.top, 40)
                
                // Texte
                VStack(spacing: 8) {
                    Text("Créez votre mot de passe")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text("Choisissez un mot de passe sécurisé pour protéger votre compte")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Formulaire mot de passe
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Mot de passe", systemImage: "lock.fill")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        SecureField("Minimum 8 caractères", text: $password)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Confirmer", systemImage: "lock.rotation")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        SecureField("Retapez le mot de passe", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        
                        // Indicateur de correspondance
                        if !confirmPassword.isEmpty {
                            HStack {
                                Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(passwordsMatch ? SNCFColors.menthe : SNCFColors.corail)
                                Text(passwordsMatch ? "Les mots de passe correspondent" : "Les mots de passe ne correspondent pas")
                                    .font(.caption)
                                    .foregroundStyle(passwordsMatch ? SNCFColors.menthe : SNCFColors.corail)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 20)
                
                // Bouton créer
                Button(action: {
                    Task { await createAccount() }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Créer mon compte")
                                .fontWeight(.semibold)
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isStep3Valid ? SNCFColors.ceruleen : Color.secondary.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isStep3Valid || isLoading)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }
    
    private var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }
    
    private var isStep3Valid: Bool {
        password.count >= 8 && passwordsMatch
    }
    
    // MARK: - Étape 4 : Succès
    
    private var step4SuccessView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Animation de succès
            ZStack {
                Circle()
                    .fill(SNCFColors.menthe.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(SNCFColors.menthe)
                    .symbolEffect(.bounce, value: showingSuccess)
            }
            
            // Message de succès
            VStack(spacing: 16) {
                Text("Bienvenue, \(fullName.components(separatedBy: " ").first ?? "CTT") !")
                    .font(.title.bold())
                    .foregroundStyle(.primary)
                
                Text("Votre compte est créé et configuré. La synchronisation SharePoint est prête à être utilisée.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Résumé
            VStack(spacing: 12) {
                summaryRow(icon: "envelope.fill", title: "Email", value: email, color: SNCFColors.ceruleen)
                summaryRow(icon: "person.fill", title: "Profil CTT", value: fullName, color: SNCFColors.lavande)
                summaryRow(icon: "cloud.fill", title: "SharePoint", value: "Prêt à synchroniser", color: SNCFColors.menthe)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
            .padding(.horizontal)
            
            Spacer()
            
            // Bouton terminer
            Button(action: {
                onComplete?()
                dismiss()
            }) {
                Text("Commencer à utiliser RailSkills")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(SNCFColors.ceruleen)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .onAppear {
            showingSuccess = true
        }
    }
    
    private func summaryRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(title)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }
    
    // MARK: - Actions
    
    private func sendVerificationCode() async {
        // Valider l'email avant d'envoyer
        guard validateEmail() else {
            errorMessage = emailError ?? "Email invalide"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Enregistrer l'utilisateur et envoyer le code
            _ = try await authService.register(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                cttId: nil
            )
            isCodeSent = true
            withAnimation { currentStep = 1 }
        } catch {
            // Gérer les erreurs serveur (validation email)
            let errorDescription = error.localizedDescription
            if errorDescription.contains("sncf.fr") || errorDescription.contains("autorisées") {
                emailError = errorDescription
                errorMessage = errorDescription
            } else {
                errorMessage = errorDescription
            }
        }
        
        isLoading = false
    }
    
    private func resendCode() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Renvoyer le code en réinscrivant l'utilisateur
            _ = try await authService.register(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                cttId: nil
            )
            toastManager.show("Code renvoyé à \(email)", type: .success)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func verifyCode() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // La méthode verifyCode ne retourne rien, elle lance une exception si invalide
            try await authService.verifyCode(email: email, code: verificationCode)
            withAnimation { currentStep = 2 }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func createAccount() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Vérifier que les CGU sont acceptées
            guard cguAccepted else {
                errorMessage = "Vous devez accepter les Conditions Générales d'Utilisation pour créer votre compte."
                isLoading = false
                return
            }
            
            // 2. Définir le mot de passe et finaliser le compte
            _ = try await authService.setPassword(email: email, code: verificationCode, password: password)
            
            // 3. Configurer automatiquement le profil CTT
            identityService.setIdentity(
                identity: email,
                name: fullName
            )
            
            // 4. Enregistrer l'acceptation des CGU avec la date
            let cguAcceptanceDate = Date()
            UserDefaults.standard.set(true, forKey: "cguAccepted")
            UserDefaults.standard.set(cguAcceptanceDate, forKey: "cguAcceptanceDate")
            UserDefaults.standard.set("3 décembre 2025", forKey: "cguVersionAccepted")
            
            // 5. Afficher l'écran de succès
            withAnimation { currentStep = 3 }
            
            Logger.success("Compte créé et profil CTT configuré pour: \(email). CGU acceptées le \(cguAcceptanceDate)", category: "Onboarding")
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environmentObject(ToastNotificationManager())
}

