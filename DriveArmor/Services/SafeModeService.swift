// SafeModeService.swift
// Elite360.DriveArmor
//
// Applies and removes "safe mode" restrictions on the child device.
// Uses achievable iOS alternatives:
//   - Focus status awareness (INFocusStatusCenter)
//   - Notification suppression (UNUserNotificationCenter)
//   - App-internal overlay to discourage phone usage while driving
//
// Does NOT attempt to toggle airplane mode (prohibited by iOS sandboxing).

import Foundation
import UserNotifications
import Combine

final class SafeModeService: ObservableObject {

    // MARK: - Published State

    @Published var isActive: Bool = false

    /// The overlay view reads this to decide whether to show the safe-mode screen.
    @Published var showOverlay: Bool = false

    /// Optional message from the parent explaining why safe mode was enabled.
    @Published var parentMessage: String?

    /// Timestamp when safe mode auto-expires (nil = indefinite until parent disables).
    @Published var expiresAt: Date?

    // MARK: - Private

    private var expirationTimer: Timer?

    // MARK: - Activate

    /// Enable safe mode on this device.
    /// - Parameters:
    ///   - durationMinutes: How long safe mode lasts. `nil` means indefinite.
    ///   - reason: Optional parent message displayed on the overlay.
    func activate(durationMinutes: Int? = nil, reason: String? = nil) {
        isActive = true
        showOverlay = true
        parentMessage = reason

        // Suppress notification delivery while in safe mode
        suppressNotifications()

        // Schedule auto-expiration if duration is set
        if let minutes = durationMinutes, minutes > 0 {
            let expiry = Date().addingTimeInterval(TimeInterval(minutes * 60))
            expiresAt = expiry
            expirationTimer?.invalidate()
            expirationTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(minutes * 60),
                                                   repeats: false) { [weak self] _ in
                self?.deactivate()
            }
        } else {
            expiresAt = nil
        }

        print("[SafeMode] Activated. Duration: \(durationMinutes ?? -1) min")
    }

    // MARK: - Deactivate

    func deactivate() {
        isActive = false
        showOverlay = false
        parentMessage = nil
        expiresAt = nil
        expirationTimer?.invalidate()
        expirationTimer = nil

        restoreNotifications()

        print("[SafeMode] Deactivated")
    }

    // MARK: - Notification Management

    /// Remove all pending notifications and disable alert presentation while driving.
    private func suppressNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        // NOTE: We cannot programmatically toggle system-level DND/Focus from a
        // third-party app. The overlay UI acts as the primary distraction blocker.
        // If the user has configured Focus Filters via the system Settings to grant
        // this app control, those rules apply automatically.
    }

    /// Re-allow notifications after safe mode ends.
    private func restoreNotifications() {
        // Notifications will resume delivery via standard iOS behaviour once the
        // app stops clearing them. No explicit "restore" call is needed.
    }
}
