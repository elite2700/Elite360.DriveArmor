// GamificationView.swift
// Elite360.DriveArmor
//
// Child view showing driving badges, streaks, and points.

import SwiftUI

struct GamificationView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var service = GamificationService()
    @State private var profile: GamificationProfile?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Stats Header
                if let profile {
                    statsHeader(profile)
                }

                // MARK: - Streak
                if let profile {
                    streakCard(profile)
                }

                // MARK: - Badges
                badgesGrid
            }
            .padding()
        }
        .navigationTitle("My Driving")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadProfile()
        }
    }

    // MARK: - Stats

    private func statsHeader(_ p: GamificationProfile) -> some View {
        HStack(spacing: 0) {
            StatBubble(value: "\(p.points)", label: "Points", icon: "star.fill", color: .yellow)
            StatBubble(value: "\(p.totalDrives)", label: "Drives", icon: "car.fill", color: .blue)
            StatBubble(value: "\(p.safeDrives)", label: "Safe", icon: "checkmark.shield.fill", color: .green)
            StatBubble(value: p.totalDrives > 0 ? "\(Int(Double(p.safeDrives) / Double(p.totalDrives) * 100))%" : "–",
                       label: "Rate", icon: "percent", color: .orange)
        }
    }

    // MARK: - Streak

    private func streakCard(_ p: GamificationProfile) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
                Text("\(p.currentStreak)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text("day streak")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            if p.longestStreak > p.currentStreak {
                Text("Best: \(p.longestStreak) days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.08))
        )
    }

    // MARK: - Badges Grid

    private var badgesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Badges")
                .font(.title2.bold())

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(BadgeType.allCases, id: \.self) { type in
                    let earned = profile?.badges.first(where: { $0.type == type })
                    BadgeCell(type: type, earned: earned != nil, earnedDate: earned?.earnedAt)
                }
            }
        }
    }

    // MARK: - Load

    private func loadProfile() async {
        guard let uid = appState.userId,
              let fId = appState.familyId else { return }
        profile = try? await service.fetchProfile(familyId: fId, childId: uid)
    }
}

// MARK: - Stat Bubble

private struct StatBubble: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

// MARK: - Badge Cell

private struct BadgeCell: View {
    let type: BadgeType
    let earned: Bool
    let earnedDate: Date?

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(earned ? type.color.opacity(0.15) : Color.gray.opacity(0.08))
                    .frame(width: 64, height: 64)
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundStyle(earned ? type.color : .gray.opacity(0.35))
            }
            Text(type.displayName)
                .font(.caption2.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(earned ? .primary : .secondary)

            if let date = earnedDate {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - BadgeType helpers

extension BadgeType {
    var displayName: String {
        switch self {
        case .firstDrive:        return "First Drive"
        case .safeWeek:          return "Safe Week"
        case .safeMonth:         return "Safe Month"
        case .noDistractions10:  return "No Distractions 10"
        case .speedCompliant50:  return "Speed Star 50"
        case .safeModeChampion:  return "Safe Mode Champ"
        case .streakMaster:      return "Streak Master"
        }
    }

    var icon: String {
        switch self {
        case .firstDrive:        return "car.fill"
        case .safeWeek:          return "calendar.badge.checkmark"
        case .safeMonth:         return "moon.stars.fill"
        case .noDistractions10:  return "eye.slash.fill"
        case .speedCompliant50:  return "speedometer"
        case .safeModeChampion:  return "shield.checkered"
        case .streakMaster:      return "flame.fill"
        }
    }

    var color: Color {
        switch self {
        case .firstDrive:        return .blue
        case .safeWeek:          return .green
        case .safeMonth:         return .purple
        case .noDistractions10:  return .indigo
        case .speedCompliant50:  return .orange
        case .safeModeChampion:  return .red
        case .streakMaster:      return .yellow
        }
    }
}

#Preview {
    NavigationStack {
        GamificationView()
            .environmentObject(AppState())
    }
}
