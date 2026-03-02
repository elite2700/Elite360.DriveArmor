// ChildDashboardView.swift
// Elite360.DriveArmor
//
// Main child screen: shows driving status, speed, and safe-mode state.
// Overlays the safe-mode view when active.

import SwiftUI

struct ChildDashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ChildDashboardViewModel()
    @State private var showOverrideSheet = false
    @State private var overrideReason = ""

    var body: some View {
        ZStack {
            // MARK: - Main Content
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DriveArmor")
                                .font(.largeTitle.bold())
                            Text(appState.currentUser?.displayName ?? "")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)

                    // MARK: - Driving Status Ring
                    DrivingStatusRing(
                        isDriving: viewModel.isDriving,
                        speed: viewModel.currentSpeed,
                        safeModeActive: viewModel.safeModeActive
                    )

                    // MARK: - Status Cards
                    VStack(spacing: 12) {
                        StatusRow(
                            icon: "car.fill",
                            label: "Driving Detection",
                            value: viewModel.isDriving ? "Active" : "Monitoring",
                            color: viewModel.isDriving ? .orange : .green
                        )

                        StatusRow(
                            icon: "lock.shield.fill",
                            label: "Safe Mode",
                            value: viewModel.safeModeActive ? "Enabled" : "Disabled",
                            color: viewModel.safeModeActive ? .orange : .secondary
                        )

                        StatusRow(
                            icon: "speedometer",
                            label: "Current Speed",
                            value: String(format: "%.0f mph", viewModel.currentSpeed),
                            color: viewModel.currentSpeed > 20 ? .orange : .green
                        )

                        if viewModel.drivingDetection.authorizationDenied {
                            StatusRow(
                                icon: "exclamationmark.triangle.fill",
                                label: "Location Access",
                                value: "Denied – tap to fix",
                                color: .red
                            )
                            .onTapGesture {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // MARK: - Manual Override (Request-based)
                    if viewModel.safeModeActive {
                        if viewModel.overrideRequestPending {
                            Label("Override Request Sent", systemImage: "clock.fill")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.orange.opacity(0.08))
                                )
                                .padding(.horizontal)
                        } else {
                            Button(role: .destructive) {
                                showOverrideSheet = true
                            } label: {
                                Label("Request Override", systemImage: "exclamationmark.shield.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .padding(.horizontal)
                        }

                        Text("Your parent will be notified and must approve the override.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // MARK: - Gamification & Rule Changes
                    HStack(spacing: 12) {
                        NavigationLink(destination: GamificationView()) {
                            VStack(spacing: 6) {
                                Image(systemName: "trophy.fill")
                                    .font(.title2)
                                    .foregroundStyle(.yellow)
                                Text("My Driving")
                                    .font(.caption.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.yellow.opacity(0.08))
                            )
                        }

                        NavigationLink(destination: RuleChangeRequestView()) {
                            VStack(spacing: 6) {
                                Image(systemName: "doc.badge.gearshape")
                                    .font(.title2)
                                    .foregroundStyle(.teal)
                                Text("Rule Changes")
                                    .font(.caption.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.teal.opacity(0.08))
                            )
                        }

                        NavigationLink(destination: OverrideRequestsView()) {
                            VStack(spacing: 6) {
                                Image(systemName: "hand.raised.fill")
                                    .font(.title2)
                                    .foregroundStyle(.red)
                                Text("Overrides")
                                    .font(.caption.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.08))
                            )
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 60)
                }
                .padding(.vertical)
            }

            // MARK: - Safe Mode Overlay
            if viewModel.safeModeActive {
                SafeModeOverlayView(
                    message: viewModel.parentMessage,
                    onOverride: { viewModel.manualOverrideSafeMode() }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: viewModel.safeModeActive)
        .onAppear {
            if let familyId = appState.currentFamily?.id,
               let uid = appState.currentUser?.uid {
                viewModel.start(familyId: familyId, childId: uid)
            }
        }
        .onDisappear {
            viewModel.stop()
        }
        .sheet(isPresented: $showOverrideSheet) {
            NavigationStack {
                Form {
                    Section("Why do you need to override safe mode?") {
                        TextEditor(text: $overrideReason)
                            .frame(minHeight: 80)
                    }
                }
                .navigationTitle("Override Request")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showOverrideSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Send Request") {
                            viewModel.requestOverride(reason: overrideReason.isEmpty ? "Emergency" : overrideReason)
                            overrideReason = ""
                            showOverrideSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .onChange(of: viewModel.isDriving) { wasDriving, isDriving in
            if wasDriving && !isDriving {
                // Drive ended — record for gamification
                viewModel.recordDriveEnd(wasSafe: !viewModel.safeModeActive)
            }
        }
    }
}

// MARK: - Driving Status Ring

private struct DrivingStatusRing: View {
    let isDriving: Bool
    let speed: Double
    let safeModeActive: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(ringColor.opacity(0.2), lineWidth: 12)
                .frame(width: 180, height: 180)

            Circle()
                .trim(from: 0, to: min(speed / 80.0, 1.0)) // 80 mph = full ring
                .stroke(ringColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 180, height: 180)
                .animation(.easeInOut, value: speed)

            VStack(spacing: 4) {
                Image(systemName: isDriving ? "car.fill" : "car.side")
                    .font(.system(size: 36))
                    .foregroundStyle(ringColor)

                Text(String(format: "%.0f", speed))
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text("mph")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var ringColor: Color {
        if safeModeActive { return .orange }
        if isDriving { return .blue }
        return .green
    }
}

// MARK: - Status Row

private struct StatusRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 28)

            Text(label)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(color)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

import UIKit // For UIApplication

#Preview {
    NavigationStack {
        ChildDashboardView()
            .environmentObject(AppState())
    }
}
