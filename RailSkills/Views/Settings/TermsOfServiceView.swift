//
//  TermsOfServiceView.swift
//  RailSkills
//
//  Vue d'affichage des Conditions Générales d'Utilisation (CGU)
//

import SwiftUI

/// Vue pour afficher les Conditions Générales d'Utilisation
struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // En-tête
                VStack(alignment: .leading, spacing: 8) {
                    Text("Conditions Générales d'Utilisation")
                        .font(.title.bold())
                        .foregroundStyle(.primary)
                    
                    Text("Dernière mise à jour : 3 décembre 2025")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)
                
                Divider()
                
                // Section 1 : Objet
                sectionView(
                    title: "1. Objet",
                    content: """
                    Les présentes Conditions Générales d'Utilisation (CGU) régissent l'utilisation de l'application RailSkills, développée pour la SNCF et destinée aux dpx Traction (CTT) pour le suivi triennal réglementaire des conducteurs.
                    
                    L'utilisation de l'application implique l'acceptation pleine et entière des présentes CGU.
                    """
                )
                
                // Section 2 : Description du Service
                sectionView(
                    title: "2. Description du Service",
                    content: """
                    RailSkills est une application mobile iOS/iPadOS permettant de :
                    • Gérer le suivi triennal réglementaire des conducteurs
                    • Enregistrer et suivre les évaluations de compétences
                    • Synchroniser les données avec SharePoint
                    • Générer des rapports et exports
                    
                    L'application nécessite une connexion internet pour la synchronisation des données.
                    """
                )
                
                // Section 3 : Utilisation et Responsabilités
                sectionView(
                    title: "3. Utilisation et Responsabilités",
                    content: """
                    3.1. L'utilisateur s'engage à utiliser l'application conformément à sa destination et dans le respect de la réglementation en vigueur.
                    
                    3.2. L'utilisateur est seul responsable de l'utilisation de son compte et des actions effectuées depuis celui-ci.
                    
                    3.3. L'utilisateur s'engage à maintenir la confidentialité de ses identifiants de connexion.
                    """
                )
                
                // Section 4 : Données Personnelles
                sectionView(
                    title: "4. Protection des Données Personnelles",
                    content: """
                    4.1. Les données saisies dans RailSkills peuvent être consultées par votre encadrement pour le suivi triennal réglementaire.
                    
                    4.2. Les données sont stockées localement sur l'appareil et synchronisées avec SharePoint selon les règles de sécurité de la SNCF.
                    
                    4.3. Conformément au RGPD, vous disposez d'un droit d'accès, de rectification, de suppression et d'opposition sur vos données personnelles.
                    
                    4.4. Pour exercer vos droits, contactez votre encadrement.
                    """
                )
                
                // Section 5 : Confidentialité
                sectionView(
                    title: "5. Confidentialité",
                    content: """
                    5.1. Les données traitées dans l'application sont confidentielles et destinées uniquement aux personnes habilitées.
                    
                    5.2. L'utilisateur s'engage à ne pas partager, diffuser ou utiliser les données à des fins autres que celles prévues par l'application.
                    
                    """
                )
                
                // Section 6 : Disponibilité du Service
                sectionView(
                    title: "6. Disponibilité du Service",
                    content: """
                    6.1. La SNCF s'efforce d'assurer une disponibilité maximale de l'application, mais ne peut garantir un fonctionnement ininterrompu.
                    
                    6.2. L'application peut être momentanément indisponible pour des raisons de maintenance, de mise à jour ou de cas de force majeure.
                    
                    6.3. La SNCF se réserve le droit de modifier, suspendre ou interrompre l'application à tout moment.
                    """
                )
                
                // Section 7 : Propriété Intellectuelle
                sectionView(
                    title: "7. Propriété Intellectuelle",
                    content: """
                    7.1. L'application RailSkills et tous ses éléments (code, design, contenus) sont la propriété exclusive de l'editeur.
                    
                    7.2. Toute reproduction, représentation, modification ou adaptation sans autorisation est interdite.
                    
                    7.3. Les données saisies par l'utilisateur restent la propriété de la SNCF dans le cadre de son activité professionnelle.
                    """
                )
                
                // Section 8 : Limitation de Responsabilité
                sectionView(
                    title: "8. Limitation de Responsabilité",
                    content: """
                    8.1. L'editeur et la SNCF ne pourront être tenues responsables des dommages directs ou indirects résultant de l'utilisation ou de l'impossibilité d'utiliser l'application.
                    
                    8.2. L'utilisateur est seul responsable des données qu'il saisit dans l'application.
                    
                    8.3. La SNCF ne garantit pas l'exactitude, l'exhaustivité ou l'actualité des informations fournies par l'application.
                    """
                )
                
                // Section 9 : Modification des CGU
                sectionView(
                    title: "9. Modification des CGU",
                    content: """
                    9.1. La SNCF se réserve le droit de modifier les présentes CGU à tout moment.
                    
                    9.2. Les modifications sont effectives dès leur publication dans l'application.
                    
                    9.3. L'utilisateur est invité à consulter régulièrement les CGU pour prendre connaissance des éventuelles modifications.
                    """
                )
                
                // Section 10 : Contact
                sectionView(
                    title: "10. Contact",
                    content: """
                    Pour toute question relative aux présentes CGU ou à l'utilisation de l'application, vous pouvez contacter :
                    
                    • Votre référent ou votre encadrement
                    • Le support technique RailSkills
                    """
                )
                
                // Section 11 : Droit Applicable
                sectionView(
                    title: "11. Droit Applicable",
                    content: """
                    Les présentes CGU sont régies par le droit français. Tout litige relatif à leur interprétation ou à leur exécution relève de la compétence exclusive des tribunaux français.
                    """
                )
            }
            .padding()
        }
        .navigationTitle("CGU")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Fermer") {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Composants
    
    private func sectionView(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(SNCFColors.ceruleen)
            
            Text(content)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TermsOfServiceView()
    }
}





























