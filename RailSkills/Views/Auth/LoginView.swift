//
//  LoginView.swift
//  RailSkills
//
//  Vue de connexion pour l'authentification web (email/mot de passe)
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authService = WebAuthService.shared
    @EnvironmentObject private var toastManager: ToastNotificationManager
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingRegister = false
    @State private var showingForgotPassword = false
    @State private var showingVerifyCode = false
    @State private var showingSetPassword = false
    
    // Pour le flux d'inscription/réinitialisation
    @State private var pendingEmail: String = ""
    @State private var verificationCode: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fond avec gradient SNCF
                LinearGradient(
                    colors: [SNCFColors.ceruleen.opacity(0.1), SNCFColors.lavande.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Logo RailSkills
                        VStack(spacing: 16) {
                            Image("railskills-logo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .accessibilityLabel("Logo RailSkills")
                        }
                        .padding(.top, 40)
                        
                        // Formulaire de connexion dans une carte moderne
                        ModernCard(elevated: true) {
                            VStack(spacing: 24) {
                                ModernTextField(
                                    title: "Email",
                                    placeholder: "votre.email@sncf.fr",
                                    text: $email,
                                    icon: "envelope.fill",
                                    keyboardType: .emailAddress
                                )
                                
                                ModernTextField(
                                    title: "Mot de passe",
                                    placeholder: "Mot de passe",
                                    text: $password,
                                    icon: "lock.fill",
                                    isSecure: true
                                )
                                
                                // Bouton de connexion moderne
                                ModernButton(
                                    title: "Se connecter",
                                    icon: "arrow.right.circle.fill",
                                    style: .primary,
                                    isLoading: authService.isLoading
                                ) {
                                    Task {
                                        await handleLogin()
                                    }
                                }
                                .disabled(email.isEmpty || password.isEmpty)
                                
                                // Message d'erreur
                                if let error = authService.lastError {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.caption)
                                        Text(error)
                                            .font(.caption)
                                    }
                                    .foregroundColor(SNCFColors.corail)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                            
                        // Liens d'aide
                        HStack(spacing: 16) {
                            Button("Mot de passe oublié ?") {
                                HapticFeedbackManager.shared.buttonPress()
                                showingForgotPassword = true
                            }
                            .font(.avenirCaption)
                            .foregroundStyle(SNCFColors.ceruleen)
                            
                            Spacer()
                            
                            Button("Créer un compte") {
                                HapticFeedbackManager.shared.buttonPress()
                                showingRegister = true
                            }
                            .font(.avenirCaption)
                            .foregroundStyle(SNCFColors.ceruleen)
                        }
                        .padding(.horizontal, 24)
                        
                        // Bouton mode démonstration (pour les reviewers Apple)
                        Button {
                            HapticFeedbackManager.shared.buttonPress()
                            Task {
                                await handleDemoMode()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "play.circle.fill")
                                Text("Mode démonstration")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(SNCFColors.menthe)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 40)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingRegister) {
                // Nouvel assistant d'intégration simplifié
                OnboardingView {
                    // Callback de fin : retour à l'écran de connexion
                    showingRegister = false
                }
                .environmentObject(toastManager)
            }
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordSheet(
                    email: $pendingEmail,
                    onRequestCode: { email in
                        pendingEmail = email
                        showingForgotPassword = false
                        showingVerifyCode = true
                    }
                )
            }
            .sheet(isPresented: $showingVerifyCode) {
                VerifyCodeSheet(
                    email: pendingEmail,
                    code: $verificationCode,
                    onVerify: { code in
                        verificationCode = code
                        showingVerifyCode = false
                        showingSetPassword = true
                    }
                )
            }
            .sheet(isPresented: $showingSetPassword) {
                SetPasswordSheet(
                    email: pendingEmail,
                    code: verificationCode,
                    password: $newPassword,
                    confirmPassword: $confirmPassword,
                    onSetPassword: { password in
                        Task {
                            await handleSetPassword(password: password)
                        }
                    }
                )
            }
        }
    }
    
    private func handleLogin() async {
        HapticFeedbackManager.shared.buttonPress()
        
        do {
            let user = try await authService.login(email: email, password: password)
            HapticFeedbackManager.shared.actionSuccess()
            toastManager.show("Connexion réussie", type: .success)
            Logger.success("Utilisateur connecté: \(user.email)", category: "LoginView")
        } catch {
            HapticFeedbackManager.shared.actionError()
            toastManager.show(error.localizedDescription, type: .error)
            Logger.error("Erreur de connexion: \(error.localizedDescription)", category: "LoginView")
        }
    }
    
    private func handleSetPassword(password: String) async {
        do {
            let user = try await authService.setPassword(
                email: pendingEmail,
                code: verificationCode,
                password: password
            )
            toastManager.show("Mot de passe défini avec succès", type: .success)
            Logger.success("Mot de passe défini pour: \(user.email)", category: "LoginView")
            showingSetPassword = false
        } catch {
            toastManager.show(error.localizedDescription, type: .error)
            Logger.error("Erreur lors de la définition du mot de passe: \(error.localizedDescription)", category: "LoginView")
        }
    }
    
    /// Active le mode démonstration pour les reviewers Apple
    private func handleDemoMode() async {
        HapticFeedbackManager.shared.actionSuccess()
        
        // Activer le mode démo
        await authService.enableDemoMode()
        
        toastManager.show("Mode démonstration activé", type: .success)
        Logger.success("Mode démonstration activé pour les reviewers Apple", category: "LoginView")
        
        // Redémarrer l'app pour charger les données de démo
        // Note: En production, vous pourriez vouloir recharger le Store ici
        // Pour l'instant, le Store chargera automatiquement les données au prochain démarrage
    }
    
}

