// UserModel.swift
// Elite360.DriveArmor
//
// Represents a registered user stored in Firestore at /users/{uid}.

import Foundation

/// The user's role within the app.
enum UserRole: String, Codable, CaseIterable {
    case parent
    case child
}

struct UserModel: Codable, Identifiable, Equatable {
    /// Firestore document ID (matches Firebase Auth UID).
    var id: String { uid }

    let uid: String
    var email: String
    var displayName: String
    var role: UserRole?
    var familyId: String?
    var fcmToken: String?
    var createdAt: Date

    init(
        uid: String,
        email: String,
        displayName: String,
        role: UserRole? = nil,
        familyId: String? = nil,
        fcmToken: String? = nil,
        createdAt: Date = Date()
    ) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.role = role
        self.familyId = familyId
        self.fcmToken = fcmToken
        self.createdAt = createdAt
    }

    // MARK: - Firestore Helpers

    /// Convert to a dictionary suitable for Firestore `setData`.
    var asDictionary: [String: Any] {
        var dict: [String: Any] = [
            "uid": uid,
            "email": email,
            "displayName": displayName,
            "createdAt": createdAt
        ]
        if let role = role { dict["role"] = role.rawValue }
        if let familyId = familyId { dict["familyId"] = familyId }
        if let fcmToken = fcmToken { dict["fcmToken"] = fcmToken }
        return dict
    }

    /// Create from a Firestore document dictionary.
    static func from(dictionary dict: [String: Any], uid: String) -> UserModel? {
        guard let email = dict["email"] as? String else { return nil }
        return UserModel(
            uid: uid,
            email: email,
            displayName: dict["displayName"] as? String ?? "",
            role: (dict["role"] as? String).flatMap { UserRole(rawValue: $0) },
            familyId: dict["familyId"] as? String,
            fcmToken: dict["fcmToken"] as? String,
            createdAt: (dict["createdAt"] as? Date) ?? Date()
        )
    }
}
