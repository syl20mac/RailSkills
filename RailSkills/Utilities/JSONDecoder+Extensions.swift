//
//  JSONDecoder+Extensions.swift
//  RailSkills
//
//  Extension pour offrir une stratégie de décodage de dates flexible et robuste.
//  Gère ISO8601, formats courts, formats français, etc.
//

import Foundation

extension JSONDecoder {
    /// Crée un décodeur avec une stratégie de gestion des dates flexible
    /// Supporte: ISO8601 (complet/partiel), YYYY-MM-DD, DD/MM/YYYY
    nonisolated static var flexible: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // 1. ISO8601 complet (avec internet datetime et fractions)
            // ex: 2023-09-21T14:30:00.123Z
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            // 2. ISO8601 standard (sans fractions)
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            // 3. Format date simple (YYYY-MM-DD)
            // ex: 2023-09-21
            let dateOnlyFormatter = DateFormatter()
            dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
            dateOnlyFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = dateOnlyFormatter.date(from: dateString) {
                // Détection erreur année 1900 (Excel default)
                let calendar = Calendar.current
                let year = calendar.component(.year, from: date)
                if year == 1900 {
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Date invalide (année 1900): \(dateString)"
                    )
                }
                return date
            }
            
            // 4. Format français (DD/MM/YYYY)
            let frenchDateFormatter = DateFormatter()
            frenchDateFormatter.dateFormat = "dd/MM/yyyy"
            frenchDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            frenchDateFormatter.locale = Locale(identifier: "fr_FR")
            if let date = frenchDateFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Format de date non supporté: \(dateString)"
            )
        }
        return decoder
    }
}
