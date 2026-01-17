//
//  ExportService.swift
//  RailSkills
//
//  Service d'export et d'import de données avec compression
//

import Foundation

/// Service d'export et d'import de données
enum ExportService {
    /// Exporte un conducteur au format JSON avec compression et chiffrement
    /// - Parameter driver: Le conducteur à exporter
    /// - Parameter checklist: La checklist associée (optionnelle)
    /// - Parameter compress: Si true, compresse les données avec LZFSE
    /// - Parameter encrypt: Si true, chiffre les données avec AES-GCM (par défaut: true)
    /// - Returns: Les données encodées, ou nil en cas d'erreur
    static func exportDriver(_ driver: DriverRecord, checklist: Checklist?, compress: Bool = true, encrypt: Bool = true) -> Data? {
        let shareableDriver = ShareableDriverRecord(
            driver: driver,
            checklist: checklist,
            exportDate: Date(),
            exporterInfo: AppConstants.Data.exporterInfo,
            version: AppConstants.Data.exportFormatVersion
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            var data = try encoder.encode(shareableDriver)
            
            // Étape 1: Compression
            if compress {
                data = data.compressed
            }
            
            // Étape 2: Chiffrement (par défaut activé pour les conducteurs)
            if encrypt {
                guard let encryptedData = EncryptionService.encrypt(data) else {
                    Logger.error("Échec du chiffrement lors de l'export du conducteur", category: "ExportService")
                    return nil
                }
                data = encryptedData
            }
            
            return data
        } catch {
            Logger.error("Erreur lors de l'export du conducteur: \(error.localizedDescription)", category: "ExportService")
            return nil
        }
    }
    
