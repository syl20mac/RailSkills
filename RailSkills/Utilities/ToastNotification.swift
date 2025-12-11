//
//  ToastNotification.swift
//  RailSkills
//
//  Système de notifications toast pour le feedback utilisateur
//

import SwiftUI
import Combine

/// Type de notification
enum ToastType {
    case success
    case error
    case warning
    case info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

/// Gestionnaire de notifications toast
@MainActor
class ToastNotificationManager: ObservableObject {
    @Published var currentToast: ToastMessage?
    
    /// Affiche une notification toast
    /// - Parameters:
    ///   - message: Le message à afficher
    ///   - type: Le type de notification
    ///   - duration: La durée d'affichage en secondes (par défaut 3 secondes)
    func show(_ message: String, type: ToastType = .info, duration: TimeInterval = 3.0) {
        currentToast = ToastMessage(message: message, type: type)
        
        // Masquer automatiquement après la durée spécifiée
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if currentToast?.message == message {
                await MainActor.run {
                    currentToast = nil
                }
            }
        }
    }
    
    /// Masque la notification actuelle
    func dismiss() {
        currentToast = nil
    }
}

/// Structure représentant un message toast
struct ToastMessage: Identifiable {
    let id = UUID()
    let message: String
    let type: ToastType
}

/// Modificateur de vue pour afficher les notifications toast
struct ToastNotificationModifier: ViewModifier {
    @ObservedObject var manager: ToastNotificationManager
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = manager.currentToast {
                    ToastView(toast: toast, onDismiss: {
                        manager.dismiss()
                    })
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1000)
                }
            }
    }
}

/// Vue représentant une notification toast
struct ToastView: View {
    let toast: ToastMessage
    let onDismiss: () -> Void
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .foregroundStyle(toast.type.color)
                .font(.title3)
            
            Text(toast.message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(toast.type == .success ? "Succès" : toast.type == .error ? "Erreur" : toast.type == .warning ? "Avertissement" : "Information"): \(toast.message)")
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}

extension View {
    /// Ajoute le support des notifications toast à une vue
    func toastNotifications(manager: ToastNotificationManager) -> some View {
        modifier(ToastNotificationModifier(manager: manager))
    }
}

