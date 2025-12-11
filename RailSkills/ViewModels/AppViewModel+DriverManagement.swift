//
//  AppViewModel+DriverManagement.swift
//  RailSkills
//
//  Extension pour la gestion des conducteurs
//

import Foundation
import SwiftUI

// MARK: - Gestion des conducteurs
extension AppViewModel {
    
    /// Supprime des conducteurs aux indices spécifiés (localement et sur SharePoint)
    /// - Parameter offsets: Les indices des conducteurs à supprimer
    func deleteDrivers(at offsets: IndexSet) {
        let deletedDrivers = offsets.map { store.drivers[$0] }
        let deletedDriverIds = Set(deletedDrivers.map { $0.id })
        
        // Haptic feedback pour l'action destructive
        HapticFeedbackManager.shared.destructiveAction()
        
        // Logger les suppressions dans l'audit log
        for driver in deletedDrivers {
            AuditLogger.shared.log(
                action: .driverDeleted,
                target: driver.name,
                details: ["driver_id": driver.id.uuidString]
            )
        }
        
        // Supprimer localement d'abord (pour une réactivité UI immédiate)
        // avec la synchronisation désactivée pour éviter qu'elle recrée les fichiers
        store.withSyncDisabled {
            store.drivers.remove(atOffsets: offsets)
        }
        
        // Supprimer sur SharePoint en arrière-plan
        Task {
            await deleteDriversOnSharePoint(driverIds: Array(deletedDriverIds))
        }
    }
    
    /// Supprime des conducteurs par leurs IDs (localement et sur SharePoint)
    /// - Parameter driverIds: Les IDs des conducteurs à supprimer
    func deleteDrivers(byIds driverIds: Set<UUID>) {
        let deletedDrivers = store.drivers.filter { driverIds.contains($0.id) }
        let driverIdsArray = Array(driverIds)
        
        // Haptic feedback pour l'action destructive
        HapticFeedbackManager.shared.destructiveAction()
        
        // Logger les suppressions dans l'audit log
        for driver in deletedDrivers {
            AuditLogger.shared.log(
                action: .driverDeleted,
                target: driver.name,
                details: ["driver_id": driver.id.uuidString]
            )
        }
        
        // Supprimer localement d'abord (pour une réactivité UI immédiate)
        // avec la synchronisation désactivée pour éviter qu'elle recrée les fichiers
        store.withSyncDisabled {
            store.drivers.removeAll { driverIds.contains($0.id) }
        }
        
        // Supprimer sur SharePoint en arrière-plan
        Task {
            await deleteDriversOnSharePoint(driverIds: driverIdsArray)
        }
    }
    
    /// Supprime des conducteurs sur SharePoint (méthode interne)
    /// - Parameter driverIds: Les IDs des conducteurs à supprimer
    @MainActor
    private func deleteDriversOnSharePoint(driverIds: [UUID]) async {
        guard !driverIds.isEmpty else { return }
        
        // Vérifier si SharePoint est configuré
        guard SharePointSyncService.shared.isConfigured else {
            Logger.info("SharePoint non configuré, suppression locale uniquement pour \(driverIds.count) conducteur(s)", category: "AppViewModel")
            return
        }
        
        Logger.info("Suppression de \(driverIds.count) conducteur(s) sur SharePoint...", category: "AppViewModel")
        
        do {
            try await SharePointSyncService.shared.deleteDrivers(driverIds: driverIds)
            Logger.success("✅ \(driverIds.count) conducteur(s) supprimé(s) sur SharePoint", category: "AppViewModel")
        } catch {
            Logger.error("❌ Erreur lors de la suppression sur SharePoint: \(error.localizedDescription)", category: "AppViewModel")
            // Ne pas interrompre l'utilisateur, la suppression locale a déjà été effectuée
        }
    }

    /// Calcule la date d'échéance (3 ans après la date de début)
    func nextDueDate(from date: Date?) -> Date? {
        guard let date else { return nil }
        return Calendar.current.date(byAdding: .year, value: AppConstants.Date.triennialYears, to: date)
    }
}

