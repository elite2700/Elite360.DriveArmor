// NotificationService.swift
// Elite360.DriveArmor
//
// Handles local notifications on behalf of the app and FCM token management.
// Push delivery is handled server-side via FCM; this service manages the
// device-side token lifecycle and local alert scheduling.

import Foundation
import UserNotifications
import FirebaseMessaging
import Combine

final class NotificationService: ObservableObject {

    private let authService = AuthService()
    private var tokenCancellable: AnyCancellable?

    // MARK: - Init

    init() {
        observeTokenRefresh()
    }

    // MARK: - FCM Token

    /// Listen for token refresh broadcasts from AppDelegate and persist to Firestore.
    private func observeTokenRefresh() {
        tokenCancellable = NotificationCenter.default
            .publisher(for: .fcmTokenDidRefresh)
            .compactMap { $0.userInfo?["token"] as? String }
            .sink { [weak self] token in
                self?.uploadToken(token)
            }
    }

    /// Upload the current FCM token for the signed-in user.
    func uploadCurrentToken(uid: String) {
        Messaging.messaging().token { [weak self] token, error in
            if let error = error {
                print("[Notification] Error fetching FCM token: \(error.localizedDescription)")
                return
            }
            if let token = token {
                self?.uploadToken(token, uid: uid)
            }
        }
    }

    private func uploadToken(_ token: String, uid: String? = nil) {
        guard let uid = uid ?? currentUID else { return }
        Task {
            do {
                try await authService.updateFCMToken(uid: uid, token: token)
            } catch {
                print("[Notification] Failed to upload FCM token: \(error.localizedDescription)")
            }
        }
    }

    private var currentUID: String? {
        FirebaseAuth.Auth.auth().currentUser?.uid
    }

    // MARK: - Local Notifications

    /// Schedule a local notification (e.g., "Safe mode has been activated").
    func scheduleLocal(
        title: String,
        body: String,
        delay: TimeInterval = 0,
        identifier: String = UUID().uuidString
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger: UNNotificationTrigger?
        if delay > 0 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        } else {
            trigger = nil // Deliver immediately
        }

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[Notification] Failed to schedule: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Remove Notifications

    func removeAll() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// Firebase Auth import for currentUser access
import FirebaseAuth
