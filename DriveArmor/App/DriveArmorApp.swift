// DriveArmorApp.swift
// Elite360.DriveArmor
//
// Main application entry point. Configures Firebase and injects global state.

import SwiftUI
import FirebaseCore

@main
struct DriveArmorApp: App {
    // Bridge to UIKit for push notification & Firebase lifecycle handling
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