// MARK: - Register Sheet

struct RegisterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var email: String
    let onRegister: (String) -> Void
    
    @State private var inputEmail: String = ""
    @State private var cttId: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var emailError: String? = nil
    @StateObject private var authService = WebAuthService.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("votre.email@sncf.fr", text: $inputEmail)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .onChange(of: inputEmail) { _, newValue in
                                // Valider l'email en temps réel
                                if !newValue.isEmpty {
                                    let validation = newValue.isValidSNCFEmail()
                                    emailError = validation.errorMessage
                                } else {
                                    emailError = nil
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
                        }
                    }
                    
                    TextField("CTT ID (optionnel)", text: $cttId)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } header: {
                    Text("Informations")
                } footer: {
                    Text("Un code de vérification sera envoyé à votre email")
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(SNCFColors.corail)
                    }
                }
                
                Section {
                    Button(action: {
                        Task {
                            await handleRegister()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Créer le compte")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isLoading || inputEmail.isEmpty || emailError != nil)
                }
            }
            .navigationTitle("Créer un compte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func handleRegister() async {
        // Valider l'email avant d'envoyer
        let validation = inputEmail.isValidSNCFEmail()
        guard validation.isValid else {
            emailError = validation.errorMessage
            errorMessage = validation.errorMessage
            return
        }
        
        isLoading = true
        errorMessage = nil
        emailError = nil
        
        do {
            // Ignorer explicitement le résultat retourné
            _ = try await authService.register(
                email: inputEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                cttId: cttId.isEmpty ? nil : cttId.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            email = inputEmail
            dismiss()
            onRegister(inputEmail)
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
}

// MARK: - Forgot Password Sheet

struct ForgotPasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var email: String
    let onRequestCode: (String) -> Void
    
    @State private var inputEmail: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @StateObject private var authService = WebAuthService.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $inputEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } header: {
                    Text("Email")
                } footer: {
                    Text("Un code de vérification sera envoyé à votre email")
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(SNCFColors.corail)
                    }
                }
                
                if let success = successMessage {
                    Section {
                        Text(success)
                            .foregroundStyle(SNCFColors.menthe)
                    }
                }
                
                Section {
                    Button(action: {
                        Task {
                            await handleForgotPassword()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Envoyer le code")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isLoading || inputEmail.isEmpty)
                }
            }
            .navigationTitle("Mot de passe oublié")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func handleForgotPassword() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await authService.forgotPassword(email: inputEmail.trimmingCharacters(in: .whitespacesAndNewlines))
            successMessage = "Code envoyé avec succès"
            email = inputEmail
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                dismiss()
                onRequestCode(inputEmail)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Verify Code Sheet

struct VerifyCodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let email: String
    @Binding var code: String
    let onVerify: (String) -> Void
    
    @State private var inputCode: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @StateObject private var authService = WebAuthService.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Code à 6 chiffres", text: $inputCode)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .onChange(of: inputCode) { _, newValue in
                            // Limiter à 6 chiffres
                            if newValue.count > 6 {
                                inputCode = String(newValue.prefix(6))
                            }
                        }
                } header: {
                    Text("Code de vérification")
                } footer: {
                    Text("Entrez le code à 6 chiffres reçu par email à \(email)")
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(SNCFColors.corail)
                    }
                }
                
                Section {
                    Button(action: {
                        Task {
                            await handleVerify()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Vérifier")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isLoading || inputCode.count != 6)
                }
            }
            .navigationTitle("Vérification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func handleVerify() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.verifyCode(email: email, code: inputCode)
            code = inputCode
            dismiss()
            onVerify(inputCode)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Set Password Sheet

struct SetPasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    let email: String
    let code: String
    @Binding var password: String
    @Binding var confirmPassword: String
    let onSetPassword: (String) -> Void
    
    @State private var inputPassword: String = ""
    @State private var inputConfirmPassword: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var isPasswordValid: Bool {
        inputPassword.count >= 8 && inputPassword == inputConfirmPassword
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Nouveau mot de passe", text: $inputPassword)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirmer le mot de passe", text: $inputConfirmPassword)
                        .textContentType(.newPassword)
                } header: {
                    Text("Nouveau mot de passe")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Le mot de passe doit contenir au moins 8 caractères")
                        if !inputPassword.isEmpty && inputPassword != inputConfirmPassword {
                            Text("Les mots de passe ne correspondent pas")
                                .foregroundStyle(SNCFColors.corail)
                        }
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(SNCFColors.corail)
                    }
                }
                
                Section {
                    Button(action: {
                        password = inputPassword
                        confirmPassword = inputConfirmPassword
                        onSetPassword(inputPassword)
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Définir le mot de passe")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isLoading || !isPasswordValid)
                }
            }
            .navigationTitle("Définir le mot de passe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(ToastNotificationManager())
}