    /// Importe un conducteur depuis des données JSON (avec détection automatique du chiffrement)
    /// - Parameter data: Les données à importer (potentiellement compressées et/ou chiffrées)
    /// - Returns: Un ShareableDriverRecord décodé, ou nil en cas d'erreur
    static func importDriver(from data: Data) -> ShareableDriverRecord? {
        do {
            var processedData = data
            
            // Étape 1: Déchiffrement (si nécessaire)
            if EncryptionService.isEncrypted(processedData) {
                guard let decryptedData = EncryptionService.decrypt(processedData) else {
                    Logger.error("Échec du déchiffrement lors de l'import du conducteur", category: "ExportService")
                    return nil
                }
                processedData = decryptedData
            }
            
            // Étape 2: Décompression (si nécessaire)
            let decompressedData = processedData.decompressed
            
            // Étape 3: Décodage JSON
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ShareableDriverRecord.self, from: decompressedData)
        } catch {
            Logger.error("Erreur lors de l'import du conducteur: \(error.localizedDescription)", category: "ExportService")
            return nil
        }
    }
    
    /// Exporte une checklist au format JSON
    /// - Parameters:
    ///   - checklist: La checklist à exporter
    ///   - compress: Si true, compresse les données avec LZFSE
    /// - Returns: Les données JSON encodées (et optionnellement compressées), ou nil en cas d'erreur
    static func exportChecklist(_ checklist: Checklist, compress: Bool = false) -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = compress ? [] : [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(checklist)
            
            if compress {
                // Compression LZFSE pour réduire la taille
                guard let compressedData = try? (jsonData as NSData).compressed(using: .lzfse) as Data else {
                    Logger.error("Échec de la compression LZFSE de la checklist", category: "ExportService")
                    return nil
                }
                let originalSize = jsonData.count
                let compressedSize = compressedData.count
                let reduction = originalSize > 0 ? Int((1.0 - Double(compressedSize) / Double(originalSize)) * 100) : 0
                Logger.debug("Checklist compressée: \(originalSize) → \(compressedSize) octets (\(reduction)% réduction)", category: "ExportService")
                return compressedData
            }
            
            return jsonData
        } catch {
            Logger.error("Erreur lors de l'export de la checklist: \(error.localizedDescription)", category: "ExportService")
            return nil
        }
    }
    
    /// Importe une checklist depuis des données JSON (potentiellement compressées)
    /// - Parameter data: Les données JSON à importer (compressées ou non)
    /// - Returns: Une Checklist décodée, ou nil en cas d'erreur
    static func importChecklist(from data: Data) -> Checklist? {
        let decoder = JSONDecoder()
        
        // Essayer d'abord de décoder directement (non compressé)
        if let checklist = try? decoder.decode(Checklist.self, from: data) {
            return checklist
        }
        
        // Sinon, essayer de décompresser d'abord (LZFSE)
        do {
            let decompressedData = try (data as NSData).decompressed(using: .lzfse) as Data
            Logger.debug("Checklist décompressée: \(data.count) → \(decompressedData.count) octets", category: "ExportService")
            return try decoder.decode(Checklist.self, from: decompressedData)
        } catch {
            Logger.error("Erreur lors de l'import de la checklist: \(error.localizedDescription)", category: "ExportService")
            return nil
        }
    }
    
    /// Exporte plusieurs conducteurs au format JSON avec compression et chiffrement
    /// - Parameters:
    ///   - drivers: Les conducteurs à exporter
    ///   - checklist: La checklist associée (optionnelle)
    ///   - compress: Si true, compresse les données avec LZFSE
    ///   - encrypt: Si true, chiffre les données avec AES-GCM (par défaut: true)
    /// - Returns: Les données encodées, ou nil en cas d'erreur
    static func exportDrivers(_ drivers: [DriverRecord], checklist: Checklist?, compress: Bool = true, encrypt: Bool = true) -> Data? {
        let shareableDrivers = drivers.map { driver in
            ShareableDriverRecord(
                driver: driver,
                checklist: checklist,
                exportDate: Date(),
                exporterInfo: AppConstants.Data.exporterInfo,
                version: AppConstants.Data.exportFormatVersion
            )
        }
        
        let shareableRecord = ShareableDriversRecord(
            drivers: shareableDrivers,
            exportDate: Date(),
            exporterInfo: AppConstants.Data.exporterInfo,
            version: AppConstants.Data.exportFormatVersion
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            var data = try encoder.encode(shareableRecord)
            
            // Étape 1: Compression
            if compress {
                data = data.compressed
            }
            
            // Étape 2: Chiffrement (par défaut activé pour les conducteurs)
            if encrypt {
                guard let encryptedData = EncryptionService.encrypt(data) else {
                    Logger.error("Échec du chiffrement lors de l'export des conducteurs", category: "ExportService")
                    return nil
                }
                data = encryptedData
            }
            
            return data
        } catch {
            Logger.error("Erreur lors de l'export des conducteurs: \(error.localizedDescription)", category: "ExportService")
            return nil
        }
    }
    
    /// Importe plusieurs conducteurs depuis des données JSON (avec détection automatique du chiffrement)
    /// - Parameter data: Les données à importer (potentiellement compressées et/ou chiffrées)
    /// - Returns: Un ShareableDriversRecord décodé, ou nil en cas d'erreur
    static func importDrivers(from data: Data) -> ShareableDriversRecord? {
        do {
            var processedData = data
            
            // Étape 1: Déchiffrement (si nécessaire)
            if EncryptionService.isEncrypted(processedData) {
                guard let decryptedData = EncryptionService.decrypt(processedData) else {
                    Logger.error("Échec du déchiffrement lors de l'import des conducteurs", category: "ExportService")
                    return nil
                }
                processedData = decryptedData
            }
            
            // Étape 2: Décompression (si nécessaire)
            let decompressedData = processedData.decompressed
            
            // Étape 3: Décodage JSON
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ShareableDriversRecord.self, from: decompressedData)
        } catch {
            Logger.error("Erreur lors de l'import des conducteurs: \(error.localizedDescription)", category: "ExportService")
            return nil
        }
    }
    
    /// Exporte les données de conducteurs au format CSV pour Excel
    /// - Parameters:
    ///   - drivers: Les conducteurs à exporter
    ///   - checklist: La checklist associée
    ///   - includeNotes: Si true, inclut les notes (par défaut: true)
    /// - Returns: Les données CSV encodées en UTF-8 avec BOM, ou nil en cas d'erreur
    static func exportDriversAsCSV(_ drivers: [DriverRecord], checklist: Checklist?, includeNotes: Bool = true) -> Data? {
        guard let checklist = checklist else {
            Logger.error("Impossible d'exporter en CSV sans checklist", category: "ExportService")
            return nil
        }
        
        var csvLines: [String] = []
        
        // En-têtes CSV avec séparateur point-virgule (standard européen pour Excel)
        let headers = [
            "Nom du conducteur",
            "Date début triennale",
            "Échéance triennale",
            "Jours restants",
            "Catégorie",
            "Question",
            "État",
            "État (texte)",
            "Date de suivi",
            "Note"
        ]
        csvLines.append(headers.joined(separator: ";"))
        
        // Fonction helper pour échapper les valeurs CSV
        func escapeCSV(_ value: String) -> String {
            var escaped = value
            // Remplacer les guillemets doubles par deux guillemets
            escaped = escaped.replacingOccurrences(of: "\"", with: "\"\"")
            // Si contient ; ou \n, entourer de guillemets
            if escaped.contains(";") || escaped.contains("\n") || escaped.contains("\"") {
                escaped = "\"\(escaped)\""
            }
            return escaped
        }
        
        // Parcourir chaque conducteur
        for driver in drivers {
            let checklistKey = checklist.title
            let statesMap = driver.checklistStates[checklistKey] ?? [:]
            let notesMap = driver.checklistNotes[checklistKey] ?? [:]
            let datesMap = driver.checklistDates[checklistKey] ?? [:]
            
            // Calculer l'échéance triennale
            var triennialDue: String = ""
            var daysRemaining: String = ""
            if let start = driver.triennialStart,
               let due = Calendar.current.date(byAdding: .year, value: 3, to: start) {
                triennialDue = DateFormatHelper.formatDate(due)
                let remaining = Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0
                daysRemaining = "\(remaining)"
            }
            
            let triennialStartStr = driver.triennialStart != nil ? DateFormatHelper.formatDate(driver.triennialStart!) : ""
            
            // Parcourir les items de la checklist
            var currentCategory = ""
            
            for item in checklist.items {
                if item.isCategory {
                    currentCategory = item.title
                    continue
                }
                
                // Ignorer les catégories dans le CSV
                let state = statesMap[item.id.uuidString] ?? 0
                let stateText: String
                switch state {
                case 3: stateText = "Non applicable"
                case 2: stateText = "Validé"
                case 1: stateText = "Partiel"
                default: stateText = "Non validé"
                }
                
                let evalDate = datesMap[item.id.uuidString]
                let evalDateStr = evalDate != nil ? DateFormatHelper.formatDate(evalDate!) : ""
                
                let note = notesMap[item.id.uuidString] ?? ""
                
                // Échapper les valeurs CSV
                let driverName = escapeCSV(driver.name)
                let category = escapeCSV(currentCategory)
                let question = escapeCSV(item.title)
                let noteEscaped = includeNotes ? escapeCSV(note) : ""
                
                // Créer la ligne CSV
                let row = [
                    driverName,
                    triennialStartStr,
                    triennialDue,
                    daysRemaining,
                    category,
                    question,
                    "\(state)",
                    stateText,
                    evalDateStr,
                    noteEscaped
                ]
                csvLines.append(row.joined(separator: ";"))
            }
        }
        
        // Joindre toutes les lignes avec des retours à la ligne
        let csvContent = csvLines.joined(separator: "\n")
        
        // Encoder en UTF-8 avec BOM pour Excel (recommandé pour les caractères accentués)
        guard let csvData = csvContent.data(using: .utf8) else {
            Logger.error("Impossible d'encoder le CSV en UTF-8", category: "ExportService")
            return nil
        }
        
        // Ajouter le BOM UTF-8 pour Excel
        var bomData = Data([0xEF, 0xBB, 0xBF])
        bomData.append(csvData)
        
        Logger.success("CSV exporté avec \(drivers.count) conducteur(s) et \(csvLines.count - 1) ligne(s)", category: "ExportService")
        return bomData
    }
}

