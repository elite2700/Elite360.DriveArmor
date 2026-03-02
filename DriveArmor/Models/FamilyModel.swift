// FamilyModel.swift
// Elite360.DriveArmor
//
// Represents a family group stored at /families/{familyId}.
// Links one parent to one or more child UIDs and holds the pairing code.

import Foundation

struct FamilyModel: Codable, Identifiable, Equatable {
    let id: String            // Firestore document ID
    var name: String          // e.g. "Smith Family"
    var parentId: String      // UID of the parent who created the group
    var childIds: [String]    // UIDs of linked children
    var pairingCode: String   // 6-character alphanumeric code for child onboarding
    var subscriptionTier: String  // raw value of SubscriptionTier (free/standard/premium/familyUltimate)
    var speedThresholds: SpeedThresholds
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        parentId: String,
        childIds: [String] = [],
        pairingCode: String = FamilyModel.generatePairingCode(),
        subscriptionTier: String = "free",
        speedThresholds: SpeedThresholds = SpeedThresholds(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.parentId = parentId
        self.childIds = childIds
        self.pairingCode = pairingCode
        self.subscriptionTier = subscriptionTier
        self.speedThresholds = speedThresholds
        self.createdAt = createdAt
    }

    // MARK: - Pairing Code

    /// Generate a random 6-character uppercase alphanumeric pairing code.
    static func generatePairingCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Omit confusable chars (0, O, 1, I)
        return String((0..<6).map { _ in chars.randomElement()! })
    }

    // MARK: - Firestore Helpers

    var asDictionary: [String: Any] {
        [
            "id": id,
            "name": name,
            "parentId": parentId,
            "childIds": childIds,
            "pairingCode": pairingCode,
            "subscriptionTier": subscriptionTier,
            "speedThresholds": speedThresholds.asDictionary,
            "createdAt": createdAt
        ]
    }

    static func from(dictionary dict: [String: Any], id: String) -> FamilyModel? {
        guard let name = dict["name"] as? String,
              let parentId = dict["parentId"] as? String else { return nil }

        let thresholdsDict = dict["speedThresholds"] as? [String: Any]
        let thresholds = thresholdsDict.map { SpeedThresholds.from(dictionary: $0) } ?? SpeedThresholds()

        return FamilyModel(
            id: id,
            name: name,
            parentId: parentId,
            childIds: dict["childIds"] as? [String] ?? [],
            pairingCode: dict["pairingCode"] as? String ?? "",
            subscriptionTier: dict["subscriptionTier"] as? String ?? "free",
            speedThresholds: thresholds,
            createdAt: (dict["createdAt"] as? Date) ?? Date()
        )
    }
}

// MARK: - Speed Thresholds

struct SpeedThresholds: Codable, Equatable {
    var general: Double
    var schoolZone: Double
    var residential: Double
    var highway: Double

    init(general: Double = 70, schoolZone: Double = 25, residential: Double = 35, highway: Double = 75) {
        self.general = general
        self.schoolZone = schoolZone
        self.residential = residential
        self.highway = highway
    }

    var asDictionary: [String: Any] {
        [
            "general": general,
            "schoolZone": schoolZone,
            "residential": residential,
            "highway": highway
        ]
    }

    static func from(dictionary dict: [String: Any]) -> SpeedThresholds {
        SpeedThresholds(
            general: dict["general"] as? Double ?? 70,
            schoolZone: dict["schoolZone"] as? Double ?? 25,
            residential: dict["residential"] as? Double ?? 35,
            highway: dict["highway"] as? Double ?? 75
        )
    }
}
