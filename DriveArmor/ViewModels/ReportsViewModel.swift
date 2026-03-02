// ReportsViewModel.swift
// Elite360.DriveArmor
//
// Fetches and presents driving logs for the parent's reports view.
// Supports filtering by child and date range.

import Foundation
import Combine

@MainActor
final class ReportsViewModel: ObservableObject {

    // MARK: - Published

    @Published var logs: [DrivingLog] = []
    @Published var selectedChildId: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Computed

    /// Total number of driving sessions.
    var totalSessions: Int { logs.count }

    /// Total driving time across all logs (seconds).
    var totalDrivingSeconds: TimeInterval {
        logs.compactMap(\.durationSeconds).reduce(0, +)
    }

    /// Average speed across all sessions.
    var overallAverageSpeed: Double {
        guard !logs.isEmpty else { return 0 }
        return logs.map(\.averageSpeed).reduce(0, +) / Double(logs.count)
    }

    /// Maximum speed ever recorded.
    var topSpeed: Double {
        logs.map(\.maxSpeed).max() ?? 0
    }

    /// Total distraction attempts.
    var totalDistractions: Int {
        logs.map(\.distractionAttempts).reduce(0, +)
    }

    // MARK: - Services

    private let statusService = DeviceStatusService()

    // MARK: - Load

    func loadLogs(familyId: String, childId: String) async {
        selectedChildId = childId
        isLoading = true
        do {
            logs = try await statusService.fetchDrivingLogs(familyId: familyId, childId: childId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
