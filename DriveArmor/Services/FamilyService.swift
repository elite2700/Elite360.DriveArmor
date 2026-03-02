// FamilyService.swift
// Elite360.DriveArmor
//
// Manages the /families Firestore collection: creation, pairing, and queries.

import Foundation
import FirebaseFirestore

final class FamilyService {

    private let db = Firestore.firestore()
    private var familiesRef: CollectionReference { db.collection("families") }
    private var usersRef: CollectionReference { db.collection("users") }

    // MARK: - Create Family

    /// Parent creates a new family group. Returns the new family and its 6-char pairing code.
    func createFamily(name: String, parentId: String) async throws -> FamilyModel {
        let family = FamilyModel(name: name, parentId: parentId)
        try await familiesRef.document(family.id).setData(family.asDictionary)

        // Link the parent's profile to this family
        try await usersRef.document(parentId).updateData(["familyId": family.id])

        return family
    }

    // MARK: - Join Family (Child)

    /// Child enters a pairing code → look up the matching family → add child UID.
    func joinFamily(childId: String, pairingCode: String) async throws -> FamilyModel {
        // Query for the family with this code
        let snapshot = try await familiesRef
            .whereField("pairingCode", isEqualTo: pairingCode.uppercased())
            .limit(to: 1)
            .getDocuments()

        guard let doc = snapshot.documents.first,
              var family = FamilyModel.from(dictionary: doc.data(), id: doc.documentID) else {
            throw DriveArmorError.invalidPairingCode
        }

        // Prevent duplicate additions
        guard !family.childIds.contains(childId) else { return family }

        // Append child to the family
        family.childIds.append(childId)
        try await familiesRef.document(family.id).updateData([
            "childIds": FieldValue.arrayUnion([childId])
        ])

        // Link the child's profile
        try await usersRef.document(childId).updateData(["familyId": family.id])

        return family
    }

    // MARK: - Fetch

    func fetchFamily(id: String) async throws -> FamilyModel {
        let doc = try await familiesRef.document(id).getDocument()
        guard let data = doc.data(),
              let family = FamilyModel.from(dictionary: data, id: id) else {
            throw DriveArmorError.familyNotFound
        }
        return family
    }

    /// Fetch display-friendly child profiles for the given UIDs.
    func fetchChildProfiles(childIds: [String]) async throws -> [UserModel] {
        guard !childIds.isEmpty else { return [] }
        var children: [UserModel] = []
        for uid in childIds {
            let doc = try await usersRef.document(uid).getDocument()
            if let data = doc.data(), let user = UserModel.from(dictionary: data, uid: uid) {
                children.append(user)
            }
        }
        return children
    }

    // MARK: - Regenerate Pairing Code

    func regeneratePairingCode(familyId: String) async throws -> String {
        let newCode = FamilyModel.generatePairingCode()
        try await familiesRef.document(familyId).updateData(["pairingCode": newCode])
        return newCode
    }
}
