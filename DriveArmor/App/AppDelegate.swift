// AppDelegate.swift
// Elite360.DriveArmor
//
// UIKit app delegate for Firebase setup, push notifications, and FCM token handling.

import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Application Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize Firebase SDK
        FirebaseApp.configure()

        // Request notification permissions and register for remote notifications
        configureNotifications(application)

        return true
    }

    // MARK: - Remote Notification Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Forward the APNs token to Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[DriveArmor] Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - Private

    private func configureNotifications(_ application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
                print("[DriveArmor] Notification auth error: \(error.localizedDescription)")
            }
            print("[DriveArmor] Notification permission granted: \(granted)")
        }
        application.registerForRemoteNotifications()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    /// Show notification banners even when app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .badge, .sound]
    }

    /// Handle notification tap actions.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        print("[DriveArmor] Notification tapped with payload: \(userInfo)")
        // Deep-link handling can be added here
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    /// Called when a new FCM registration token is received.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("[DriveArmor] FCM token: \(token)")

        // Persist the token so NotificationService can upload it to Firestore
        NotificationCenter.default.post(
            name: .fcmTokenDidRefresh,
            object: nil,
            userInfo: ["token": token]
        )
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let fcmTokenDidRefresh = Notification.Name("fcmTokenDidRefresh")
}
