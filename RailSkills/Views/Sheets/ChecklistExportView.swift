//
//  ChecklistExportView.swift
//  RailSkills
//
//  Vue pour exporter une checklist (JSON ou PDF)
//

import SwiftUI

/// Vue pour exporter une checklist
struct ChecklistExportView: View {
    let checklist: Checklist
    let checklistType: ChecklistType
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        exportAsJSON()
                    } label: {
                        HStack {
                            Label("Exporter en JSON", systemImage: "doc.text")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    Button {
                        exportAsPDF()
                    } label: {
                        HStack {
                            Label("Exporter en PDF", systemImage: "doc.richtext")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("Format d'export")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Checklist:")
                                .foregroundStyle(.secondary)
                            Text(checklist.title)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Type:")
                                .foregroundStyle(.secondary)
                            Text(checklistType.displayTitle)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Questions:")
                                .foregroundStyle(.secondary)
                            Text("\(checklist.questions.count)")
                                .fontWeight(.medium)
                        }
                    }
                    .font(.subheadline)
                    .padding(.vertical, 4)
                } header: {
                    Text("Informations")
                }
            }
            .navigationTitle("Partager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
        .shareSheet(isPresented: $showingShareSheet, activityItems: shareItems)
    }
    
    // MARK: - Export Functions
    
    private func exportAsJSON() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(checklist)
            
            // Créer un fichier temporaire
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(checklist.title)_\(checklistType.rawValue).json")
            
            try jsonData.write(to: tempURL)
            
            shareItems = [tempURL]
            showingShareSheet = true
        } catch {
            print("Erreur lors de l'export JSON: \(error)")
        }
    }
    
    private func exportAsPDF() {
        // TODO: Implémenter l'export PDF via PDFReportGenerator
        print("Export PDF pour \(checklistType.displayTitle) - À implémenter avec PDFReportGenerator")
    }
}
