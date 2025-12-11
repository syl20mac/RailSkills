//
//  ChecklistImportWelcomeView.swift
//  RailSkills
//
//  Vue d'accueil affichée quand aucune checklist n'est présente
//

import SwiftUI
import UniformTypeIdentifiers

/// Vue d'accueil affichée quand aucune checklist n'est présente
/// Guide l'utilisateur pour importer une checklist via fichier
struct ChecklistImportWelcomeView: View {
    @ObservedObject var vm: ViewModel
    var checklistType: ChecklistType = .triennale
    @State private var showingFileImporter = false
    @State private var importSuccessMessage: String?
    @State private var importErrorMessage: String?
    @State private var showingCreateConfirmation = false
    @State private var showingResetConfirmation = false
    
    var body: some View {
        mainContent
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [UTType.json, UTType.plainText, UTType.text],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    guard url.startAccessingSecurityScopedResource() else {
                        importErrorMessage = "Impossible d'accéder au fichier. Assurez-vous que le fichier est dans l'application Fichiers (iCloud Drive ou sur l'appareil) et réessayez."
                        Logger.error("Impossible d'accéder au fichier: \(url.path)", category: "ChecklistImport")
                        return
                    }
                    
                    defer {
                        url.stopAccessingSecurityScopedResource()
                    }
                    
                    do {
                        try vm.importTextFile(url: url, type: checklistType)
                        importSuccessMessage = "Checklist \(checklistType.displayTitle) importée avec succès !"
                        Logger.success("Checklist \(checklistType.displayTitle) importée: \(url.lastPathComponent)", category: "ChecklistImport")
                    } catch {
                        importErrorMessage = "Erreur lors de l'import : \(error.localizedDescription)"
                        Logger.error("Erreur d'import: \(error.localizedDescription)", category: "ChecklistImport")
                    }
                }
            case .failure(let error):
                importErrorMessage = "Erreur lors de la sélection du fichier : \(error.localizedDescription)"
                Logger.error("Erreur de sélection de fichier: \(error.localizedDescription)", category: "ChecklistImport")
            }
        }
        .alert("Import réussi", isPresented: Binding(get: { importSuccessMessage != nil }, set: { if !$0 { importSuccessMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importSuccessMessage ?? "")
        }
        .alert("Erreur d'import", isPresented: Binding(get: { importErrorMessage != nil }, set: { if !$0 { importErrorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage ?? "")
        }
        .alert("Créer une nouvelle checklist", isPresented: $showingCreateConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Créer") {
                vm.createEmptyChecklist(type: checklistType)
                importSuccessMessage = "Checklist \(checklistType.displayTitle) vide créée ! Vous pouvez maintenant ajouter des catégories et des questions dans l'onglet Éditeur."
                Logger.info("Checklist \(checklistType.displayTitle) vide créée", category: "ChecklistImport")
            }
        } message: {
            Text("Une nouvelle checklist \(checklistType.displayTitle) vide sera créée. Vous pourrez ensuite ajouter des catégories et des questions manuellement dans l'éditeur.")
        }
        .alert("Réinitialiser l'application", isPresented: $showingResetConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Réinitialiser", role: .destructive) {
                vm.store.resetAllData()
                importSuccessMessage = "Application réinitialisée. Toutes les données ont été supprimées."
                Logger.warning("Application réinitialisée par l'utilisateur", category: "ChecklistImport")
            }
        } message: {
            Text("Cette action supprimera toutes les données : checklist, conducteurs, et tous les suivis. Cette action est irréversible.")
        }
    }
    
    // MARK: - Subviews
    
    private var mainContent: some View {
        VStack(spacing: 24) {
            welcomeIcon
            welcomeText
            importOptions
            supportedFormats
            #if DEBUG
            resetButton
            #endif
        }
    }
    
    private var welcomeIcon: some View {
        Image(systemName: "tray.and.arrow.down.fill")
            .font(.system(size: 64))
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue, .green],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .padding(.top, 40)
    }
    
    private var welcomeText: some View {
        VStack(spacing: 12) {
            Text("Checklist \(checklistType.displayTitle)")
                .font(.title)
                .fontWeight(.bold)
            
            if checklistType == .triennale {
                Text("Pour commencer, importez une checklist depuis un fichier JSON ou texte, ou créez-en une manuellement.")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            } else {
                Text("Aucune checklist \(checklistType.displayTitle) chargée. Téléchargez-la depuis SharePoint ou importez un fichier.")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Text("1. Télécharger depuis SharePoint\n2. Importer un fichier JSON ou texte\n3. Créer manuellement les questions et catégories")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    @State private var isDownloading = false
    @State private var downloadErrorMessage: String?
    
    private var importOptions: some View {
        VStack(spacing: 16) {
            // Bouton pour télécharger depuis SharePoint
            sharePointDownloadButton
            
            Divider()
                .padding(.vertical, 8)
            
            fileImportButton
            createEmptyButton
        }
        .padding(.horizontal, 24)
        .alert("Erreur de téléchargement", isPresented: Binding(get: { downloadErrorMessage != nil }, set: { if !$0 { downloadErrorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(downloadErrorMessage ?? "")
        }
    }
    
    private var sharePointDownloadButton: some View {
        Button {
            downloadFromSharePoint()
        } label: {
            HStack {
                if isDownloading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "cloud.fill")
                }
                Text(isDownloading ? "Téléchargement..." : "Télécharger depuis SharePoint")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(SNCFColors.menthe)
        .controlSize(.large)
        .disabled(isDownloading)
    }
    
    private func downloadFromSharePoint() {
        isDownloading = true
        Task {
            let success: Bool
            switch checklistType {
            case .triennale:
                success = await vm.store.forceDownloadChecklist()
            case .vp:
                success = await vm.store.forceDownloadChecklistVP()
            case .te:
                success = await vm.store.forceDownloadChecklistTE()
            }
            
            await MainActor.run {
                isDownloading = false
                if success {
                    importSuccessMessage = "Checklist \(checklistType.displayTitle) téléchargée depuis SharePoint avec succès !"
                } else {
                    downloadErrorMessage = "Impossible de télécharger la checklist \(checklistType.displayTitle). Vérifiez votre connexion et que le fichier existe sur SharePoint."
                }
            }
        }
    }
    
    private var fileImportButton: some View {
        Button {
            showingFileImporter = true
        } label: {
            Label("Importer un fichier", systemImage: "doc.badge.plus")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
    
    private var createEmptyButton: some View {
        Button {
            showingCreateConfirmation = true
        } label: {
            Label("Créer une checklist vide", systemImage: "plus.circle")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
    
    private var supportedFormats: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Formats supportés:")
                .font(.headline)
            Text("• JSON (fichier .json)\n• Texte brut (.txt)")
                .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    #if DEBUG
    private var resetButton: some View {
        Button(role: .destructive) {
            showingResetConfirmation = true
        } label: {
            Label("Réinitialiser l'application", systemImage: "trash")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
    }
    #endif
}


