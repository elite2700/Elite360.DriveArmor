// AppConstants.swift
// Elite360.DriveArmor
//
// Centralised constants referenced throughout the codebase.

import Foundation

enum AppConstants {

    // MARK: - Firestore Collection Paths

    enum Firestore {
        static let usersCollection             = "users"
        static let familiesCollection          = "families"
        static let commandsSubcollection       = "commands"
        static let deviceStatusSubcollection   = "deviceStatus"
        static let drivingLogsSubcollection    = "drivingLogs"
        static let overrideRequestsSub         = "overrideRequests"
        static let ruleChangeRequestsSub       = "ruleChangeRequests"
        static let geofencesSub                = "geofences"
        static let schedulesSub                = "schedules"
        static let gamificationSub             = "gamification"
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

    // MARK: - Subscription

    enum Subscription {
        static let monthlyStandardId     = "com.elite360.DriveArmor.standard.monthly"
        static let monthlyPremiumId      = "com.elite360.DriveArmor.premium.monthly"
        static let monthlyFamilyId       = "com.elite360.DriveArmor.family.monthly"
        static let annualStandardId      = "com.elite360.DriveArmor.standard.annual"
        static let annualPremiumId       = "com.elite360.DriveArmor.premium.annual"
        static let annualFamilyId        = "com.elite360.DriveArmor.family.annual"
    }

    // MARK: - Gamification

    enum Gamification {
        static let pointsPerSafeDrive     = 10
        static let pointsPerDrive         = 2
        static let pointsPerBadge         = 50
        static let streakMasterThreshold  = 30  // consecutive days
    }
}
