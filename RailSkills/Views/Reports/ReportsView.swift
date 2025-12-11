//
//  ReportsView.swift
//  RailSkills
//
//  Vue de génération et export de rapports PDF
//

import SwiftUI

/// Vue de génération et export de rapports PDF
struct ReportsView: View {
    @ObservedObject var vm: ViewModel
    @State private var showingSelectionExporter: Bool = false
    @State private var selectedExportIndices: Set<Int> = []

    var body: some View {
        NavigationStack {
            Group {
                // Afficher la vue d'import si la checklist est nil ou vide
                if vm.store.checklist == nil || vm.store.checklist?.items.isEmpty == true {
                    ChecklistImportWelcomeView(vm: vm)
                } else {
                    List {
                        Section {
                            ShareLink(
                                item: PDFReportGenerator.generatePDF(forDrivers: vm.store.drivers, vm: vm),
                                preview: SharePreview("Rapport PDF - Tous les conducteurs", image: Image(systemName: "doc.richtext"))
                            ) {
                                Label("Export de rapport de suivi — Tous les conducteurs", systemImage: "doc.richtext.fill")
                            }
                            .disabled(vm.store.drivers.isEmpty)

                            Button {
                                showingSelectionExporter = true
                            } label: {
                                Label("Export de rapport de suivi — Sélection", systemImage: "person.3.sequence.fill")
                            }
                            .disabled(vm.store.drivers.isEmpty)
                        } header: {
                            Text("Rapports PDF")
                        }
                    }
                }
            }
            .navigationTitle("Rapport")
            .sheet(isPresented: $showingSelectionExporter) {
                selectionExportSheet
            }
        }
    }

    @ViewBuilder
    private var selectionExportSheet: some View {
        NavigationStack {
            List(selection: $selectedExportIndices) {
                ForEach(vm.store.drivers.indices, id: \.self) { i in
                    HStack {
                        Image(systemName: "person")
                            .foregroundStyle(.blue)
                        Text(vm.store.drivers[i].name)
                        Spacer()
                        if let start = vm.store.drivers[i].triennialStart,
                           let due = Calendar.current.date(byAdding: .year, value: AppConstants.Date.triennialYears, to: start) {
                            let cal = Calendar.current
                            let startDay = cal.startOfDay(for: Date())
                            let endDay = cal.startOfDay(for: due)
                            let remaining = cal.dateComponents([.day], from: startDay, to: endDay).day ?? 0
                            Image(systemName: remaining <= AppConstants.Date.criticalDaysThreshold ? "exclamationmark.triangle.fill" : (remaining <= AppConstants.Date.warningDaysThreshold ? "exclamationmark.triangle" : "checkmark.circle"))
                                .foregroundStyle(remaining <= AppConstants.Date.criticalDaysThreshold ? Color.red : (remaining <= AppConstants.Date.warningDaysThreshold ? Color.orange : Color.green))
                        }
                    }
                    .tag(i)
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Sélection PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        showingSelectionExporter = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !selectedExportIndices.isEmpty {
                        let drivers = selectedExportIndices.compactMap { idx in
                            vm.store.drivers.indices.contains(idx) ? vm.store.drivers[idx] : nil
                        }
                        ShareLink(
                            item: PDFReportGenerator.generatePDF(forDrivers: drivers, vm: vm),
                            preview: SharePreview("Rapport PDF (sélection)", image: Image(systemName: "doc.richtext"))
                        ) {
                            Text("Exporter")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
    }

}

