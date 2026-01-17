//
//  DriverRecord.swift
//  RailSkills
//
//  Modèle de données pour un dossier de conducteur
//

import Foundation

/// Dossier d'un conducteur avec toutes ses informations de suivi
struct DriverRecord: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String                                    // nom du conducteur
    var firstName: String?                             // prénom du conducteur (optionnel pour rétrocompatibilité)
    var cpNumber: String?                              // numéro de certificat de capacité professionnelle (optionnel pour rétrocompatibilité)
    var lastEvaluation: Date?                          // date du dernier suivi
    var triennialStart: Date?                          // date de début de la période triennale
    var checklistStates: [String: [String: Int]]       // états des questions par checklist (0=non validé, 1=partiel, 2=validé, 3=non traité)
    var checklistNotes: [String: [String: String]]     // notes par question et par checklist
    var checklistDates: [String: [String: Date]]       // dates de suivi de chaque question par checklist
    var ownerSNCFId: String?                           // identifiant SNCF du CTT propriétaire (optionnel pour rétrocompatibilité)
    var additionalInfo: [String: String]?              // informations supplémentaires (DPX, Précisions, dates d'accompagnement, etc.)

    init(id: UUID = UUID(), name: String, firstName: String? = nil, cpNumber: String? = nil, lastEvaluation: Date? = nil, triennialStart: Date? = nil, checklistStates: [String: [String: Int]] = [:], checklistNotes: [String: [String: String]] = [:], checklistDates: [String: [String: Date]] = [:], ownerSNCFId: String? = nil, additionalInfo: [String: String]? = nil) {
        self.id = id
        self.name = name
        self.firstName = firstName
        self.cpNumber = cpNumber
        self.lastEvaluation = lastEvaluation
        self.triennialStart = triennialStart
        self.checklistStates = checklistStates
        self.checklistNotes = checklistNotes
        self.checklistDates = checklistDates
        self.ownerSNCFId = ownerSNCFId
        self.additionalInfo = additionalInfo
    }
    
    // MARK: - Propriétés calculées pour l'UI
    
    /// Nom complet du conducteur (nom + prénom)
    var fullName: String {
        if let firstName = firstName, !firstName.isEmpty {
            return "\(firstName) \(name)"
        }
        return name
    }
    
    /// Initiales du conducteur pour l'avatar
    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = String(components[0].prefix(1))
            let last = String(components[1].prefix(1))
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "??"
    }
}

