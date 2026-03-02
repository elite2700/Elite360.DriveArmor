// DeviceStatusService.swift
// Elite360.DriveArmor
//
// Reads and writes real-time device status documents at
// /families/{familyId}/deviceStatus/{childId}.
// The child writes; the parent subscribes.

import Foundation
import Combine
import FirebaseFirestore

final class DeviceStatusService {

    private let db = Firestore.firestore()

    private func statusRef(familyId: String, childId: String) -> DocumentReference {
        db.collection("families")
            .document(familyId)
            .collection("deviceStatus")
            .document(childId)
    }

    // MARK: - Child: Write Status

    /// Called periodically by child device to push its current state.
    func updateStatus(familyId: String, status: DeviceStatus) async throws {
        try await statusRef(familyId: familyId, childId: status.childId)
            .setData(status.asDictionary, merge: true)
    }

    // MARK: - Parent: Subscribe to Child Status

    /// Returns a Combine publisher that emits the latest DeviceStatus for a child.
    func listenToChildStatus(
        familyId: String,
        childId: String
    ) -> AnyPublisher<DeviceStatus?, Error> {
        let subject = PassthroughSubject<DeviceStatus?, Error>()

        let listener = statusRef(familyId: familyId, childId: childId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                    return
                }
                guard let data = snapshot?.data() else {
                    subject.send(nil)
                    return
                }
                subject.send(DeviceStatus.from(dictionary: data, childId: childId))
            }

        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }

    // MARK: - Parent: Fetch Single Status

    func fetchStatus(familyId: String, childId: String) async throws -> DeviceStatus? {
        let doc = try await statusRef(familyId: familyId, childId: childId).getDocument()
        guard let data = doc.data() else { return nil }
        return DeviceStatus.from(dictionary: data, childId: childId)
    }

    // MARK: - Driving Logs

    private func logsRef(familyId: String) -> CollectionReference {
        db.collection("families").document(familyId).collection("drivingLogs")
    }

    /// Save a completed driving log.
    func saveDrivingLog(familyId: String, log: DrivingLog) async throws {
        try await logsRef(familyId: familyId)
            .document(log.id)
            .setData(log.asDictionary)
    }

    /// Fetch recent driving logs for a child (for parental reports).
    func fetchDrivingLogs(
        familyId: String,
        childId: String,
        limit: Int = 50
    ) async throws -> [DrivingLog] {
        let snapshot = try await logsRef(familyId: familyId)
            .whereField("childId", isEqualTo: childId)
            .order(by: "startTime", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            DrivingLog.from(dictionary: doc.data(), id: doc.documentID)
        }
    }
}
