// AppConstants.swift
// Elite360.DriveArmor
//
// Centralised constants referenced throughout the codebase.

import Foundation

enum AppConstants {

    // MARK: - Firestore Collection Paths

    enum Firestore {
        static let usersCollection         = "users"
        static let familiesCollection      = "families"
        static let commandsSubcollection   = "commands"
        static let deviceStatusSubcollection = "deviceStatus"
        static let drivingLogsSubcollection  = "drivingLogs"
    }

    // MARK: - Driving Detection

    enum Driving {
        /// Speed threshold in mph above which we consider the device to be in a car.
        static let speedThresholdMPH: Double = 20.0

        /// Interval (seconds) between device-status pushes to Firestore.
        static let statusUpdateInterval: TimeInterval = 10.0
    }

    // MARK: - Pairing

    enum Pairing {
        /// Length of the alphanumeric family pairing code.
        static let codeLength = 6
    }

    // MARK: - Notifications

    enum Notifications {
        static let safeModeEnabledTitle   = "Safe Mode Activated"
        static let safeModeDisabledTitle  = "Safe Mode Disabled"
        static let drivingDetectedTitle   = "Driving Detected"
    }

    // MARK: - UI

    enum UI {
        /// Maximum speed shown on the child dashboard ring (mph).
        static let speedometerMax: Double = 80.0
    }
}
