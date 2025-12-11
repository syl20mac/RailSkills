//
//  CircularProgressView.swift
//  RailSkills
//
//  Composant de progression circulaire pour afficher les pourcentages
//

import SwiftUI

/// Vue de progression circulaire avec dégradé moderne
struct CircularProgressView: View {
    let progress: Double // 0.0 à 1.0
    let lineWidth: CGFloat
    let size: CGFloat
    
    init(progress: Double, lineWidth: CGFloat = 8, size: CGFloat = 60) {
        self.progress = max(0, min(1, progress))
        self.lineWidth = lineWidth
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: lineWidth)
            
            // Progress circle avec dégradé
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [
                            SNCFColors.ceruleen,
                            SNCFColors.menthe
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: progress)
            
            // Percentage text
            Text("\(Int(progress * 100))%")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(.primary)
        }
        .frame(width: size, height: size)
    }
}





