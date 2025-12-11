//
//  Logger.swift
//  RailSkills
//
//  Système de logging structuré pour remplacer les print() dispersés
//

import Foundation
import os.log

/// Niveaux de log disponibles
enum LogLevel: String {
    case debug = "🔍"
    case info = "ℹ️"
    case warning = "⚠️"
    case error = "❌"
    case success = "✅"
}

/// Système de logging centralisé pour l'application
struct Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.railskills"
    
    /// Logs une message avec un niveau spécifique
    /// - Parameters:
    ///   - level: Le niveau de log
    ///   - message: Le message à logger
    ///   - category: La catégorie du log (optionnel)
    ///   - file: Le fichier source (automatique)
    ///   - function: La fonction source (automatique)
    ///   - line: La ligne source (automatique)
    static func log(
        _ level: LogLevel,
        _ message: String,
        category: String = "General",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        
        #if DEBUG
        // En mode debug, afficher dans la console avec emoji
        print("\(level.rawValue) [\(category)] \(logMessage)")
        #else
        // En production, utiliser os.log pour de meilleures performances
        let osLog = OSLog(subsystem: subsystem, category: category)
        let osLogType: OSLogType
        
        switch level {
        case .debug:
            osLogType = .debug
        case .info, .success:
            osLogType = .info
        case .warning:
            osLogType = .default
        case .error:
            osLogType = .error
        }
        
        os_log("%{public}@", log: osLog, type: osLogType, logMessage)
        #endif
    }
    
    // Méthodes de convenance pour chaque niveau
    static func debug(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message, category: category, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message, category: category, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message, category: category, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message, category: category, file: file, function: function, line: line)
    }
    
    static func success(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(.success, message, category: category, file: file, function: function, line: line)
    }
}





