// ChildStatusCard.swift
// Elite360.DriveArmor
//
// Card displayed on the parent dashboard showing one child's real-time status
// with toggle and report actions.

import SwiftUI

struct ChildStatusCard: View {
    let child: UserModel
    let status: DeviceStatus?
    let onToggleSafeMode: (Bool) -> Void
    let onViewReports: () -> Void

    @EnvironmentObject var appState: AppState

    private var isDriving: Bool { status?.drivingDetected ?? false }
    private var safeModeActive: Bool { status?.safeModeActive ?? false }
    private var speed: Double { status?.currentSpeed ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: - Header
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                    .foregroundStyle(.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(child.displayName)
                        .font(.headline)
                    Text(isDriving ? "Currently Driving" : "Not Driving")
                        .font(.caption)
                        .foregroundStyle(isDriving ? .orange : .secondary)
                }

                Spacer()

                // Live indicator dot
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
            }

            // MARK: - Stats Row
            if let status = status {
                HStack(spacing: 24) {
                    StatItem(label: "Speed", value: String(format: "%.0f mph", status.currentSpeed),
                             icon: "speedometer")
                    StatItem(label: "Safe Mode", value: safeModeActive ? "ON" : "OFF",
                             icon: safeModeActive ? "lock.shield.fill" : "lock.open.fill")
                    if let battery = status.batteryLevel {
                        StatItem(label: "Battery", value: String(format: "%.0f%%", battery * 100),
                                 icon: "battery.75percent")
                    }
                }
            } else {
                Text("Waiting for device data…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // MARK: - Actions
            HStack(spacing: 12) {
                Button {
                    onToggleSafeMode(!safeModeActive)
                } label: {
                    Label(
                        safeModeActive ? "Disable Safe Mode" : "Enable Safe Mode",
                        systemImage: safeModeActive ? "lock.open.fill" : "lock.shield.fill"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(safeModeActive ? .gray : .orange)

                NavigationLink {
                    ReportsView(childId: child.uid, childName: child.displayName)
                } label: {
                    Label("Reports", systemImage: "chart.bar.fill")
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private var statusColor: Color {
        if isDriving && safeModeActive { return .green }
        if isDriving { return .orange }
        return .gray
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
