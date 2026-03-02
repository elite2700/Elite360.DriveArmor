// OverrideRequestService.swift
// Elite360.DriveArmor
//
// Manages override requests at /families/{familyId}/overrideRequests/{id}
// and rule change requests at /families/{familyId}/ruleChangeRequests/{id}.

import Foundation
import Combine
import FirebaseFirestore

final class OverrideRequestService: ObservableObject {

    private let db = Firestore.firestore()

    private func overrideRef(familyId: String) -> CollectionReference {
        db.collection("families").document(familyId).collection("overrideRequests")
    }

    private func ruleChangeRef(familyId: String) -> CollectionReference {
        db.collection("families").document(familyId).collection("ruleChangeRequests")
    }

    // MARK: - Override Requests

    /// Child sends a request to override safe mode.
    func sendOverrideRequest(
        familyId: String,
        childId: String,
        reason: String
    ) async throws -> OverrideRequest {
        let request = OverrideRequest(childId: childId, reason: reason)
        try await overrideRef(familyId: familyId)
            .document(request.id).setData(request.asDictionary)
        return request
    }

    /// Parent responds to an override request.
    func respondToOverrideRequest(
        familyId: String,
        requestId: String,
        approved: Bool
    ) async throws {
        try await overrideRef(familyId: familyId).document(requestId).updateData([
            "status": approved ? OverrideRequestStatus.approved.rawValue : OverrideRequestStatus.denied.rawValue,
            "respondedAt": Date()
        ])
    }

    /// Listen for pending override requests (parent view).
    func listenForPendingRequests(
        familyId: String
    ) -> AnyPublisher<[OverrideRequest], Error> {
        let subject = PassthroughSubject<[OverrideRequest], Error>()
        let listener = overrideRef(familyId: familyId)
            .whereField("status", isEqualTo: OverrideRequestStatus.pending.rawValue)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error { subject.send(completion: .failure(error)); return }
                let requests = snapshot?.documents.compactMap { doc in
                    OverrideRequest.from(dictionary: doc.data(), id: doc.documentID)
                } ?? []
                subject.send(requests)
            }
        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }

    /// Listen for responses to the child's requests.
    func listenForMyRequests(
        familyId: String,
        childId: String
    ) -> AnyPublisher<[OverrideRequest], Error> {
        let subject = PassthroughSubject<[OverrideRequest], Error>()
        let listener = overrideRef(familyId: familyId)
            .whereField("childId", isEqualTo: childId)
            .order(by: "createdAt", descending: true)
            .limit(to: 5)
            .addSnapshotListener { snapshot, error in
                if let error { subject.send(completion: .failure(error)); return }
                let requests = snapshot?.documents.compactMap { doc in
                    OverrideRequest.from(dictionary: doc.data(), id: doc.documentID)
                } ?? []
                subject.send(requests)
            }
        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }

    // MARK: - Rule Change Requests

    /// Child sends a request to change a family rule.
    func sendRuleChangeRequest(
        familyId: String,
        childId: String,
        requestType: String,
        message: String
    ) async throws -> RuleChangeRequest {
        let request = RuleChangeRequest(
            childId: childId,
            requestType: requestType,
            message: message
        )
        try await ruleChangeRef(familyId: familyId)
            .document(request.id).setData(request.asDictionary)
        return request
    }

    /// Parent responds to a rule change request.
    func respondToRuleChangeRequest(
        familyId: String,
        requestId: String,
        approved: Bool
    ) async throws {
        try await ruleChangeRef(familyId: familyId).document(requestId).updateData([
            "status": approved ? OverrideRequestStatus.approved.rawValue : OverrideRequestStatus.denied.rawValue,
            "respondedAt": Date()
        ])
    }

    /// Listen for pending rule change requests (parent view).
    func listenForPendingRuleChanges(
        familyId: String
    ) -> AnyPublisher<[RuleChangeRequest], Error> {
        let subject = PassthroughSubject<[RuleChangeRequest], Error>()
        let listener = ruleChangeRef(familyId: familyId)
            .whereField("status", isEqualTo: OverrideRequestStatus.pending.rawValue)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error { subject.send(completion: .failure(error)); return }
                let requests = snapshot?.documents.compactMap { doc in
                    RuleChangeRequest.from(dictionary: doc.data(), id: doc.documentID)
                } ?? []
                subject.send(requests)
            }
        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }
}
