//
//  NavigationRoute.swift
//  RailSkills
//
//  Routes de navigation typées pour iOS 18+ avec NavigationStack
//

import Foundation

/// Routes de navigation typées et sécurisées pour iOS 18+
/// Permet une navigation type-safe avec NavigationStack
enum NavigationRoute: Hashable {
    case driver(UUID)
    case checklist(UUID)
    case settings
    case report(UUID)
    case sharing
    case dashboard
    
    /// Hashable implementation pour NavigationStack
    func hash(into hasher: inout Hasher) {
        switch self {
        case .driver(let id):
            hasher.combine("driver")
            hasher.combine(id)
        case .checklist(let id):
            hasher.combine("checklist")
            hasher.combine(id)
        case .settings:
            hasher.combine("settings")
        case .report(let id):
            hasher.combine("report")
            hasher.combine(id)
        case .sharing:
            hasher.combine("sharing")
        case .dashboard:
            hasher.combine("dashboard")
        }
    }
    
    /// Égalité pour Hashable
    static func == (lhs: NavigationRoute, rhs: NavigationRoute) -> Bool {
        switch (lhs, rhs) {
        case (.driver(let lhsId), .driver(let rhsId)):
            return lhsId == rhsId
        case (.checklist(let lhsId), .checklist(let rhsId)):
            return lhsId == rhsId
        case (.settings, .settings):
            return true
        case (.report(let lhsId), .report(let rhsId)):
            return lhsId == rhsId
        case (.sharing, .sharing):
            return true
        case (.dashboard, .dashboard):
            return true
        default:
            return false
        }
    }
}









