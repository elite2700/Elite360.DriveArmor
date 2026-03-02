// ChildDashboardViewModel.swift
// Elite360.DriveArmor
//
// Drives the child's view: listens for parent commands, runs driving detection,
// manages safe-mode state, and pushes device status to Firestore.

import Foundation
import Combine

@MainActor
final class ChildDashboardViewModel: ObservableObject {

    // MARK: - Published

    @Published var isDriving: Bool = false
    @Published var currentSpeed: Double = 0
    @Published var safeModeActive: Bool = false
    @Published var parentMessage: String?
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Services

    let drivingDetection = DrivingDetectionService()
    let safeModeService = SafeModeService()
    private let commandService = CommandService()
    private let statusService = DeviceStatusService()
    private let notificationService = NotificationService()

    // MARK: - Private

    private var cancellables = Set<AnyCancellable>()
    private var statusTimer: Timer?
    private var familyId: String?
    private var childId: String?

    // MARK: - Lifecycle

    func start(familyId: String, childId: String) {
        self.familyId = familyId
        self.childId = childId

        // Start driving detection
        drivingDetection.startMonitoring()

        // Bind driving detection → local state
        drivingDetection.$isDriving
            .receive(on: DispatchQueue.main)
            .assign(to: &$isDriving)

        drivingDetection.$currentSpeed
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentSpeed)

        // Bind safe mode service → local state
        safeModeService.$isActive
            .receive(on: DispatchQueue.main)
            .assign(to: &$safeModeActive)

        safeModeService.$parentMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$parentMessage)

        // Auto-activate safe mode when driving detected
        drivingDetection.$isDriving
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] driving in
                if driving && !(self?.safeModeActive ?? false) {
                    self?.safeModeService.activate(reason: "Driving detected automatically")
                    self?.notificationService.scheduleLocal(
                        title: "Safe Mode Activated",
                        body: "Driving detected. Distractions are being minimized."
                    )
                }
            }
            .store(in: &cancellables)

        // Listen for parent commands
        listenForCommands()

        // Periodically push device status
        startStatusUpdates()

        // Upload FCM token
        notificationService.uploadCurrentToken(uid: childId)
    }

    func stop() {
        drivingDetection.stopMonitoring()
        statusTimer?.invalidate()
        cancellables.removeAll()
    }

    // MARK: - Command Listener

    private func listenForCommands() {
        guard let familyId = familyId, let childId = childId else { return }

        commandService.listenForCommands(familyId: familyId, childId: childId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        self?.showError = true
                    }
                },
                receiveValue: { [weak self] commands in
                    self?.handleIncomingCommands(commands)
                }
            )
            .store(in: &cancellables)
    }

    private func handleIncomingCommands(_ commands: [CommandModel]) {
        guard let familyId = familyId else { return }

        for command in commands {
            switch command.type {
            case .enableSafeMode:
                safeModeService.activate(
                    durationMinutes: command.params?.durationMinutes,
                    reason: command.params?.reason ?? "Safe mode enabled by parent"
                )
                notificationService.scheduleLocal(
                    title: "Safe Mode Enabled",
                    body: command.params?.reason ?? "Your parent has enabled safe mode."
                )

            case .disableSafeMode:
                safeModeService.deactivate()
                notificationService.scheduleLocal(
                    title: "Safe Mode Disabled",
                    body: "Safe mode has been turned off by your parent."
                )
            }

            // Acknowledge the command
            Task {
                try? await commandService.updateCommandStatus(
                    familyId: familyId,
                    commandId: command.id,
                    status: .completed
                )
            }
        }
    }

    // MARK: - Device Status Updates

    private func startStatusUpdates() {
        // Push status every 10 seconds while active
        statusTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.pushStatus()
            }
        }
        // Also push immediately
        Task { await pushStatus() }
    }

    private func pushStatus() async {
        guard let familyId = familyId, let childId = childId else { return }

        let status = DeviceStatus(
            childId: childId,
            drivingDetected: isDriving,
            safeModeActive: safeModeActive,
            currentSpeed: currentSpeed,
            lastLatitude: drivingDetection.buildCurrentLog(childId: childId) != nil ? nil : nil,
            batteryLevel: Double(UIDevice.current.batteryLevel)
        )

        do {
            try await statusService.updateStatus(familyId: familyId, status: status)
        } catch {
            print("[ChildDashboard] Status update failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Manual Override

    /// Child can manually dismiss safe mode (parent will be notified).
    func manualOverrideSafeMode() {
        safeModeService.deactivate()
        // TODO: Notify parent via a Firestore document or FCM that child overrode safe mode
    }
}

import UIKit // For UIDevice.current.batteryLevel
