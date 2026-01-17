//
//  SharingView.swift
//  RailSkills
//
//  Vue de partage et import/export des conducteurs
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

/// Vue de partage et import/export des conducteurs
struct SharingView: View {
    @ObservedObject var vm: ViewModel
    @State private var selectedDriverIndex: Int = 0
    @State private var importErrorMessage: String?
    @State private var showingMultiDriverSelection: Bool = false
    @State private var selectedDriverIndices: Set<Int> = []
    @State private var showingDriverFileImporter: Bool = false
    @State private var importResults: [ImportResult] = []
    @State private var showingMergeDialog: Bool = false
    @State private var pendingMergeDriver: DriverRecord?
    @State private var pendingMergeIndex: Int = 0
    @State private var importSuccessMessage: String?
    @State private var showingShareSheet: Bool = false
    @State private var shareItems: [Any] = []
    
    // Export loading states
    @State private var isExportingJSON = false
    @State private var isExportingCSV = false
    @State private var isExportingChecklist = false
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                // Afficher la vue d'import si la checklist est nil ou vide
                if vm.store.checklist == nil || vm.store.checklist?.items.isEmpty == true {
                    ChecklistImportWelcomeView(vm: vm)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header avec description
                            headerSection
                            
                            // Section Export
                            exportSection
                            
                            // Section Import
                            importSection
                            
                            // Section Checklist
                            checklistSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Partage")
            .navigationBarTitleDisplayMode(.large)
            .fileImporter(
                isPresented: $showingDriverFileImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleDriverImport(result: result)
            }
            .navigationBarTitleDisplayMode(.inline)
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
            .alert("Conducteur existant", isPresented: $showingMergeDialog) {
                ForEach(MergeStrategy.allCases, id: \.self) { strategy in
                    Button(strategy.title) {
                        handleMerge(strategy: strategy)
                    }
                }
                Button("Annuler", role: .cancel) {
                    pendingMergeDriver = nil
                    showingMergeDialog = false
                }
            } message: {
                if let driver = pendingMergeDriver {
                    Text("Le conducteur '\(driver.name)' existe déjà. Choisissez une stratégie de fusion :")
                } else {
                    Text("Le conducteur existe déjà. Choisissez une stratégie de fusion :")
                }
            }
            .sheet(isPresented: $showingMultiDriverSelection) {
                multiDriverSelectionSheet
            }
            .shareSheet(isPresented: $showingShareSheet, activityItems: shareItems)
        }
        .onAppear {
            // Valider que l'index sélectionné est valide
            validateAndUpdateSelectedIndex()
        }
        .onChange(of: vm.store.drivers.count) { _, _ in
            // Valider l'index si la liste change (conducteur supprimé)
            validateAndUpdateSelectedIndex()
        }
    }
    
    // MARK: - Header Section
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [SNCFColors.ceruleen.opacity(0.15), SNCFColors.lavande.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "square.and.arrow.up.on.square.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [SNCFColors.ceruleen, SNCFColors.lavande],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Partage & Export")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Exportez vos données ou importez depuis un fichier")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }
    
    // MARK: - Export Section
    
    @ViewBuilder
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // En-tête de section avec icône
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [SNCFColors.ceruleen, SNCFColors.bleuHorizon],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("Exporter")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.bottom, 4)
            
            VStack(spacing: 16) {
                // Export un conducteur
                exportSingleDriverCard
                
                // Export plusieurs conducteurs
                exportMultipleDriversCard
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
    
    @ViewBuilder
    private var exportSingleDriverCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // En-tête avec icône et badge
            HStack {
                ZStack {
                    Circle()
                        .fill(SNCFColors.ceruleen.opacity(0.15))
                        .frame(width: 44, height: 44)
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                        .foregroundStyle(SNCFColors.ceruleen)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                Text("Un conducteur")
                    .font(.headline)
                    if !vm.store.drivers.isEmpty {
                        Text("Sélectionnez un conducteur à exporter")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
                            
            if vm.store.drivers.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "tray.fill")
                        .font(.title3)
                        .foregroundStyle(SNCFColors.safran.opacity(0.7))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Aucun conducteur disponible")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Ajoutez des conducteurs depuis l'onglet Conducteurs")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(SNCFColors.safran.opacity(0.08))
                )
            } else {
                // Sélecteur de conducteur amélioré
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(SNCFColors.ceruleen)
                Picker("Conducteur", selection: $selectedDriverIndex) {
                    ForEach(vm.store.drivers.indices, id: \.self) { i in
                        // Affiche le prénom et le nom du conducteur
                        Text(vm.store.drivers[i].fullName).tag(i)
                    }
                }
                .pickerStyle(.menu)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.tertiarySystemBackground))
                )
                
                if vm.store.drivers.indices.contains(selectedDriverIndex) {
                    let selectedDriver = vm.store.drivers[selectedDriverIndex]
                    
                    // Informations du conducteur avec badges
                    HStack(spacing: 12) {
                            if let start = selectedDriver.triennialStart {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                Text(DateFormatHelper.formatDate(start))
                                    .font(.caption)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(SNCFColors.ceruleen.opacity(0.1))
                            )
                            .foregroundStyle(SNCFColors.ceruleen)
                        }
                        
                            if let checklist = vm.store.checklist {
                                let progress = calculateProgress(for: selectedDriverIndex, checklist: checklist)
                            HStack(spacing: 6) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.caption2)
                                Text("\(Int(progress * 100))%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(progress >= 1.0 ? SNCFColors.menthe.opacity(0.1) : SNCFColors.safran.opacity(0.1))
                            )
                            .foregroundStyle(progress >= 1.0 ? SNCFColors.menthe : SNCFColors.safran)
                        }
                        Spacer()
                    }
                }
                
                // Boutons d'export avec style amélioré
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button {
                            exportSingleDriver()
                        } label: {
                            HStack(spacing: 10) {
                                if isExportingJSON {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                Text("JSON")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SNCFColors.ceruleen)
                        .disabled(vm.store.drivers.isEmpty || !vm.store.drivers.indices.contains(selectedDriverIndex) || isExportingJSON)
                        .accessibilityLabel(isExportingJSON ? "Export en cours" : "Exporter le conducteur sélectionné en JSON")
                        .accessibilityHint("Exporte les données du conducteur dans un fichier JSON")
                        
                        Button {
                            exportSingleDriverAsCSV()
                        } label: {
                            HStack(spacing: 10) {
                                if isExportingCSV {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "tablecells.fill")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                Text("CSV")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SNCFColors.menthe)
                        .disabled(vm.store.drivers.isEmpty || !vm.store.drivers.indices.contains(selectedDriverIndex) || isExportingCSV)
                        .accessibilityLabel(isExportingCSV ? "Export en cours" : "Exporter le conducteur sélectionné en CSV")
                        .accessibilityHint("Exporte les données du conducteur dans un fichier CSV compatible Excel")
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.tertiarySystemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }
    
    @ViewBuilder
    private var exportMultipleDriversCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // En-tête avec icône
            HStack {
                ZStack {
                    Circle()
                        .fill(SNCFColors.ocre.opacity(0.15))
                        .frame(width: 44, height: 44)
                Image(systemName: "person.3.fill")
                    .font(.title3)
                        .foregroundStyle(SNCFColors.ocre)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                Text("Plusieurs conducteurs")
                    .font(.headline)
                if !vm.store.drivers.isEmpty {
                    Text("\(vm.store.drivers.count) disponible\(vm.store.drivers.count > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                }
                Spacer()
            }
            
            if vm.store.drivers.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "tray.fill")
                        .font(.title3)
                        .foregroundStyle(SNCFColors.ocre.opacity(0.7))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Aucun conducteur disponible")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Ajoutez des conducteurs depuis l'onglet Conducteurs")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(SNCFColors.ocre.opacity(0.08))
                )
            } else {
                // Badge indiquant la sélection
                if !selectedDriverIndices.isEmpty {
                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                            Text("\(selectedDriverIndices.count) sélectionné\(selectedDriverIndices.count > 1 ? "s" : "")")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(SNCFColors.ocre.opacity(0.1))
                        )
                        .foregroundStyle(SNCFColors.ocre)
                        
                        Button {
                            selectedDriverIndices.removeAll()
                        } label: {
                            Text("Tout désélectionner")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
                
                // Bouton de sélection
            Button {
                showingMultiDriverSelection = true
            } label: {
                    HStack(spacing: 8) {
                        Image(systemName: selectedDriverIndices.isEmpty ? "checklist" : "checklist.checked")
                            .font(.system(size: 16, weight: .semibold))
                        Text(selectedDriverIndices.isEmpty ? "Sélectionner les conducteurs" : "Modifier la sélection")
                            .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                            .opacity(0.6)
                }
                .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
                .buttonStyle(.bordered)
                .tint(SNCFColors.ocre)
            .disabled(vm.store.drivers.isEmpty)
                
                // Boutons d'export (comme pour un seul conducteur)
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button {
                            exportMultipleDriversAsJSON()
                        } label: {
                            HStack(spacing: 10) {
                                if isExportingJSON {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                Text("JSON")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SNCFColors.ceruleen)
                        .disabled(vm.store.drivers.isEmpty || isExportingJSON)
                        
                        Button {
                            exportMultipleDriversAsCSV()
                        } label: {
                            HStack(spacing: 10) {
                                if isExportingCSV {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "tablecells.fill")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                Text("CSV")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SNCFColors.menthe)
                        .disabled(vm.store.drivers.isEmpty || vm.store.checklist == nil || isExportingCSV)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.tertiarySystemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }
    // MARK: - Import Section
    
    @ViewBuilder
    private var importSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // En-tête de section
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [SNCFColors.menthe, SNCFColors.vertEau],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("Importer")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.bottom, 4)
            
            // Bouton import fichier
            Button {
                showingDriverFileImporter = true
            } label: {
                HStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [SNCFColors.menthe.opacity(0.15), SNCFColors.vertEau.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                        Image(systemName: "doc.badge.plus.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [SNCFColors.menthe, SNCFColors.vertEau],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Importer depuis fichier")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Un ou plusieurs conducteurs depuis un fichier JSON")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .opacity(0.5)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.tertiarySystemBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Importer depuis fichier")
            .accessibilityHint("Ouvre le sélecteur de fichiers pour importer un ou plusieurs conducteurs depuis un fichier JSON")
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Checklist Section
    
    @ViewBuilder
    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // En-tête de section
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [SNCFColors.lavande, SNCFColors.vieuxRose],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("Checklist")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.bottom, 4)
            
            if let checklist = vm.store.checklist {
                VStack(alignment: .leading, spacing: 18) {
                    // Informations de la checklist avec badge
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(checklist.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                            HStack(spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "list.bullet.rectangle")
                                        .font(.caption2)
                                    Text("\(checklist.items.filter { !$0.isCategory }.count) questions")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(SNCFColors.parme.opacity(0.12))
                                )
                                .foregroundStyle(SNCFColors.parme)
                            }
                        }
                        Spacer()
                    }
                    
                    // Bouton d'export
                    Button {
                        exportChecklist()
                    } label: {
                        HStack(spacing: 12) {
                            if isExportingChecklist {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.up.fill")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            Text("Exporter la checklist")
                                .fontWeight(.semibold)
                            Spacer()
                            if !isExportingChecklist {
                                Image(systemName: "doc.fill")
                                    .font(.caption)
                                    .opacity(0.6)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SNCFColors.lavande)
                    .disabled(isExportingChecklist)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.tertiarySystemBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                )
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.title3)
                        .foregroundStyle(SNCFColors.lavande.opacity(0.7))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Aucune checklist chargée")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Importez une checklist depuis un fichier JSON")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(SNCFColors.lavande.opacity(0.08))
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Helper Methods
    
    private func exportSingleDriver() {
        guard vm.store.drivers.indices.contains(selectedDriverIndex) else { return }
        let driverName = vm.store.drivers[selectedDriverIndex].name // Capture avant Task
        Task { @MainActor in
            isExportingJSON = true
            defer { isExportingJSON = false }
            if let url = vm.exportDriverAsJSON(at: selectedDriverIndex) {
                shareItems = [url]
                showingShareSheet = true
                Logger.success("Conducteur exporté: \(driverName)", category: "SharingView")
            } else {
                importErrorMessage = "Erreur lors de l'export du conducteur"
                Logger.error("Erreur lors de l'export du conducteur", category: "SharingView")
            }
        }
    }
    
    private func exportChecklist() {
        Task { @MainActor in
            isExportingChecklist = true
            defer { isExportingChecklist = false }
            guard let jsonData = vm.exportChecklistAsJSON() else {
                importErrorMessage = "Erreur lors de l'export de la checklist"
                Logger.error("Erreur lors de l'export de la checklist", category: "SharingView")
                return
            }
            let fileName = "checklist_\(Int(Date().timeIntervalSince1970)).json"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            do {
                try jsonData.write(to: tempURL)
                shareItems = [tempURL]
                showingShareSheet = true
                Logger.success("Checklist exportée", category: "SharingView")
            } catch {
                importErrorMessage = "Erreur lors de l'export : \(error.localizedDescription)"
                Logger.error("Erreur lors de l'export: \(error.localizedDescription)", category: "SharingView")
            }
        }
    }
    
    @ViewBuilder
    private var multiDriverSelectionSheet: some View {
        NavigationStack {
            List(selection: $selectedDriverIndices) {
                ForEach(vm.store.drivers.indices, id: \.self) { i in
                    HStack {
                        Image(systemName: "person")
                            .foregroundStyle(SNCFColors.ceruleen)
                        VStack(alignment: .leading, spacing: 4) {
                            // Affiche le prénom et le nom du conducteur
                            Text(vm.store.drivers[i].fullName)
                                .font(.headline)
                            if let lastEval = vm.store.drivers[i].lastEvaluation {
                                Text("Dernier suivi : \(DateFormatHelper.formatDate(lastEval))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let checklist = vm.store.checklist {
                                let progress = calculateProgress(for: i, checklist: checklist)
                                Text("Progression : \(Int(progress * 100))%")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if let start = vm.store.drivers[i].triennialStart,
                           let due = Calendar.current.date(byAdding: .year, value: AppConstants.Date.triennialYears, to: start) {
                            let cal = Calendar.current
                            let startDay = cal.startOfDay(for: Date())
                            let endDay = cal.startOfDay(for: due)
                            let remaining = cal.dateComponents([.day], from: startDay, to: endDay).day ?? 0
                            Image(systemName: remaining <= AppConstants.Date.criticalDaysThreshold ? "exclamationmark.triangle.fill" : (remaining <= AppConstants.Date.warningDaysThreshold ? "exclamationmark.triangle" : "checkmark.circle"))
                                .foregroundStyle(remaining <= AppConstants.Date.criticalDaysThreshold ? SNCFColors.corail : (remaining <= AppConstants.Date.warningDaysThreshold ? SNCFColors.safran : SNCFColors.menthe))
                        }
                    }
                    .tag(i)
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Sélectionner les conducteurs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        showingMultiDriverSelection = false
                        selectedDriverIndices.removeAll()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Terminer") {
                        showingMultiDriverSelection = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    @MainActor
    private func exportSelectedDrivers() {
        let indices = Array(selectedDriverIndices).sorted()
        
        guard let url = vm.exportDriversAsJSON(indices: indices) else {
            importErrorMessage = "Erreur lors de l'export des conducteurs"
            showingMultiDriverSelection = false
            Logger.error("Erreur lors de l'export de \(indices.count) conducteur(s)", category: "SharingView")
            return
        }
        
        // Fermer la vue de sélection et afficher le sélecteur de partage
        showingMultiDriverSelection = false
        selectedDriverIndices.removeAll()
        
        // Présenter le sélecteur de partage
        shareItems = [url]
        showingShareSheet = true
        Logger.success("\(indices.count) conducteur(s) exporté(s)", category: "SharingView")
    }
    
    /// Exporte plusieurs conducteurs en JSON (utilise la sélection ou tous)
    private func exportMultipleDriversAsJSON() {
        let indices = selectedDriverIndices.isEmpty 
            ? Array(vm.store.drivers.indices) 
            : Array(selectedDriverIndices).sorted()
        
        guard !indices.isEmpty else {
            // Si aucune sélection, ouvrir la feuille de sélection
            showingMultiDriverSelection = true
            return
        }
        
        Task { @MainActor in
            isExportingJSON = true
            defer { isExportingJSON = false }
            guard let url = vm.exportDriversAsJSON(indices: indices) else {
                importErrorMessage = "Erreur lors de l'export des conducteurs"
                Logger.error("Erreur lors de l'export de \(indices.count) conducteur(s)", category: "SharingView")
                return
            }
            
            shareItems = [url]
            showingShareSheet = true
            Logger.success("\(indices.count) conducteur(s) exporté(s) en JSON", category: "SharingView")
        }
    }
    
    /// Exporte plusieurs conducteurs en CSV (utilise la sélection ou tous)
    private func exportMultipleDriversAsCSV() {
        let indices = selectedDriverIndices.isEmpty 
            ? nil // nil = tous les conducteurs
            : Array(selectedDriverIndices).sorted()
        
        if selectedDriverIndices.isEmpty && !vm.store.drivers.isEmpty {
            // Si aucune sélection mais des conducteurs disponibles, exporter tous
            exportAllDriversAsCSV()
            return
        }
        
        guard let indices = indices, !indices.isEmpty else {
            // Si aucune sélection, ouvrir la feuille de sélection
            showingMultiDriverSelection = true
            return
        }
        
        Task { @MainActor in
            isExportingCSV = true
            defer { isExportingCSV = false }
            guard let url = vm.exportDriversAsCSV(selectedIndices: indices) else {
                importErrorMessage = "Erreur lors de l'export CSV"
                Logger.error("Erreur lors de l'export CSV de \(indices.count) conducteur(s)", category: "SharingView")
                return
            }
            
            shareItems = [url]
            showingShareSheet = true
            Logger.success("\(indices.count) conducteur(s) exporté(s) en CSV", category: "SharingView")
        }
    }
    
    private func exportAllDriversAsCSV() {
        Task { @MainActor in
            isExportingCSV = true
            defer { isExportingCSV = false }
            guard let url = vm.exportDriversAsCSV(selectedIndices: nil) else {
                importErrorMessage = "Erreur lors de l'export CSV"
                Logger.error("Erreur lors de l'export CSV", category: "SharingView")
                return
            }
            
            shareItems = [url]
            showingShareSheet = true
            Logger.success("Export CSV réussi", category: "SharingView")
        }
    }
    
    private func exportSingleDriverAsCSV() {
        guard vm.store.drivers.indices.contains(selectedDriverIndex) else {
            importErrorMessage = "Erreur : conducteur non sélectionné"
            Logger.error("Erreur : conducteur non sélectionné pour l'export CSV", category: "SharingView")
            return
        }
        
        let driverName = vm.store.drivers[selectedDriverIndex].name // Capture avant Task
        Task { @MainActor in
            isExportingCSV = true
            defer { isExportingCSV = false }
            guard let url = vm.exportDriversAsCSV(selectedIndices: [selectedDriverIndex]) else {
                importErrorMessage = "Erreur lors de l'export CSV"
                Logger.error("Erreur lors de l'export CSV du conducteur", category: "SharingView")
                return
            }
            
            shareItems = [url]
            showingShareSheet = true
            Logger.success("Export CSV du conducteur réussi: \(driverName)", category: "SharingView")
        }
    }
    
    // MARK: - Import Methods
    
    private func handleDriverImport(result: Result<[URL], Error>) {
        Task { @MainActor in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                
                guard url.startAccessingSecurityScopedResource() else {
                    importErrorMessage = "Impossible d'accéder au fichier. Assurez-vous que le fichier est dans l'application Fichiers et réessayez."
                    Logger.error("Impossible d'accéder au fichier: \(url.path)", category: "SharingView")
                    return
                }
                
                defer {
                    url.stopAccessingSecurityScopedResource()
                }
                
                // Tenter d'abord d'importer plusieurs conducteurs
                importResults = vm.importDriversJSON(from: url)
                
                // Si l'import de plusieurs échoue avec une erreur, essayer un seul conducteur
                if importResults.count == 1, case .error = importResults.first {
                    let singleResult = vm.importDriverJSON(from: url)
                    importResults = [singleResult]
                }
                
                processImportResults()
                
            case .failure(let error):
                importErrorMessage = "Erreur lors de la sélection du fichier : \(error.localizedDescription)"
                Logger.error("Erreur de sélection de fichier: \(error.localizedDescription)", category: "SharingView")
            }
        }
    }
    
    @MainActor
    private func processImportResults() {
        var newDriversCount = 0
        var errors: [String] = []
        var hasExistingDriver = false
        
        // Traiter les résultats un par un
        for (index, result) in importResults.enumerated() {
            switch result {
            case .newDriver(let driver, let checklist, let checklistMatch, _):
                // Ajouter le conducteur directement
                vm.addImportedDriver(driver)
                newDriversCount += 1
                Logger.info("Nouveau conducteur ajouté: \(driver.name)", category: "SharingView")
                
                // Si la checklist est différente, on pourrait proposer de l'importer
                if checklist != nil, !checklistMatch {
                    // Optionnel : proposer d'importer la checklist aussi
                }
                
            case .existingDriver(let driverIndex, let importedDriver, _, _):
                // Demander la stratégie de fusion pour le premier conducteur existant
                if !hasExistingDriver {
                    hasExistingDriver = true
                    pendingMergeDriver = importedDriver
                    pendingMergeIndex = driverIndex
                    showingMergeDialog = true
                    // Garder les résultats restants pour traitement après fusion
                    importResults = Array(importResults.dropFirst(index + 1))
                    return // Sortir pour afficher le dialogue
                }
                
            case .error(let message):
                errors.append(message)
                Logger.error("Erreur d'import: \(message)", category: "SharingView")
            }
        }
        
        // Afficher un message de succès si des conducteurs ont été ajoutés
        if newDriversCount > 0 {
            importSuccessMessage = "Import réussi : \(newDriversCount) nouveau(x) conducteur(s) ajouté(s)"
            Logger.success("Import réussi: \(newDriversCount) conducteur(s)", category: "SharingView")
        }
        
        if !errors.isEmpty {
            importErrorMessage = errors.joined(separator: "\n")
        }
        
        // Réinitialiser les résultats
        importResults = []
    }
    
    @MainActor
    private func handleMerge(strategy: MergeStrategy) {
        guard let driver = pendingMergeDriver else {
            showingMergeDialog = false
            processImportResults()
            return
        }
        
        vm.mergeDriver(driver, at: pendingMergeIndex, strategy: strategy)
        pendingMergeDriver = nil
        showingMergeDialog = false
        Logger.info("Conducteur fusionné avec stratégie: \(strategy.title)", category: "SharingView")
        
        // Continuer à traiter les autres résultats
        processImportResults()
    }
    
    // MARK: - Helper Methods
    
    /// Valide et met à jour l'index sélectionné pour s'assurer qu'il est toujours valide
    private func validateAndUpdateSelectedIndex() {
        if vm.store.drivers.indices.contains(vm.selectedDriverIndex) {
            selectedDriverIndex = vm.selectedDriverIndex
        } else if !vm.store.drivers.isEmpty {
            // Si l'index n'est pas valide mais qu'il y a des conducteurs, utiliser le premier
            selectedDriverIndex = 0
        } else {
            // Si aucun conducteur, réinitialiser à 0
            selectedDriverIndex = 0
        }
    }
    
    private func calculateProgress(for driverIndex: Int, checklist: Checklist) -> Double {
        guard vm.store.drivers.indices.contains(driverIndex) else { return 0 }
        
        let driver = vm.store.drivers[driverIndex]
        let questions = checklist.questions
        guard !questions.isEmpty else { return 0 }
        
        let checklistTitle = checklist.title
        let stateMap = driver.checklistStates[checklistTitle] ?? [:]
        let checkedCount = questions.filter { stateMap[$0.id.uuidString] == 2 }.count
        
        return Double(checkedCount) / Double(questions.count)
    }
}



