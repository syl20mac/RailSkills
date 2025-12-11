//
//  AppViewModel+Sharing.swift
//  RailSkills
//
//  Extension pour le partage et la collaboration (export/import de conducteurs)
//

import Foundation
import UIKit

// MARK: - Partage et collaboration
extension AppViewModel {
    
    /// Exporte le conducteur sélectionné au format JSON
    /// - Returns: L'URL du fichier exporté ou nil en cas d'erreur
    func exportSelectedDriverAsJSON() -> URL? {
        return exportDriverAsJSON(at: selectedDriverIndex)
    }
    
    /// Exporte un conducteur spécifique au format JSON
    /// - Parameter index: L'index du conducteur à exporter
    /// - Returns: L'URL du fichier exporté ou nil en cas d'erreur
    func exportDriverAsJSON(at index: Int) -> URL? {
        guard store.drivers.indices.contains(index) else {
            Logger.error("Index conducteur invalide: \(index)", category: "AppViewModel")
            return nil
        }
        
        // Rate limiting
        guard canExport() else { return nil }
        
        let driver = store.drivers[index]
        
        guard let data = ExportService.exportDriver(driver, checklist: store.checklist, compress: false) else {
            return nil
        }
        
        let safeName = ValidationService.sanitizeFileName(driver.name)
        
        let fileName = "Conducteur_\(safeName)_\(Int(Date().timeIntervalSince1970)).json"
        
        // Utiliser le répertoire temporaire pour le partage
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            Self.lastExportDate = Date()
            AuditLogger.shared.log(
                action: .driverExported,
                target: driver.name,
                details: ["format": "JSON", "file": fileName]
            )
            Logger.success("Fichier exporté: \(tempURL.path)", category: "AppViewModel")
            return tempURL
        } catch {
            Logger.error("Erreur d'export JSON du conducteur: \(error.localizedDescription)", category: "AppViewModel")
            return nil
        }
    }
    
    /// Importe un conducteur depuis un fichier JSON
    /// - Parameter url: L'URL du fichier JSON
    /// - Returns: Le résultat de l'import
    func importDriverJSON(from url: URL) -> ImportResult {
        guard let data = try? Data(contentsOf: url) else {
            return .error("Impossible de lire le fichier")
        }
        
        // Valider les données avant import
        switch ValidationService.validateImportData(data) {
        case .failure(let error):
            return .error("Fichier invalide: \(error.localizedDescription)")
        case .success:
            break
        }
        
        guard let shareableDriver = ExportService.importDriver(from: data) else {
            return .error("Impossible de lire ou décoder le fichier")
        }
        
        // Vérifier si la checklist correspond
        let checklistMatch = store.checklist?.title == shareableDriver.checklist?.title
        
        if let existingIndex = store.drivers.firstIndex(where: { $0.id == shareableDriver.driver.id }) {
            // Conducteur existant - proposer une fusion
            AuditLogger.shared.log(
                action: .driverImported,
                target: shareableDriver.driver.name,
                details: ["status": "existing", "driver_id": shareableDriver.driver.id.uuidString]
            )
            return .existingDriver(
                index: existingIndex,
                importedDriver: shareableDriver.driver,
                checklistMatch: checklistMatch,
                exportDate: shareableDriver.exportDate
            )
        } else {
            // Nouveau conducteur
            AuditLogger.shared.log(
                action: .driverImported,
                target: shareableDriver.driver.name,
                details: ["status": "new", "driver_id": shareableDriver.driver.id.uuidString]
            )
            return .newDriver(
                driver: shareableDriver.driver,
                checklist: shareableDriver.checklist,
                checklistMatch: checklistMatch,
                exportDate: shareableDriver.exportDate
            )
        }
    }
    
    /// Fusionne un conducteur importé avec un conducteur existant selon la stratégie choisie
    /// - Parameters:
    ///   - importedDriver: Le conducteur importé
    ///   - index: L'index du conducteur existant
    ///   - strategy: La stratégie de fusion
    func mergeDriver(_ importedDriver: DriverRecord, at index: Int, strategy: MergeStrategy) {
        guard store.drivers.indices.contains(index) else { return }
        
        var existingDriver = store.drivers[index]
        
        var updatedDrivers = store.drivers
        
        switch strategy {
        case .replaceAll:
            updatedDrivers[index] = importedDriver
            
        case .keepNewer:
            if let importedDate = importedDriver.lastEvaluation,
               let existingDate = existingDriver.lastEvaluation {
                if importedDate > existingDate {
                    updatedDrivers[index] = importedDriver
                }
            } else if importedDriver.lastEvaluation != nil {
                updatedDrivers[index] = importedDriver
            }
            
        case .mergeChecklistStates:
            // Fusionner les états de checklist
            for (checklistTitle, states) in importedDriver.checklistStates {
                if var existingStates = existingDriver.checklistStates[checklistTitle] {
                    // Fusionner les états, en prenant les plus récents
                    for (itemId, state) in states {
                        existingStates[itemId] = state
                    }
                    existingDriver.checklistStates[checklistTitle] = existingStates
                } else {
                    existingDriver.checklistStates[checklistTitle] = states
                }
            }
            
            // Fusionner les dates de suivi
            for (checklistTitle, dates) in importedDriver.checklistDates {
                if var existingDates = existingDriver.checklistDates[checklistTitle] {
                    for (itemId, date) in dates {
                        if let existingDate = existingDates[itemId] {
                            // Garder la date la plus récente
                            if date > existingDate {
                                existingDates[itemId] = date
                            }
                        } else {
                            existingDates[itemId] = date
                        }
                    }
                    existingDriver.checklistDates[checklistTitle] = existingDates
                } else {
                    existingDriver.checklistDates[checklistTitle] = dates
                }
            }
            
            // Mettre à jour la date de suivi si l'importée est plus récente
            if let importedDate = importedDriver.lastEvaluation {
                if let existingDate = existingDriver.lastEvaluation {
                    if importedDate > existingDate {
                        existingDriver.lastEvaluation = importedDate
                    }
                } else {
                    // Pas de date existante, utiliser la date importée
                    existingDriver.lastEvaluation = importedDate
                }
            }
            
            updatedDrivers[index] = existingDriver
        }
        
        // Assigner le nouveau tableau pour forcer le didSet
        store.drivers = updatedDrivers
        
        // Invalider le cache
        cachedProgress = nil
        cachedStateMap = nil
    }
    
    /// Ajoute un conducteur importé à la liste
    func addImportedDriver(_ driver: DriverRecord) {
        store.drivers.append(driver)
    }
    
    /// Exporte plusieurs conducteurs au format JSON
    /// - Parameter indices: Les indices des conducteurs à exporter
    /// - Returns: L'URL du fichier exporté ou nil en cas d'erreur
    func exportDriversAsJSON(indices: [Int]) -> URL? {
        // Rate limiting
        guard canExport() else { return nil }
        
        let drivers = indices.compactMap { idx in
            store.drivers.indices.contains(idx) ? store.drivers[idx] : nil
        }
        
        guard !drivers.isEmpty else {
            Logger.warning("Aucun conducteur à exporter", category: "AppViewModel")
            return nil
        }
        
        guard let data = ExportService.exportDrivers(drivers, checklist: store.checklist, compress: false) else {
            return nil
        }
        
        let fileName: String
        if drivers.count == 1 {
            let safeName = ValidationService.sanitizeFileName(drivers[0].name)
            fileName = "Conducteur_\(safeName)_\(Int(Date().timeIntervalSince1970)).json"
        } else {
            fileName = "Conducteurs_\(drivers.count)_\(Int(Date().timeIntervalSince1970)).json"
        }
        
        // Utiliser le répertoire temporaire pour le partage
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            Self.lastExportDate = Date()
            let driverNames = drivers.map { $0.name }.joined(separator: ", ")
            AuditLogger.shared.log(
                action: .driverExported,
                target: "\(drivers.count) conducteur(s)",
                details: ["format": "JSON", "count": "\(drivers.count)", "names": driverNames]
            )
            Logger.success("Fichier exporté: \(tempURL.path) (\(drivers.count) conducteur(s))", category: "AppViewModel")
            return tempURL
        } catch {
            Logger.error("Erreur d'export JSON des conducteurs: \(error.localizedDescription)", category: "AppViewModel")
            return nil
        }
    }
    
    /// Importe plusieurs conducteurs depuis un fichier JSON
    /// - Parameter url: L'URL du fichier JSON
    /// - Returns: Le résultat de l'import
    func importDriversJSON(from url: URL) -> [ImportResult] {
        guard let data = try? Data(contentsOf: url) else {
            return [.error("Impossible de lire le fichier")]
        }
        
        // Valider les données avant import
        switch ValidationService.validateImportData(data) {
        case .failure(let error):
            return [.error("Fichier invalide: \(error.localizedDescription)")]
        case .success:
            break
        }
        
        guard let shareableDrivers = ExportService.importDrivers(from: data) else {
            return [.error("Impossible de lire ou décoder le fichier")]
        }
        
        var results: [ImportResult] = []
        
        for shareableDriver in shareableDrivers.drivers {
            let checklistMatch = store.checklist?.title == shareableDriver.checklist?.title
            
            if let existingIndex = store.drivers.firstIndex(where: { $0.id == shareableDriver.driver.id }) {
                results.append(.existingDriver(
                    index: existingIndex,
                    importedDriver: shareableDriver.driver,
                    checklistMatch: checklistMatch,
                    exportDate: shareableDriver.exportDate
                ))
            } else {
                results.append(.newDriver(
                    driver: shareableDriver.driver,
                    checklist: shareableDriver.checklist,
                    checklistMatch: checklistMatch,
                    exportDate: shareableDriver.exportDate
                ))
            }
        }
        
        AuditLogger.shared.log(
            action: .driverImported,
            target: "\(shareableDrivers.drivers.count) conducteur(s)",
            details: ["count": "\(shareableDrivers.drivers.count)", "format": "JSON"]
        )
        return results
    }
    
    /// Exporte les conducteurs au format CSV pour Excel
    /// - Parameter selectedIndices: Les indices des conducteurs à exporter (nil = tous)
    /// - Returns: L'URL du fichier CSV exporté ou nil en cas d'erreur
    func exportDriversAsCSV(selectedIndices: [Int]? = nil) -> URL? {
        // Rate limiting
        guard canExport() else { return nil }
        
        let driversToExport: [DriverRecord]
        
        if let indices = selectedIndices {
            driversToExport = indices.compactMap { index in
                store.drivers.indices.contains(index) ? store.drivers[index] : nil
            }
        } else {
            driversToExport = store.drivers
        }
        
        guard !driversToExport.isEmpty, let checklist = store.checklist else {
            Logger.error("Impossible d'exporter en CSV : aucun conducteur ou checklist manquante", category: "AppViewModel")
            return nil
        }
        
        guard let csvData = ExportService.exportDriversAsCSV(driversToExport, checklist: checklist, includeNotes: true) else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let dateStr = dateFormatter.string(from: Date())
        
        let fileName: String
        if driversToExport.count == 1 {
            let safeName = ValidationService.sanitizeFileName(driversToExport[0].name)
            fileName = "RailSkills_\(safeName)_\(dateStr).csv"
        } else {
            fileName = "RailSkills_Export_\(dateStr).csv"
        }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvData.write(to: tempURL)
            Self.lastExportDate = Date()
            let driverNames = driversToExport.map { $0.name }.joined(separator: ", ")
            AuditLogger.shared.log(
                action: .driverExported,
                target: "\(driversToExport.count) conducteur(s)",
                details: ["format": "CSV", "count": "\(driversToExport.count)", "names": driverNames]
            )
            Logger.success("Fichier CSV exporté: \(tempURL.path)", category: "AppViewModel")
            return tempURL
        } catch {
            Logger.error("Erreur d'export CSV: \(error.localizedDescription)", category: "AppViewModel")
            return nil
        }
    }
    
    // MARK: - Rate Limiting
    
    /// Dernière date d'export pour rate limiting
    private static var lastExportDate: Date?
    
    /// Vérifie si un export peut être effectué (rate limiting)
    /// - Returns: true si l'export est autorisé, false sinon
    private func canExport() -> Bool {
        if let lastDate = Self.lastExportDate {
            let timeSinceLastExport = Date().timeIntervalSince(lastDate)
            if timeSinceLastExport < AppConstants.Export.cooldownDelay {
                Logger.warning("Export trop rapide, attente requise (\(Int(AppConstants.Export.cooldownDelay - timeSinceLastExport))s)", category: "AppViewModel")
                return false
            }
        }
        Self.lastExportDate = Date()
        return true
    }
}



