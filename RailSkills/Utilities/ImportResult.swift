//
//  ImportResult.swift
//  RailSkills
//
//  Résultat d'une tentative d'import de conducteur
//

import Foundation

/// Résultat d'une tentative d'import de conducteur
enum ImportResult {
    case newDriver(driver: DriverRecord, checklist: Checklist?, checklistMatch: Bool, exportDate: Date)
    case existingDriver(index: Int, importedDriver: DriverRecord, checklistMatch: Bool, exportDate: Date)
    case error(String)
}






