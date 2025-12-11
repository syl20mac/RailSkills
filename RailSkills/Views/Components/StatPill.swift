//
//  StatPill.swift
//  RailSkills
//
//  Composant de statistique en forme de pilule
//

import SwiftUI

/// Composant affichant une statistique avec icône et valeur
struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(.primary)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        StatPill(
            icon: "checkmark.circle.fill",
            value: "24",
            label: "Validés",
            color: SNCFColors.menthe
        )
        
        StatPill(
            icon: "circle.fill",
            value: "6",
            label: "Restants",
            color: SNCFColors.bleuHorizon
        )
    }
    .padding()
}


