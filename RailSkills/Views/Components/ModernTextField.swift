//
//  ModernTextField.swift
//  RailSkills
//
//  Champ de texte moderne avec label flottant, validation et feedback visuel
//

import SwiftUI

/// Champ de texte moderne avec design iOS natif
struct ModernTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var errorMessage: String? = nil
    var onCommit: (() -> Void)? = nil
    
    @FocusState private var isFocused: Bool
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label avec animation
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundColor(isFocused ? SNCFColors.ceruleen : .secondary)
                }
                
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(isFocused ? SNCFColors.ceruleen : .secondary)
                
                if errorMessage != nil {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(SNCFColors.corail)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
            
            // Champ de texte
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.body)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($isFocused)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        borderColor,
                        lineWidth: borderWidth
                    )
            )
            .onChange(of: isFocused) { _, newValue in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isEditing = newValue
                }
                
                // Haptic feedback subtil
                if newValue {
                    let selectionFeedback = UISelectionFeedbackGenerator()
                    selectionFeedback.selectionChanged()
                }
            }
            .onSubmit {
                onCommit?()
            }
            
            // Message d'erreur
            if let error = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                }
                .foregroundColor(SNCFColors.corail)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var borderColor: Color {
        if errorMessage != nil {
            return SNCFColors.corail
        } else if isFocused {
            return SNCFColors.ceruleen
        } else {
            return Color.primary.opacity(0.1)
        }
    }
    
    private var borderWidth: CGFloat {
        if isFocused || errorMessage != nil {
            return 2
        } else {
            return 1
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        ModernTextField(
            title: "Nom du conducteur",
            placeholder: "Entrez le nom",
            text: .constant(""),
            icon: "person.fill"
        )
        
        ModernTextField(
            title: "Email",
            placeholder: "email@example.com",
            text: .constant(""),
            icon: "envelope.fill",
            keyboardType: .emailAddress
        )
        
        ModernTextField(
            title: "Mot de passe",
            placeholder: "••••••••",
            text: .constant(""),
            icon: "lock.fill",
            isSecure: true,
            errorMessage: "Le mot de passe doit contenir au moins 8 caractères"
        )
    }
    .padding()
}








