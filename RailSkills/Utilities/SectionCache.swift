//
//  SectionCache.swift
//  RailSkills
//
//  Cache intelligent thread-safe pour les sections de checklist
//  Utilise un Actor pour garantir la sécurité des accès concurrents
//

import Foundation

/// Cache thread-safe pour les sections de checklist
actor SectionCache {
    /// Instance partagée du cache
    static let shared = SectionCache()
    
    /// Durée de vie du cache (5 minutes par défaut)
    private let cacheLifetime: TimeInterval
    
    /// Dictionnaire de cache
    private var cache: [String: CachedSections] = [:]
    
    /// Structure représentant des sections mises en cache avec métadonnées
    struct CachedSections {
        let sections: [ChecklistSection]
        let timestamp: Date
        let searchText: String
        let filterState: Int // Pour ChecklistFilter si besoin
        let driverId: UUID
        let checklistTitle: String
        
        /// Vérifie si le cache est encore valide
        func isValid(lifetime: TimeInterval) -> Bool {
            Date().timeIntervalSince(timestamp) < lifetime
        }
        
        /// Vérifie si les paramètres correspondent
        func matches(searchText: String, filterState: Int, driverId: UUID, checklistTitle: String) -> Bool {
            return self.searchText == searchText &&
                   self.filterState == filterState &&
                   self.driverId == driverId &&
                   self.checklistTitle == checklistTitle
        }
    }
    
    /// Initialise le cache avec une durée de vie personnalisable
    /// - Parameter cacheLifetime: Durée de vie en secondes (défaut: 300 = 5 minutes)
    init(cacheLifetime: TimeInterval = 300) {
        self.cacheLifetime = cacheLifetime
        // Logger de manière asynchrone car l'initialiseur n'est pas isolé
        Task { @MainActor in
            Logger.info("SectionCache initialisé avec durée de vie de \(cacheLifetime)s", category: "SectionCache")
        }
    }
    
    /// Récupère les sections depuis le cache si disponibles et valides
    /// - Parameters:
    ///   - key: Clé d'identification unique
    ///   - searchText: Texte de recherche
    ///   - filterState: État du filtre
    ///   - driverId: ID du conducteur
    ///   - checklistTitle: Titre de la checklist
    /// - Returns: Les sections en cache ou nil si invalide/inexistant
    func get(
        for key: String,
        searchText: String,
        filterState: Int,
        driverId: UUID,
        checklistTitle: String
    ) -> [ChecklistSection]? {
        guard let cached = cache[key],
              cached.isValid(lifetime: cacheLifetime),
              cached.matches(
                searchText: searchText,
                filterState: filterState,
                driverId: driverId,
                checklistTitle: checklistTitle
              ) else {
            return nil
        }
        
        // Logger de manière asynchrone car on est dans un contexte d'actor
        Task { @MainActor in
            Logger.debug("Cache HIT pour clé: \(key)", category: "SectionCache")
        }
        return cached.sections
    }
    
    /// Met en cache des sections avec leurs métadonnées
    /// - Parameters:
    ///   - sections: Sections à mettre en cache
    ///   - key: Clé d'identification unique
    ///   - searchText: Texte de recherche
    ///   - filterState: État du filtre
    ///   - driverId: ID du conducteur
    ///   - checklistTitle: Titre de la checklist
    func set(
        _ sections: [ChecklistSection],
        for key: String,
        searchText: String,
        filterState: Int,
        driverId: UUID,
        checklistTitle: String
    ) {
        let cached = CachedSections(
            sections: sections,
            timestamp: Date(),
            searchText: searchText,
            filterState: filterState,
            driverId: driverId,
            checklistTitle: checklistTitle
        )
        
        cache[key] = cached
        // Logger de manière asynchrone car on est dans un contexte d'actor
        Task { @MainActor in
            Logger.debug("Cache SET pour clé: \(key) (\(sections.count) sections)", category: "SectionCache")
        }
        
        // Nettoyer les entrées expirées si le cache devient trop grand
        if cache.count > 50 {
            cleanExpired()
        }
    }
    
    /// Invalide toutes les entrées du cache
    func invalidateAll() {
        let count = cache.count
        cache.removeAll()
        // Logger de manière asynchrone car on est dans un contexte d'actor
        Task { @MainActor in
            Logger.info("Cache invalidé (\(count) entrée(s) supprimée(s))", category: "SectionCache")
        }
    }
    
    /// Invalide le cache pour une clé spécifique
    /// - Parameter key: Clé à invalider
    func invalidate(key: String) {
        cache.removeValue(forKey: key)
        // Logger de manière asynchrone car on est dans un contexte d'actor
        Task { @MainActor in
            Logger.debug("Cache invalidé pour clé: \(key)", category: "SectionCache")
        }
    }
    
    /// Nettoie les entrées expirées du cache
    func cleanExpired() {
        let beforeCount = cache.count
        cache = cache.filter { _, cached in
            cached.isValid(lifetime: cacheLifetime)
        }
        let removedCount = beforeCount - cache.count
        
        if removedCount > 0 {
            // Logger de manière asynchrone car on est dans un contexte d'actor
            Task { @MainActor in
                Logger.debug("Cache nettoyé: \(removedCount) entrée(s) expirée(s) supprimée(s)", category: "SectionCache")
            }
        }
    }
    
    /// Retourne des statistiques sur le cache
    func getStats() -> CacheStats {
        CacheStats(
            entryCount: cache.count,
            totalSections: cache.values.reduce(0) { $0 + $1.sections.count },
            oldestEntry: cache.values.map { $0.timestamp }.min(),
            newestEntry: cache.values.map { $0.timestamp }.max()
        )
    }
    
    /// Statistiques du cache
    struct CacheStats {
        let entryCount: Int
        let totalSections: Int
        let oldestEntry: Date?
        let newestEntry: Date?
        
        var description: String {
            """
            Cache Stats:
            - Entrées: \(entryCount)
            - Sections totales: \(totalSections)
            - Entrée la plus ancienne: \(oldestEntry?.description ?? "N/A")
            - Entrée la plus récente: \(newestEntry?.description ?? "N/A")
            """
        }
    }
}

// MARK: - Extension pour générer des clés de cache

extension SectionCache {
    /// Génère une clé de cache basée sur les paramètres
    static func cacheKey(driverId: UUID, checklistTitle: String) -> String {
        return "\(driverId.uuidString)_\(checklistTitle)"
    }
}

