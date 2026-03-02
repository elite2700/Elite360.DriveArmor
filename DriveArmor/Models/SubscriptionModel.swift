// SubscriptionModel.swift
// Elite360.DriveArmor
//
// Defines the four subscription tiers and their capabilities.
// The active tier is stored in /families/{familyId} and gated via SubscriptionService.

import Foundation

/// The four subscription tiers offered by DriveArmor.
enum SubscriptionTier: String, Codable, CaseIterable, Comparable {
    case free
    case standard
    case premium
    case familyUltimate

    // MARK: - Display

    var displayName: String {
        switch self {
        case .free:            return "Free / Basic"
        case .standard:        return "Standard"
        case .premium:         return "Premium"
        case .familyUltimate:  return "Family Ultimate"
        }
    }

    var monthlyPrice: String {
        switch self {
        case .free:            return "$0"
        case .standard:        return "$4.99"
        case .premium:         return "$9.99"
        case .familyUltimate:  return "$14.99"
        }
    }

    var annualPrice: String? {
        switch self {
        case .free:            return nil
        case .standard:        return "$49.99/yr"
        case .premium:         return "$99.99/yr"
        case .familyUltimate:  return "$149.99/yr"
        }
    }

    // MARK: - StoreKit Product IDs

    var monthlyProductId: String? {
        switch self {
        case .free:            return nil
        case .standard:        return "com.elite360.DriveArmor.standard.monthly"
        case .premium:         return "com.elite360.DriveArmor.premium.monthly"
        case .familyUltimate:  return "com.elite360.DriveArmor.ultimate.monthly"
        }
    }

    var annualProductId: String? {
        switch self {
        case .free:            return nil
        case .standard:        return "com.elite360.DriveArmor.standard.annual"
        case .premium:         return "com.elite360.DriveArmor.premium.annual"
        case .familyUltimate:  return "com.elite360.DriveArmor.ultimate.annual"
        }
    }

    // MARK: - Feature Gates

    var maxDevices: Int {
        switch self {
        case .free:            return 1
        case .standard:        return 2
        case .premium:         return 5
        case .familyUltimate:  return .max  // unlimited
        }
    }

    var hasRemoteSafeMode: Bool          { self >= .standard }
    var hasDrivingReports: Bool          { self >= .standard }
    var hasScheduling: Bool              { self >= .standard }
    var hasAdvancedAnalytics: Bool       { self >= .premium }
    var hasGeofencing: Bool              { self >= .premium }
    var hasGamification: Bool            { self >= .premium }
    var hasSpeedAlerts: Bool             { self >= .premium }
    var hasPrioritySupport: Bool         { self >= .premium }
    var hasBluetoothIntegration: Bool    { self == .familyUltimate }
    var hasDataExport: Bool              { self == .familyUltimate }
    var hasFamilySharingDashboard: Bool  { self == .familyUltimate }

    // MARK: - Features List (for paywall UI)

    var features: [String] {
        switch self {
        case .free:
            return [
                "Auto-driving detection",
                "Basic safe mode (notification silencing)",
                "Emergency overrides",
                "Single device support"
            ]
        case .standard:
            return [
                "All Free features",
                "Remote safe mode triggers",
                "Basic driving reports",
                "Scheduled safe mode",
                "2 devices"
            ]
        case .premium:
            return [
                "All Standard features",
                "Speed alerts & geofencing",
                "Advanced analytics & charts",
                "Gamification (badges & streaks)",
                "Up to 5 devices",
                "Priority support"
            ]
        case .familyUltimate:
            return [
                "All Premium features",
                "Unlimited devices",
                "Car Bluetooth integration",
                "Data export for insurers",
                "Family sharing dashboard"
            ]
        }
    }

    // MARK: - Comparable

    private var sortOrder: Int {
        switch self {
        case .free: return 0
        case .standard: return 1
        case .premium: return 2
        case .familyUltimate: return 3
        }
    }

    static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Subscription Status

struct SubscriptionStatus: Codable, Equatable {
    var tier: SubscriptionTier
    var isActive: Bool
    var expiresAt: Date?
    var productId: String?
    var originalTransactionId: String?

    init(
        tier: SubscriptionTier = .free,
        isActive: Bool = true,
        expiresAt: Date? = nil,
        productId: String? = nil,
        originalTransactionId: String? = nil
    ) {
        self.tier = tier
        self.isActive = isActive
        self.expiresAt = expiresAt
        self.productId = productId
        self.originalTransactionId = originalTransactionId
    }

    var asDictionary: [String: Any] {
        var dict: [String: Any] = [
            "tier": tier.rawValue,
            "isActive": isActive
        ]
        if let expiresAt { dict["expiresAt"] = expiresAt }
        if let productId { dict["productId"] = productId }
        if let originalTransactionId { dict["originalTransactionId"] = originalTransactionId }
        return dict
    }

    static func from(dictionary dict: [String: Any]) -> SubscriptionStatus {
        SubscriptionStatus(
            tier: (dict["tier"] as? String).flatMap { SubscriptionTier(rawValue: $0) } ?? .free,
            isActive: dict["isActive"] as? Bool ?? true,
            expiresAt: dict["expiresAt"] as? Date,
            productId: dict["productId"] as? String,
            originalTransactionId: dict["originalTransactionId"] as? String
        )
    }
}
