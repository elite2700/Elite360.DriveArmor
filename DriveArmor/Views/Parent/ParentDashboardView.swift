// ParentDashboardView.swift
// Elite360.DriveArmor
//
// Main parent screen showing child device statuses, quick actions,
// and navigation to reports/settings.

import SwiftUI

struct ParentDashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ParentDashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dashboard")
                            .font(.largeTitle.bold())
                        Text(appState.currentFamily?.name ?? "Family")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                    }
                }
                .padding(.horizontal)

                // MARK: - Pairing Code Banner
                if let code = appState.currentFamily?.pairingCode {
                    PairingCodeBanner(code: code)
                }

                // MARK: - Quick Actions Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    QuickActionCard(icon: "mappin.and.ellipse", title: "Geofences", color: .blue) {
                        NavigationLink(destination: GeofenceListView()) {
                            EmptyView()
                        }
                    }
                    QuickActionCard(icon: "clock.badge.checkmark", title: "Schedules", color: .purple) {
                        NavigationLink(destination: ScheduleListView()) {
                            EmptyView()
                        }
                    }
                    QuickActionCard(icon: "speedometer", title: "Speed Alerts", color: .orange) {
                        NavigationLink(destination: SpeedThresholdView()) {
                            EmptyView()
                        }
                    }
                    QuickActionCard(icon: "hand.raised.fill", title: "Override Requests", color: .red) {
                        NavigationLink(destination: OverrideRequestsView()) {
                            EmptyView()
                        }
                    }
                    QuickActionCard(icon: "doc.badge.gearshape", title: "Rule Changes", color: .teal) {
                        NavigationLink(destination: RuleChangeRequestView()) {
                            EmptyView()
                        }
                    }
                    QuickActionCard(icon: "qrcode", title: "QR Pairing", color: .indigo) {
                        NavigationLink(destination: QRCodePairingView(pairingCode: appState.currentFamily?.pairingCode ?? "")) {
                            EmptyView()
                        }
                    }
                }
                .padding(.horizontal)

                // MARK: - Children List
                if viewModel.children.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "No Children Linked",
                        systemImage: "person.badge.plus",
                        description: Text("Share your pairing code with your child to get started.")
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(viewModel.children) { child in
                        ChildStatusCard(
                            child: child,
                            status: viewModel.childStatuses[child.uid],
                            onToggleSafeMode: { enable in
                                Task {
                                    await viewModel.toggleSafeMode(for: child.uid, enable: enable)
                                }
                            },
                            onViewReports: {
                                // Handled by NavigationLink inside the card
                            }
                        )
                    }
                }

                // MARK: - Recent Commands
                if !viewModel.recentCommands.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Commands")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(viewModel.recentCommands.prefix(5)) { command in
                            CommandRow(command: command, childName: viewModel.childName(for: command.targetChildId))
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            if let family = appState.currentFamily, let uid = appState.currentUser?.uid {
                viewModel.load(family: family, parentId: uid)
            }
        }
        .onAppear {
            if let family = appState.currentFamily, let uid = appState.currentUser?.uid {
                viewModel.load(family: family, parentId: uid)
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - Pairing Code Banner

private struct PairingCodeBanner: View {
    let code: String

    var body: some View {
        VStack(spacing: 8) {
            Text("Family Pairing Code")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(code)
                .font(.system(.title, design: .monospaced).bold())
                .kerning(4)

            Text("Share this code with your child's device")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.accentColor.opacity(0.08))
        )
        .padding(.horizontal)
    }
}

// MARK: - Command Row

private struct CommandRow: View {
    let command: CommandModel
    let childName: String

    var body: some View {
        HStack {
            Image(systemName: command.type == .enableSafeMode ? "lock.shield.fill" : "lock.open.fill")
                .foregroundStyle(command.type == .enableSafeMode ? .orange : .green)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(command.type == .enableSafeMode ? "Enabled" : "Disabled") safe mode for \(childName)")
                    .font(.subheadline)
                Text(command.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            StatusBadge(status: command.status)
        }
        .padding(.horizontal)
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: CommandStatus

    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .pending:      return .orange
        case .acknowledged: return .blue
        case .completed:    return .green
        case .failed:       return .red
        }
    }
}

#Preview {
    NavigationStack {
        ParentDashboardView()
            .environmentObject(AppState())
    }
}

// MARK: - Quick Action Card

private struct QuickActionCard<Destination: View>: View {
    let icon: String
    let title: String
    let color: Color
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        ZStack {
            destination()
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.08))
            )
        }
    }
}
