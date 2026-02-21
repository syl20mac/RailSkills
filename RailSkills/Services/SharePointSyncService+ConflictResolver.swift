//
//  SharePointSyncService+ConflictResolver.swift
//  RailSkills
//
//  Gestion des conflits de synchronisation SharePoint.
//  Isolé pour faciliter les tests et l'évolution indépendante de la logique de fusion.
//

import Foundation

// MARK: - Types de gestion des conflits

/// Stratégie de résolution des conflits de synchronisation
enum SyncConflictResolution {
    case useLocal    // Version iPad prioritaire
    case useRemote   // Version SharePoint prioritaire
    case merge       // Fusion intelligente (recommandé)
    case askUser     // Intervention manuelle
}

/// Représente un conflit entre version locale et distante
struct SyncConflict: Identifiable {
    let id = UUID()
    let driverName: String
    let driverId: UUID
    let localVersion: DriverRecord
    let remoteVersion: DriverRecord
    let localModifiedDate: Date
    let remoteModifiedDate: Date

    /// Détermine si la version locale est plus récente
    var localIsNewer: Bool {
        localModifiedDate > remoteModifiedDate
    }
}

// MARK: - Extension ConflictResolver

extension SharePointSyncService {

    /// Synchronise avec détection et résolution automatique des conflits.
    func syncWithConflictResolution(
        _ drivers: [DriverRecord],
        resolution: SyncConflictResolution = .merge
    ) async throws -> [SyncConflict] {
        guard isConfigured else { throw SharePointSyncError.notConfigured }

        isSyncing = true
        syncError = nil
        defer { isSyncing = false }

        do {
            let remoteDrivers = try await fetchDrivers()
            let conflicts = detectConflicts(local: drivers, remote: remoteDrivers)

            if conflicts.isEmpty {
                try await syncDrivers(drivers)
                Logger.success("Synchronisation sans conflits réussie", category: "SharePointSync")
                return []
            }

            switch resolution {
            case .useLocal:
                try await syncDrivers(drivers)
                Logger.info("Conflits résolus: version locale prioritaire", category: "SharePointSync")
                return []

            case .useRemote:
                Logger.info("Conflits résolus: version distante prioritaire", category: "SharePointSync")
                return []

            case .merge:
                let mergedDrivers = conflicts.map { conflict in
                    mergeDriverRecords(local: conflict.localVersion, remote: conflict.remoteVersion)
                }
                try await syncDrivers(mergedDrivers)
                Logger.success("Conflits résolus: fusion intelligente appliquée", category: "SharePointSync")
                return []

            case .askUser:
                Logger.info("\(conflicts.count) conflit(s) détecté(s), intervention manuelle requise", category: "SharePointSync")
                return conflicts
            }
        } catch {
            syncError = error.localizedDescription
            Logger.error("Erreur lors de la synchronisation avec gestion des conflits: \(error.localizedDescription)", category: "SharePointSync")
            throw error
        }
    }

    /// Détecte les conflits entre versions locales et distantes.
    func detectConflicts(local: [DriverRecord], remote: [DriverRecord]) -> [SyncConflict] {
        var conflicts: [SyncConflict] = []
        let remoteDict = Dictionary(uniqueKeysWithValues: remote.map { ($0.id, $0) })

        for localDriver in local {
            guard let remoteDriver = remoteDict[localDriver.id] else { continue }

            let localDate = localDriver.lastEvaluation ?? Date.distantPast
            let remoteDate = remoteDriver.lastEvaluation ?? Date.distantPast

            guard localDate != remoteDate else { continue }

            if hasSignificantDifferences(local: localDriver, remote: remoteDriver) {
                conflicts.append(SyncConflict(
                    driverName: localDriver.name,
                    driverId: localDriver.id,
                    localVersion: localDriver,
                    remoteVersion: remoteDriver,
                    localModifiedDate: localDate,
                    remoteModifiedDate: remoteDate
                ))
            }
        }

        return conflicts
    }

