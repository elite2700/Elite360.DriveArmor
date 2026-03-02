// CommandService.swift
// Elite360.DriveArmor
//
// Manages real-time command documents at /families/{familyId}/commands/{commandId}.
// Parents create commands; Child devices listen and update status.

import Foundation
import Combine
import FirebaseFirestore

final class CommandService {

    private let db = Firestore.firestore()

    // MARK: - References

    private func commandsRef(familyId: String) -> CollectionReference {
        db.collection("families").document(familyId).collection("commands")
    }

    // MARK: - Parent: Send Command

    /// Parent issues a new command targeting a child device.
    func sendCommand(
        familyId: String,
        type: CommandType,
        targetChildId: String,
        issuedBy: String,
        params: CommandParams? = nil
    ) async throws -> CommandModel {
        let command = CommandModel(
            type: type,
            targetChildId: targetChildId,
            issuedBy: issuedBy,
            params: params
        )
        try await commandsRef(familyId: familyId)
            .document(command.id)
            .setData(command.asDictionary)
        return command
    }

    // MARK: - Child: Listen for Pending Commands

    /// Returns a Combine publisher that emits whenever a new pending command
    /// targeting this child appears in Firestore.
    func listenForCommands(
        familyId: String,
        childId: String
    ) -> AnyPublisher<[CommandModel], Error> {
        let subject = PassthroughSubject<[CommandModel], Error>()

        let listener = commandsRef(familyId: familyId)
            .whereField("targetChildId", isEqualTo: childId)
            .whereField("status", isEqualTo: CommandStatus.pending.rawValue)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                    return
                }
                let commands = snapshot?.documents.compactMap { doc in
                    CommandModel.from(dictionary: doc.data(), id: doc.documentID)
                } ?? []
                subject.send(commands)
            }

        // Keep listener alive as long as there are subscribers
        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }

    // MARK: - Child: Update Command Status

    /// Child acknowledges or completes a command.
    func updateCommandStatus(
        familyId: String,
        commandId: String,
        status: CommandStatus
    ) async throws {
        try await commandsRef(familyId: familyId)
            .document(commandId)
            .updateData([
                "status": status.rawValue,
                "updatedAt": Date()
            ])
    }

    // MARK: - Parent: Fetch Command History

    func fetchRecentCommands(familyId: String, limit: Int = 20) async throws -> [CommandModel] {
        let snapshot = try await commandsRef(familyId: familyId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            CommandModel.from(dictionary: doc.data(), id: doc.documentID)
        }
    }
}
