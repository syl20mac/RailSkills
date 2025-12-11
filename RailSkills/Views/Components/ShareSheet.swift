//
//  ShareSheet.swift
//  RailSkills
//
//  Wrapper UIViewRepresentable pour présenter UIActivityViewController
//

import SwiftUI
import UIKit

// MARK: - Share Sheet Wrapper

/// Wrapper UIViewRepresentable pour présenter UIActivityViewController sans warnings
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> ShareSheetController {
        return ShareSheetController()
    }
    
    func updateUIViewController(_ uiViewController: ShareSheetController, context: Context) {
        if isPresented && uiViewController.presentedViewController == nil {
            // Créer et présenter le UIActivityViewController
            let activityVC = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: applicationActivities
            )
            
            // Configurer pour iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = uiViewController.view
                popover.sourceRect = CGRect(
                    x: uiViewController.view.bounds.midX,
                    y: uiViewController.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }
            
            // Callback quand le sheet est fermé
            activityVC.completionWithItemsHandler = { _, completed, _, _ in
                DispatchQueue.main.async {
                    isPresented = false
                }
            }
            
            // Présenter le sheet
            DispatchQueue.main.async {
                uiViewController.present(activityVC, animated: true)
            }
        }
    }
}

/// Contrôleur de vue personnalisé pour gérer la présentation du share sheet
class ShareSheetController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
    }
}

/// Modifier pour présenter un share sheet
struct ShareSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?
    
    func body(content: Content) -> some View {
        content
            .background(
                ShareSheet(
                    activityItems: activityItems,
                    applicationActivities: applicationActivities,
                    isPresented: $isPresented
                )
                .frame(width: 0, height: 0)
                .opacity(0)
            )
    }
}

extension View {
    /// Présente un share sheet avec les éléments spécifiés
    func shareSheet(isPresented: Binding<Bool>, activityItems: [Any], applicationActivities: [UIActivity]? = nil) -> some View {
        self.modifier(ShareSheetModifier(
            isPresented: isPresented,
            activityItems: activityItems,
            applicationActivities: applicationActivities
        ))
    }
}