    /// Vérifie s'il y a des différences significatives entre deux versions.
    func hasSignificantDifferences(local: DriverRecord, remote: DriverRecord) -> Bool {
        local.checklistStates != remote.checklistStates
            || local.checklistNotes != remote.checklistNotes
            || local.triennialStart != remote.triennialStart
    }

    /// Fusionne intelligemment deux versions d'un conducteur.
    ///
    /// Règles de fusion :
    /// - Date d'évaluation : prendre la plus récente
    /// - Date triennale : conserver la plus ancienne (référence initiale)
    /// - États des questions : privilégier l'état le plus avancé (2 > 1 > 0, sauf 3 = N/A)
    /// - Notes : concaténer si différentes
    /// - Dates de suivi : prendre les plus récentes
    func mergeDriverRecords(local: DriverRecord, remote: DriverRecord) -> DriverRecord {
        var merged = local

        // 1. Date d'évaluation
        if let remoteEval = remote.lastEvaluation, let localEval = local.lastEvaluation {
            merged.lastEvaluation = max(localEval, remoteEval)
        } else {
            merged.lastEvaluation = remote.lastEvaluation ?? local.lastEvaluation
        }

        // 2. Date triennale
        if let remoteTriennal = remote.triennialStart, let localTriennal = local.triennialStart {
            merged.triennialStart = min(localTriennal, remoteTriennal)
        } else {
            merged.triennialStart = remote.triennialStart ?? local.triennialStart
        }

        // 3. États des questions
        merged.checklistStates = mergeChecklistStates(local: local.checklistStates, remote: remote.checklistStates)

        // 4. Notes
        merged.checklistNotes = mergeNotes(local: local.checklistNotes, remote: remote.checklistNotes)

        // 5. Dates de suivi
        merged.checklistDates = mergeDates(local: local.checklistDates, remote: remote.checklistDates)

        Logger.info("Fusion intelligente appliquée pour '\(merged.name)'", category: "SharePointSync")
        return merged
    }

    // MARK: - Helpers de fusion privés

    private func mergeChecklistStates(
        local: [String: [String: Int]],
        remote: [String: [String: Int]]
    ) -> [String: [String: Int]] {
        var merged = local

        for (checklistKey, remoteStates) in remote {
            if var localStates = merged[checklistKey] {
                for (questionId, remoteState) in remoteStates {
                    let localState = localStates[questionId] ?? 0
                    // N/A (3) : garder la valeur locale
                    if remoteState == 3 || localState == 3 { continue }
                    localStates[questionId] = max(localState, remoteState)
                }
                merged[checklistKey] = localStates
            } else {
                merged[checklistKey] = remoteStates
            }
        }

        return merged
    }

    private func mergeNotes(
        local: [String: [String: String]],
        remote: [String: [String: String]]
    ) -> [String: [String: String]] {
        var merged = local

        for (checklistKey, remoteNotes) in remote {
            if var localNotes = merged[checklistKey] {
                for (questionId, remoteNote) in remoteNotes {
                    if let localNote = localNotes[questionId] {
                        if localNote != remoteNote {
                            localNotes[questionId] = "\(localNote)\n\n--- Fusion ---\n\n\(remoteNote)"
                        }
                    } else {
                        localNotes[questionId] = remoteNote
                    }
                }
                merged[checklistKey] = localNotes
            } else {
                merged[checklistKey] = remoteNotes
            }
        }

        return merged
    }

    private func mergeDates(
        local: [String: [String: Date]],
        remote: [String: [String: Date]]
    ) -> [String: [String: Date]] {
        var merged = local

        for (checklistKey, remoteDates) in remote {
            if var localDates = merged[checklistKey] {
                for (questionId, remoteDate) in remoteDates {
                    if let localDate = localDates[questionId] {
                        localDates[questionId] = max(localDate, remoteDate)
                    } else {
                        localDates[questionId] = remoteDate
                    }
                }
                merged[checklistKey] = localDates
            } else {
                merged[checklistKey] = remoteDates
            }
        }

        return merged
    }
}
