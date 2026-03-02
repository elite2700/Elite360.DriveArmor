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
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        parentId: String,
        childIds: [String] = [],
        pairingCode: String = FamilyModel.generatePairingCode(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.parentId = parentId
        self.childIds = childIds
        self.pairingCode = pairingCode
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
            "createdAt": createdAt
        ]
    }

    static func from(dictionary dict: [String: Any], id: String) -> FamilyModel? {
        guard let name = dict["name"] as? String,
              let parentId = dict["parentId"] as? String else { return nil }
        return FamilyModel(
            id: id,
            name: name,
            parentId: parentId,
            childIds: dict["childIds"] as? [String] ?? [],
            pairingCode: dict["pairingCode"] as? String ?? "",
            createdAt: (dict["createdAt"] as? Date) ?? Date()
        )
    }
}
