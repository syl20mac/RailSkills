//
//  ImportDriversFromSharePointView.swift
//  RailSkills
//
//  Vue d'import de conducteurs depuis SharePoint
//

import SwiftUI

/// Vue d'import de conducteurs depuis SharePoint
struct ImportDriversFromSharePointView: View {
    @ObservedObject var vm: ViewModel
    @Binding var isPresented: Bool
    @State private var isImporting = false
    @State private var importMessage: String?
    @State private var importSuccess: Bool = false
    @State private var showingResult = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Importez les conducteurs depuis SharePoint. Cela récupère les conducteurs créés depuis le site web ou d'autres appareils.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Instructions")
                }
                
                Section {
                    Button {
                        importFromSharePoint()
                    } label: {
                        HStack {
                            if isImporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            } else {
                                Image(systemName: "tray.and.arrow.down")
                                    .padding(.trailing, 8)
                            }
                            Text(isImporting ? "Import en cours..." : "Importer depuis SharePoint")
                        }
                    }
                    .disabled(isImporting || !SharePointSyncService.shared.isConfigured)
                } header: {
                    Text("Import")
                } footer: {
                    if !SharePointSyncService.shared.isConfigured {
                        Text("SharePoint n'est pas configuré. Allez dans Réglages → Synchronisation SharePoint pour le configurer.")
                            .foregroundStyle(.orange)
                    }
                }
                
                if isImporting {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Téléchargement des conducteurs...")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Importer depuis SharePoint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        isPresented = false
                    }
                }
            }
            .alert("Résultat de l'import", isPresented: $showingResult) {
                Button("OK") {
                    if importSuccess {
                        isPresented = false
                    }
                }
            } message: {
                if let message = importMessage {
                    Text(message)
                }
            }
        }
    }
    
    private func importFromSharePoint() {
        isImporting = true
        let driversCountBefore = vm.store.drivers.count
        
        Task {
            // Utiliser la synchronisation bidirectionnelle pour récupérer les modifications
            await vm.store.syncDriversBidirectional()
            
            await MainActor.run {
                let driversCountAfter = vm.store.drivers.count
                let newDriversCount = driversCountAfter - driversCountBefore
                
                if newDriversCount > 0 {
                    importMessage = "\(newDriversCount) nouveau(x) conducteur(s) récupéré(s) depuis SharePoint. Total: \(driversCountAfter) conducteur(s)."
                    importSuccess = true
                } else if driversCountAfter > 0 {
                    importMessage = "Synchronisation réussie. Aucun nouveau conducteur détecté. Total: \(driversCountAfter) conducteur(s)."
                    importSuccess = true
                } else {
                    importMessage = "Aucun conducteur trouvé dans SharePoint. Vérifiez que les conducteurs ont été créés correctement."
                    importSuccess = false
                }
                
                showingResult = true
                isImporting = false
            }
        }
    }
}

