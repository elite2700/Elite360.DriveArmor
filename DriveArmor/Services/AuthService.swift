// AuthService.swift
// Elite360.DriveArmor
//
// Wraps Firebase Auth and the /users Firestore collection.
// Provides async/await methods for sign-up, sign-in, profile CRUD.

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthService {

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var usersRef: CollectionReference { db.collection("users") }

    // MARK: - Sign Up

    /// Create a new Firebase Auth account and a matching Firestore profile.
    func signUp(email: String, password: String, displayName: String) async throws -> UserModel {
        let result = try await auth.createUser(withEmail: email, password: password)

        // Update the Auth display name
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()

        // Build the user model (role assigned later in onboarding)
        let user = UserModel(
            uid: result.user.uid,
            email: email,
            displayName: displayName
        )

        // Persist to Firestore
        try await usersRef.document(user.uid).setData(user.asDictionary)
        return user
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws -> UserModel {
        let result = try await auth.signIn(withEmail: email, password: password)
        guard let user = try await fetchUserProfile(uid: result.user.uid) else {
            throw DriveArmorError.userProfileNotFound
        }
        return user
    }

    // MARK: - Profile

    /// Fetch the Firestore profile for a given UID. Returns nil if no document exists.
    func fetchUserProfile(uid: String) async throws -> UserModel? {
        let snapshot = try await usersRef.document(uid).getDocument()
        guard let data = snapshot.data() else { return nil }
        return UserModel.from(dictionary: data, uid: uid)
    }

    /// Update specific fields on the user profile.
    func updateProfile(uid: String, fields: [String: Any]) async throws {
        try await usersRef.document(uid).updateData(fields)
    }

    /// Set the user's role (parent/child) during onboarding.
    func setRole(uid: String, role: UserRole) async throws {
        try await updateProfile(uid: uid, fields: ["role": role.rawValue])
    }

    /// Store the latest FCM push token so the server can reach this device.
    func updateFCMToken(uid: String, token: String) async throws {
        try await updateProfile(uid: uid, fields: ["fcmToken": token])
    }

    // MARK: - Sign Out

    func signOut() throws {
        try auth.signOut()
    }

    // MARK: - Password Reset

    func sendPasswordReset(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
}

// MARK: - App-specific Errors

enum DriveArmorError: LocalizedError {
    case userProfileNotFound
    case familyNotFound
    case invalidPairingCode
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .userProfileNotFound:  return "User profile not found. Please sign up again."
        case .familyNotFound:       return "Family group not found."
        case .invalidPairingCode:   return "The pairing code is incorrect or expired."
        case .commandFailed(let m): return "Command failed: \(m)"
        }
    }
}
