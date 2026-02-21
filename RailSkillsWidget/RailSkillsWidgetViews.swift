//
//  RailSkillsWidgetViews.swift
//  RailSkillsWidget
//
//  Vues pour les 3 tailles de widget :
//  - Small  : progression globale + conducteur le plus récent
//  - Medium : top 2 conducteurs avec barres de progression
//  - Large  : top 4 conducteurs avec les 3 checklists
//

import SwiftUI
import WidgetKit

// MARK: - Couleurs (copie locale pour ne pas dépendre du module principal)

private enum WColor {
    static let ceruleen    = Color(red: 0/255,   green: 132/255, blue: 212/255)
    static let menthe      = Color(red: 0/255,   green: 179/255, blue: 136/255)
    static let corail      = Color(red: 242/255, green: 130/255, blue: 127/255)
    static let safran      = Color(red: 218/255, green: 170/255, blue: 0/255)
    static let bleuMarine  = Color(red: 0/255,   green: 32/255,  blue: 91/255)
}

// MARK: - Helpers

private func progressColor(_ value: Double) -> Color {
    if value >= 0.8 { return WColor.menthe }
    if value >= 0.5 { return WColor.safran }
    return WColor.corail
}

private func formatDate(_ date: Date?) -> String {
    guard let date else { return "—" }
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.locale = Locale(identifier: "fr_FR")
    return formatter.string(from: date)
}

// MARK: - Avatar

private struct AvatarView: View {
    let initials: String
    let size: CGFloat
    var color: Color = WColor.ceruleen

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
            Text(initials)
                .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Barre de progression horizontale

private struct ProgressBarView: View {
    let label: String
    let value: Double
    let barHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(progressColor(value))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: barHeight)
                    Capsule()
                        .fill(progressColor(value))
                        .frame(width: geo.size.width * value, height: barHeight)
                }
            }
            .frame(height: barHeight)
        }
    }
}

// MARK: - Arc de progression circulaire

private struct ArcProgressView: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor(progress),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Vue Small

struct SmallWidgetView: View {
    let entry: RailSkillsEntry
    @Environment(\.widgetFamily) private var family

    private var driver: WidgetDriverSummary? {
        entry.data.mostRecentDriver ?? entry.data.drivers.first
    }
    private var progress: Double {
        driver?.globalProgress ?? entry.data.averageGlobalProgress
    }

    var body: some View {
        ZStack {
            // Fond dégradé discret
            LinearGradient(
                colors: [WColor.bleuMarine.opacity(0.05), WColor.ceruleen.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 6) {
                // En-tête
                HStack(spacing: 4) {
                    Image(systemName: "train.side.front.car")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(WColor.ceruleen)
                    Text("RailSkills")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(WColor.ceruleen)
                }

                Spacer()

                // Arc de progression
                ArcProgressView(progress: progress, size: 64, lineWidth: 7)
                    .frame(maxWidth: .infinity, alignment: .center)

                Spacer()

                // Nom du conducteur
                if let driver {
                    Text(driver.displayName)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text("Dernière eval. \(formatDate(driver.lastEvaluation))")
                        .font(.system(size: 9, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(entry.data.totalDriverCount) conducteur(s)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Vue Medium

struct MediumWidgetView: View {
    let entry: RailSkillsEntry

    private var topDrivers: [WidgetDriverSummary] {
        Array(entry.data.drivers.prefix(2))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [WColor.bleuMarine.opacity(0.05), WColor.ceruleen.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // En-tête
                HStack {
                    Image(systemName: "train.side.front.car")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WColor.ceruleen)
                    Text("RailSkills")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(WColor.ceruleen)
                    Spacer()
                    Text("\(entry.data.totalDriverCount) conducteurs")
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)

                Divider().opacity(0.4)

                if topDrivers.isEmpty {
                    Spacer()
                    Text("Aucun conducteur")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    VStack(spacing: 6) {
                        ForEach(topDrivers, id: \.id) { driver in
                            DriverMediumRow(driver: driver)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }

                Spacer(minLength: 0)

                // Pied de page
                HStack {
                    Spacer()
                    Text("Mis à jour \(formatDate(entry.data.lastUpdate))")
                        .font(.system(size: 8, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }
        }
    }
}

private struct DriverMediumRow: View {
    let driver: WidgetDriverSummary

    var body: some View {
        HStack(spacing: 10) {
            AvatarView(initials: driver.initials, size: 32, color: progressColor(driver.globalProgress))

            VStack(alignment: .leading, spacing: 3) {
                Text(driver.displayName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    MiniProgressPill(label: "S", value: driver.progressTriennale)
                    MiniProgressPill(label: "VP", value: driver.progressVP)
                    MiniProgressPill(label: "TE", value: driver.progressTE)
                }
            }

            Spacer()

            Text("\(Int(driver.globalProgress * 100))%")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(progressColor(driver.globalProgress))
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.06))
        )
    }
}

private struct MiniProgressPill: View {
    let label: String
    let value: Double

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Text("\(Int(value * 100))%")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(progressColor(value))
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(progressColor(value).opacity(0.12))
        )
    }
}

// MARK: - Vue Large

struct LargeWidgetView: View {
    let entry: RailSkillsEntry

    private var topDrivers: [WidgetDriverSummary] {
        Array(entry.data.drivers.prefix(4))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [WColor.bleuMarine.opacity(0.05), WColor.ceruleen.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // En-tête
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "train.side.front.car")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(WColor.ceruleen)
                        Text("RailSkills")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(WColor.ceruleen)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(Int(entry.data.averageGlobalProgress * 100))%")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(progressColor(entry.data.averageGlobalProgress))
                        Text("moy. globale")
                            .font(.system(size: 9, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

                Divider().opacity(0.4)

                if topDrivers.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(WColor.ceruleen.opacity(0.4))
                        Text("Ouvrez RailSkills pour\najouter des conducteurs")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    VStack(spacing: 8) {
                        ForEach(topDrivers, id: \.id) { driver in
                            DriverLargeRow(driver: driver)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                Spacer(minLength: 0)

                // Pied de page
                HStack {
                    if entry.data.totalDriverCount > 4 {
                        Text("+ \(entry.data.totalDriverCount - 4) autre(s) conducteur(s)")
                            .font(.system(size: 9, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Text("Mis à jour \(formatDate(entry.data.lastUpdate))")
                        .font(.system(size: 8, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
        }
    }
}

private struct DriverLargeRow: View {
    let driver: WidgetDriverSummary

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(initials: driver.initials, size: 38, color: progressColor(driver.globalProgress))

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(driver.displayName)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        if let cp = driver.cpNumber, !cp.isEmpty {
                            Text(cp)
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Spacer()
                    Text("\(Int(driver.globalProgress * 100))%")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(progressColor(driver.globalProgress))
                }

                VStack(spacing: 3) {
                    ProgressBarView(label: "Suivi",  value: driver.progressTriennale, barHeight: 4)
                    ProgressBarView(label: "VP",     value: driver.progressVP,        barHeight: 4)
                    ProgressBarView(label: "TE",     value: driver.progressTE,        barHeight: 4)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.06))
        )
    }
}
