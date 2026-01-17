//
//  CTTProfileView.swift
//  RailSkills
//
//  Vue pour configurer l'identité du CTT (Cadre Transport Traction)
//  Permet de saisir ou modifier l'identifiant SNCF et le nom du CTT
//

import SwiftUI

struct CTTProfileView: View {
    @StateObject private var identityService = OrganizationIdentityService.shared
    @EnvironmentObject private var toastManager: ToastNotificationManager
    
    @State private var sncfIdentity: String = ""
    @State private var sncfName: String = ""
    @State private var isEditing: Bool = false
    
    var body: some View {
        Form {
            Section {
                if identityService.isAuthenticated && !isEditing {
                    // Affichage du profil actuel
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(identityService.sncfName)
                                .font(.avenirHeadline)
                                .foregroundStyle(.primary)
                            
                            Text(identityService.sncfIdentity)
                                .font(.avenirCaption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            isEditing = true
                            sncfIdentity = identityService.sncfIdentity
                            sncfName = identityService.sncfName
                        }) {
                            Image(systemName: "pencil")
                                .foregroundStyle(Color.blue)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    if let createdAt = identityService.profileCreatedAt {
                        HStack {
                            Text("Profil créé le")
                                .font(.avenirCaption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(DateFormatHelper.formatDate(createdAt, style: .medium))
                                .font(.avenirCaption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    // Formulaire de saisie/modification
                    TextField("Identifiant (email ou ID)", text: $sncfIdentity)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .font(.avenirBody)
                    
                    TextField("Nom complet", text: $sncfName)
                        .textContentType(.name)
                        .font(.avenirBody)
                    
                    if isEditing {
                        Button(action: {
                            cancelEditing()
                        }) {
                            Text("Annuler")
                                .font(.avenirBody)
                                .foregroundStyle(Color.red)
                        }
                    }
                }
            } header: {
                Text("Profil")
            } footer: {
                if identityService.isAuthenticated && !isEditing {
                    Text("Votre identité est configurée. Vous ne verrez que les conducteurs et checklists qui vous sont attribués.")
                        .font(.avenirCaption)
                } else {
                    Text("Saisissez votre identifiant organisation (email professionnel ou ID interne) et votre nom complet. Cette information permet d'isoler vos données.")
                        .font(.avenirCaption)
                }
            }
            
            // Section d'authentification SDK SNCF_ID (si disponible)
            if identityService.isSDKAvailable && !identityService.isAuthenticated {
                Section {
                    Button(action: {
                        authenticateWithSDK()
                    }) {
                        HStack {
                            Image(systemName: "person.badge.key.fill")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("S'authentifier avec l'Organisation")
                                    .font(.avenirHeadline)
                                    .foregroundStyle(.primary)
                                Text("Authentification automatique")
                                    .font(.avenirCaption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if identityService.isAuthenticating {
                                ProgressView()
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(identityService.isAuthenticating)
                } header: {
                    Text("Authentification Organisation")
                } footer: {
                    Text("Utilisez votre compte professionnel pour vous authentifier automatiquement.")
                        .font(.avenirCaption)
                }
            }
            
            if identityService.isAuthenticated && !isEditing {
                Section {
                    // Afficher si l'identité provient du SDK
                    if identityService.isUsingSDK {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(Color.green)
                            Text("Authentifié via Organisation")
                                .font(.avenirCaption)
                                .foregroundStyle(Color.green)
                        }
                    }
                    
                    Button(role: .destructive, action: {
                        clearIdentity()
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.minus")
                            Text("Déconnecter le profil")
                                .font(.avenirBody)
                        }
                    }
                } footer: {
                    Text(identityService.isUsingSDK ? 
                         "Votre identité provient du système d'organisation. La déconnexion vous déconnectera et n'effacera pas vos données locales." :
                         "La déconnexion n'efface pas vos données locales, mais vous ne pourrez plus accéder aux données filtrées par votre identité.")
                        .font(.avenirCaption)
                }
            } else if !identityService.isSDKAvailable || (!identityService.isAuthenticated && !identityService.isAuthenticating) {
                // Afficher le formulaire de saisie manuelle uniquement si le SDK n'est pas disponible ou si l'utilisateur veut saisir manuellement
                Section {
                    Button(action: {
                        saveIdentity()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(identityService.isAuthenticated ? "Enregistrer les modifications" : "Enregistrer le profil")
                                .font(.avenirHeadline)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(sncfIdentity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                             sncfName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } header: {
                    Text(identityService.isSDKAvailable ? "Saisie manuelle" : "Configuration manuelle")
                } footer: {
                    Text(identityService.isSDKAvailable ? 
                         "Vous pouvez saisir manuellement votre identifiant si vous préférez ne pas utiliser l'authentification automatique." :
                         "Saisissez votre identifiant organisation (email professionnel ou ID interne) et votre nom complet.")
                        .font(.avenirCaption)
                }
            }
            
            // Afficher les erreurs d'authentification
            if let error = identityService.lastAuthenticationError {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.red)
                        Text(error)
                            .font(.avenirCaption)
                            .foregroundStyle(Color.red)
                    }
                }
            }
        }
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if identityService.isAuthenticated {
                sncfIdentity = identityService.sncfIdentity
                sncfName = identityService.sncfName
            }
        }
    }
    
    private func authenticateWithSDK() {
        identityService.authenticateWithSDK { result in
            switch result {
            case .success:
                isEditing = false
                toastManager.show("Authentification réussie", type: .success)
                
            case .failure(let error):
                if let sncfError = error as? SNCFIDError {
                    switch sncfError {
                    case .sdkNotAvailable:
                        toastManager.show("L'authentification automatique n'est pas disponible. Utilisez la saisie manuelle.", type: .warning)
                    case .authenticationCancelled:
                        // Ne pas afficher d'erreur si l'utilisateur a annulé
                        break
                    default:
                        toastManager.show("Erreur d'authentification: \(error.localizedDescription)", type: .error)
                    }
                } else {
                    toastManager.show("Erreur d'authentification: \(error.localizedDescription)", type: .error)
                }
            }
        }
    }
    
    private func saveIdentity() {
        let trimmedIdentity = sncfIdentity.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = sncfName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedIdentity.isEmpty && !trimmedName.isEmpty else {
            toastManager.show("Veuillez remplir tous les champs", type: .warning)
            return
        }
        
        identityService.setIdentity(userId: trimmedIdentity, name: trimmedName)
        isEditing = false
        
        let message = identityService.isAuthenticated ? "Profil mis à jour avec succès" : "Profil enregistré avec succès"
        toastManager.show(message, type: .success)
        
        Logger.info("Profil sauvegardé: \(trimmedName) (\(trimmedIdentity))", category: "Profile")
    }
    
    private func cancelEditing() {
        sncfIdentity = identityService.sncfIdentity
        sncfName = identityService.sncfName
        isEditing = false
    }
    
    private func clearIdentity() {
        identityService.clearIdentity()
        sncfIdentity = ""
        sncfName = ""
        isEditing = false
        
        toastManager.show("Profil déconnecté", type: .info)
        Logger.info("Profil déconnecté", category: "Profile")
    }
}

#Preview {
    NavigationStack {
        CTTProfileView()
            .environmentObject(ToastNotificationManager())
    }
}

