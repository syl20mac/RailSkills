//
//  ModeSelectionView.swift
//  RailSkills
//
//  Écran de sélection du mode de fonctionnement au premier lancement
//

import SwiftUI

struct ModeSelectionView: View {
    @StateObject private var appConfig = AppConfigurationService.shared
    @State private var showingEnterpriseConfig = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fond neutre
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Logo et Titre
                    VStack(spacing: 16) {
                        Image("railskills-logo") // Assurez-vous que l'actif existe, sinon texte
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .accessibilityLabel("Logo RailSkills")
                        
                        Text("Bienvenue sur RailSkills")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                    
                    Text("Choisissez votre mode de fonctionnement")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 24) {
                        // Option Mode Entreprise
                        ModeOptionButton(
                            title: "Mode Entreprise",
                            description: "Pour les utilisateurs d'une organisation (SNCF, etc.). Nécessite une configuration.",
                            icon: "building.2.fill",
                            color: .blue
                        ) {
                            showingEnterpriseConfig = true
                        }
                        
                        // Option Mode Local
                        ModeOptionButton(
                            title: "Mode Local",
                            description: "Pour une utilisation personnelle. Vos données restent sur cet appareil.",
                            icon: "ipad.and.iphone",
                            color: .green
                        ) {
                            appConfig.enableLocalMode()
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationDestination(isPresented: $showingEnterpriseConfig) {
                // Vers la configuration entreprise (QR Code ou manuel)
                EnterpriseConfigView()
            }
        }
    }
}

struct ModeOptionButton: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(color)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}



#Preview {
    ModeSelectionView()
}
