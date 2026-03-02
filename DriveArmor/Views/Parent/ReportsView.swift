// ReportsView.swift
// Elite360.DriveArmor
//
// Displays driving history and statistics for a specific child.
// Uses Swift Charts for visual analytics.

import SwiftUI
import Charts

struct ReportsView: View {
    let childId: String
    let childName: String

    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ReportsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Summary Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    SummaryCard(title: "Sessions", value: "\(viewModel.totalSessions)", icon: "car.fill", color: .blue)
                    SummaryCard(title: "Total Time", value: formatDuration(viewModel.totalDrivingSeconds), icon: "clock.fill", color: .purple)
                    SummaryCard(title: "Avg Speed", value: String(format: "%.0f mph", viewModel.overallAverageSpeed), icon: "speedometer", color: .green)
                    SummaryCard(title: "Top Speed", value: String(format: "%.0f mph", viewModel.topSpeed), icon: "gauge.with.dots.needle.67percent", color: .orange)
                }
                .padding(.horizontal)

                // MARK: - Speed Chart
                if !viewModel.logs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Speed per Session")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart(viewModel.logs.prefix(20)) { log in
                            BarMark(
                                x: .value("Date", log.startTime, unit: .day),
                                y: .value("Max Speed", log.maxSpeed)
                            )
                            .foregroundStyle(.orange.gradient)

                            BarMark(
                                x: .value("Date", log.startTime, unit: .day),
                                y: .value("Avg Speed", log.averageSpeed)
                            )
                            .foregroundStyle(.blue.gradient)
                        }
                        .chartYAxisLabel("mph")
                        .frame(height: 200)
                        .padding(.horizontal)
                    }

                    // MARK: - Distraction Chart
                    if viewModel.totalDistractions > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Distraction Attempts")
                                .font(.headline)
                                .padding(.horizontal)

                            Chart(viewModel.logs.prefix(20)) { log in
                                BarMark(
                                    x: .value("Date", log.startTime, unit: .day),
                                    y: .value("Attempts", log.distractionAttempts)
                                )
                                .foregroundStyle(.red.gradient)
                            }
                            .frame(height: 150)
                            .padding(.horizontal)
                        }
                    }
                }

                // MARK: - Log List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Driving Sessions")
                        .font(.headline)
                        .padding(.horizontal)

                    if viewModel.logs.isEmpty && !viewModel.isLoading {
                        ContentUnavailableView(
                            "No Driving Data",
                            systemImage: "car.side",
                            description: Text("Driving sessions will appear here once your child starts driving.")
                        )
                    } else {
                        ForEach(viewModel.logs) { log in
                            DrivingLogRow(log: log)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("\(childName)'s Reports")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let familyId = appState.currentFamily?.id {
                Task { await viewModel.loadLogs(familyId: familyId, childId: childId) }
            }
        }
        .overlay {
            if viewModel.isLoading { ProgressView() }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

// MARK: - Summary Card

private struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Driving Log Row

private struct DrivingLogRow: View {
    let log: DrivingLog

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.startTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.bold())
                HStack(spacing: 12) {
                    Label(String(format: "%.0f mph max", log.maxSpeed), systemImage: "speedometer")
                    Label(String(format: "%.1f km", log.distanceKm), systemImage: "road.lanes")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let duration = log.durationSeconds {
                    Text(Duration.seconds(duration).formatted(.units(allowed: [.hours, .minutes])))
                        .font(.caption.bold())
                }
                if log.safeModeWasActive {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        ReportsView(childId: "test", childName: "Alex")
            .environmentObject(AppState())
    }
}
