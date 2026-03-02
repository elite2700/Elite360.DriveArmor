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
    @Published var overrideRequestPending: Bool = false

    // MARK: - Services

    let drivingDetection = DrivingDetectionService()
    let safeModeService = SafeModeService()
    private let commandService = CommandService()
    private let statusService = DeviceStatusService()
    private let notificationService = NotificationService()
    private let overrideService = OverrideRequestService()
    private let gamificationService = GamificationService()
    private let scheduleService = ScheduleService()

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

        // Check for active schedules
        checkSchedules()

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

            case .overrideNotification, .speedAlert, .scheduleTriggered, .geofenceAlert:
                // These are parent-bound notifications; child just acknowledges
                break
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

    // MARK: - Manual Override (now sends a request instead of directly disabling)

    /// Child requests safe mode override — sends request to parent for approval.
    func requestOverride(reason: String = "Emergency") {
        guard let familyId = familyId, let childId = childId else { return }
        overrideRequestPending = true

        Task {
            _ = try? await overrideService.sendOverrideRequest(
                familyId: familyId,
                childId: childId,
                reason: reason
            )

            // Also notify parent via a command document
            _ = try? await commandService.sendCommand(
                familyId: familyId,
                type: .overrideNotification,
                targetChildId: childId,
                issuedBy: childId,
                params: CommandParams(reason: "Teen requested safe mode override: \(reason)")
            )
        }
    }

    /// Direct override (only used if parent pre-approved or after approval received).
    func manualOverrideSafeMode() {
        safeModeService.deactivate()
        overrideRequestPending = false

        guard let familyId = familyId, let childId = childId else { return }

        // Notify parent that child overrode safe mode
        Task {
            _ = try? await commandService.sendCommand(
                familyId: familyId,
                type: .overrideNotification,
                targetChildId: childId,
                issuedBy: childId,
                params: CommandParams(reason: "Teen overrode safe mode")
            )
        }
    }

    // MARK: - Gamification

    /// Record drive completion for gamification tracking.
    func recordDriveEnd(log: DrivingLog) {
        guard let familyId = familyId, let childId = childId else { return }
        Task {
            _ = try? await gamificationService.recordDriveCompletion(
                familyId: familyId,
                childId: childId,
                log: log
            )
        }
    }

    // MARK: - Schedule Checking

    private func checkSchedules() {
        guard let familyId = familyId else { return }
        scheduleService.listenToSchedules(familyId: familyId)

        // Check schedule status periodically
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.scheduleService.isScheduleActiveNow() && !self.safeModeActive {
                    self.safeModeService.activate(reason: "Scheduled safe mode active")
                    self.notificationService.scheduleLocal(
                        title: "Scheduled Safe Mode",
                        body: "Safe mode activated per schedule."
                    )
                }
            }
        }
    }
}

import UIKit // For UIDevice.current.batteryLevel
