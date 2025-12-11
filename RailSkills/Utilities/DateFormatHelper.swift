//
//  DateFormatHelper.swift
//  RailSkills
//
//  Utilitaire pour formater les dates de manière cohérente
//

import Foundation

/// Utilitaire pour formater les dates de manière cohérente
enum DateFormatHelper {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    static func formatDate(_ date: Date) -> String {
        formatter.string(from: date)
    }
    
    /// Formate une date avec un style personnalisé
    static func formatDate(_ date: Date, style: DateFormatter.Style) -> String {
        let customFormatter = DateFormatter()
        customFormatter.dateStyle = style
        return customFormatter.string(from: date)
    }
}






