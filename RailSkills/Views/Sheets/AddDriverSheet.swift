//
//  AddDriverSheet.swift
//  RailSkills
//
//  Vue pour ajouter un nouveau conducteur
//

import SwiftUI

/// Vue pour ajouter un nouveau conducteur
struct AddDriverSheet: View {
    @ObservedObject var vm: ViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var driverName: String = ""
    @State private var driverFirstName: String = ""
    @State private var driverCpNumber: String = ""
    @State private var triennialStartDate: Date = Date()
    @State private var showingValidationError: Bool = false
    @State private var validationErrorMessage: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Carte avec informations du conducteur
                    ModernCard(elevated: true) {
                        VStack(spacing: 20) {
                            ModernTextField(
                                title: "Nom",
                                placeholder: "Nom de famille",
                                text: $driverName,
                                icon: "person.fill",
                                errorMessage: getFieldError(for: .name)
                            )
                            
                            ModernTextField(
                                title: "Prénom",
                                placeholder: "Prénom",
                                text: $driverFirstName,
                                icon: "person.fill",
                                errorMessage: getFieldError(for: .firstName)
                            )
                            
                            ModernTextField(
                                title: "Numéro de CP",
                                placeholder: "Numéro de CP",
                                text: $driverCpNumber,
                                icon: "number",
                                errorMessage: getFieldError(for: .cpNumber)
                            )
                        }
                    }
                    
                    // Carte avec période triennale
                    ModernCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Période triennale")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            DatePicker(
                                "Date de début",
                                selection: $triennialStartDate,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            
                            Text("Cette date est requise pour calculer l'échéance triennale.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    ModernButton(
                        title: "Ajouter le conducteur",
                        icon: "person.badge.plus",
                        style: .primary
                    ) {
                        addDriver()
                    }
                    .disabled(!isFormValid)
                    .padding(.horizontal)
                    
                    // Message d'erreur général
                    if showingValidationError && !validationErrorMessage.isEmpty {
                        Text("⚠️ \(validationErrorMessage)")
                            .font(.caption)
                            .foregroundColor(SNCFColors.corail)
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
            .background(Color(uiColor: UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Nouveau conducteur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        HapticFeedbackManager.shared.buttonPress()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Pré-remplir avec la date actuelle pour faciliter la saisie
            triennialStartDate = Date()
        }
    }
    
    // MARK: - Validation
    
    /// Type de champ pour les erreurs
    private enum FieldType {
        case name, firstName, cpNumber
    }
    
    /// Récupère le message d'erreur pour un champ spécifique
    private func getFieldError(for field: FieldType) -> String? {
        guard showingValidationError else { return nil }
        
        let trimmedName = driverName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFirstName = driverFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCpNumber = driverCpNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch field {
        case .name:
            if trimmedName.isEmpty {
                return "Le nom est obligatoire"
            } else if !ValidationService.validateDriverName(trimmedName) {
                return "Le nom contient des caractères invalides"
            }
        case .firstName:
            if trimmedFirstName.isEmpty {
                return "Le prénom est obligatoire"
            }
        case .cpNumber:
            if trimmedCpNumber.isEmpty {
                return "Le numéro de CP est obligatoire"
            }
        }
        
        return nil
    }
    
    /// Vérifie si le formulaire est valide
    private var isFormValid: Bool {
        let trimmedName = driverName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFirstName = driverFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCpNumber = driverCpNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !trimmedName.isEmpty 
            && !trimmedFirstName.isEmpty 
            && !trimmedCpNumber.isEmpty
            && ValidationService.validateDriverName(trimmedName)
    }
    
    private func addDriver() {
        // Haptic feedback pour l'action
        HapticFeedbackManager.shared.buttonPress()
        let trimmedName = driverName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFirstName = driverFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCpNumber = driverCpNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validation du nom
        guard !trimmedName.isEmpty else {
            validationErrorMessage = "Le nom est obligatoire"
            showingValidationError = true
            return
        }
        
        guard ValidationService.validateDriverName(trimmedName) else {
            validationErrorMessage = "Le nom contient des caractères invalides"
            showingValidationError = true
            Logger.warning("Nom de conducteur invalide: \(trimmedName)", category: "AddDriverSheet")
            return
        }
        
        // Validation du prénom
        guard !trimmedFirstName.isEmpty else {
            validationErrorMessage = "Le prénom est obligatoire"
            showingValidationError = true
            return
        }
        
        // Validation du numéro de CP
        guard !trimmedCpNumber.isEmpty else {
            validationErrorMessage = "Le numéro de CP est obligatoire"
            showingValidationError = true
            return
        }
        
        showingValidationError = false
        
        // SNCF_ID supprimé : on ne rattache plus le conducteur à un propriétaire CTT.
        // ownerSNCFId est conservé dans le modèle pour la rétrocompatibilité de décodage,
        // mais n'est plus renseigné pour les nouveaux enregistrements.
        let newDriver = DriverRecord(
            name: trimmedName,
            firstName: trimmedFirstName,
            cpNumber: trimmedCpNumber,
            triennialStart: triennialStartDate,
            ownerSNCFId: nil
        )
        
        vm.store.drivers.append(newDriver)
        Logger.success("Conducteur ajouté: \(trimmedFirstName) \(trimmedName) (CP: \(trimmedCpNumber))", category: "AddDriverSheet")
        
        // Feedback de succès
        HapticFeedbackManager.shared.actionSuccess()
        dismiss()
    }
}





