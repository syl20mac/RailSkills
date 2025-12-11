//
//  ShareableDriverRecord.swift
//  RailSkills
//
//  Modèle de données pour le partage d'un conducteur
//

import Foundation

/// Structure pour partager un conducteur avec toutes ses données associées
struct ShareableDriverRecord: Codable {
    let driver: DriverRecord         // données du conducteur
    let checklist: Checklist?        // checklist associée
    let exportDate: Date             // date d'export
    let exporterInfo: String         // informations sur l'application exportatrice
    let version: String              // version du format d'export
    
    init(driver: DriverRecord, checklist: Checklist?, exportDate: Date, exporterInfo: String, version: String = "1.0") {
        self.driver = driver
        self.checklist = checklist
        self.exportDate = exportDate
        self.exporterInfo = exporterInfo
        self.version = version
    }
}

/// Structure pour partager plusieurs conducteurs (transfert à un autre CTT)
struct ShareableDriversRecord: Codable {
    let drivers: [ShareableDriverRecord]  // liste des conducteurs
    let exportDate: Date                  // date d'export
    let exporterInfo: String              // informations sur l'application exportatrice
    let version: String                   // version du format d'export
    let count: Int                        // nombre de conducteurs
    
    init(drivers: [ShareableDriverRecord], exportDate: Date, exporterInfo: String, version: String = "1.0") {
        self.drivers = drivers
        self.exportDate = exportDate
        self.exporterInfo = exporterInfo
        self.version = version
        self.count = drivers.count
    }
}

