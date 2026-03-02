// ParentDashboardViewModel.swift
// Elite360.DriveArmor
//
// Drives the parent's main dashboard: real-time child statuses,
// remote safe-mode commands, command history, and child profiles.

import Foundation
import Combine

@MainActor
final class ParentDashboardViewModel: ObservableObject {

    // MARK: - Published

    @Published var children: [UserModel] = []
    @Published var childStatuses: [String: DeviceStatus] = [:]  // keyed by childId
    @Published var recentCommands: [CommandModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Services

    private let familyService = FamilyService()
    private let commandService = CommandService()
    private let statusService = DeviceStatusService()

    // MARK: - Private

    private var cancellables = Set<AnyCancellable>()
    private var familyId: String?
    private var parentId: String?

    // MARK: - Load

    /// Initialize the dashboard with the current family data.
    func load(family: FamilyModel, parentId: String) {
        self.familyId = family.id
        self.parentId = parentId

        Task {
            isLoading = true
            do {
                // Fetch child profiles
                children = try await familyService.fetchChildProfiles(childIds: family.childIds)

                // Subscribe to each child's live status
                for childId in family.childIds {
                    subscribeToChildStatus(familyId: family.id, childId: childId)
                }

                // Load recent command history
                recentCommands = try await commandService.fetchRecentCommands(familyId: family.id)
            } catch {
                showErrorMessage(error.localizedDescription)
            }
            isLoading = false
        }
    }

    // MARK: - Real-time Status

    private func subscribeToChildStatus(familyId: String, childId: String) {
        statusService.listenToChildStatus(familyId: familyId, childId: childId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.showErrorMessage(error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] status in
                    self?.childStatuses[childId] = status
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - Commands

    /// Send an enableSafeMode or disableSafeMode command to a specific child.
    func toggleSafeMode(
        for childId: String,
        enable: Bool,
        durationMinutes: Int? = nil,
        reason: String? = nil
    ) async {
        guard let familyId = familyId, let parentId = parentId else { return }

        do {
            let command = try await commandService.sendCommand(
                familyId: familyId,
                type: enable ? .enableSafeMode : .disableSafeMode,
                targetChildId: childId,
                issuedBy: parentId,
                params: CommandParams(durationMinutes: durationMinutes, reason: reason)
            )

            // Prepend to local history for instant UI feedback
            recentCommands.insert(command, at: 0)
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }

    // MARK: - Helpers

    /// Get the display name for a child UID.
    func childName(for childId: String) -> String {
        children.first(where: { $0.uid == childId })?.displayName ?? "Child"
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
