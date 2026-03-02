// CommandModel.swift
// Elite360.DriveArmor
//
// Represents a parent → child command stored at
// /families/{familyId}/commands/{commandId}.

import Foundation

/// Types of commands a parent can issue.
enum CommandType: String, Codable {
    case enableSafeMode
    case disableSafeMode
    case overrideNotification   // Notify parent that child overrode safe mode
    case speedAlert             // Alert parent that child exceeded speed threshold
    case scheduleTriggered      // System command when a schedule window opens/closes
    case geofenceAlert          // Alert parent about geofence entry/exit
}

/// Lifecycle status of a command.
enum CommandStatus: String, Codable {
    case pending        // Written by parent, not yet seen by child
    case acknowledged   // Child device received and is processing
    case completed      // Child confirmed execution
    case failed         // Child could not execute
}

struct CommandModel: Codable, Identifiable, Equatable {
    let id: String
    let type: CommandType
    var status: CommandStatus
    let targetChildId: String   // UID of the child device
    let issuedBy: String        // UID of the parent
    var params: CommandParams?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        type: CommandType,
        status: CommandStatus = .pending,
        targetChildId: String,
        issuedBy: String,
        params: CommandParams? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.status = status
        self.targetChildId = targetChildId
        self.issuedBy = issuedBy
        self.params = params
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Firestore Helpers

    var asDictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "type": type.rawValue,
            "status": status.rawValue,
            "targetChildId": targetChildId,
            "issuedBy": issuedBy,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
        if let params = params {
            dict["params"] = params.asDictionary
        }
        return dict
    }

    static func from(dictionary dict: [String: Any], id: String) -> CommandModel? {
        guard let typeRaw = dict["type"] as? String,
              let type = CommandType(rawValue: typeRaw),
              let statusRaw = dict["status"] as? String,
              let status = CommandStatus(rawValue: statusRaw),
              let targetChildId = dict["targetChildId"] as? String,
              let issuedBy = dict["issuedBy"] as? String else { return nil }

        let paramsDict = dict["params"] as? [String: Any]
        let params = paramsDict.flatMap { CommandParams.from(dictionary: $0) }

        return CommandModel(
            id: id,
            type: type,
            status: status,
            targetChildId: targetChildId,
            issuedBy: issuedBy,
            params: params,
            createdAt: dict["createdAt"] as? Date ?? Date(),
            updatedAt: dict["updatedAt"] as? Date ?? Date()
        )
    }
}

// MARK: - Command Parameters

struct CommandParams: Codable, Equatable {
    var durationMinutes: Int?   // How long safe mode should last (nil = indefinite)
    var reason: String?         // Optional message from parent

    var asDictionary: [String: Any] {
        var dict = [String: Any]()
        if let dur = durationMinutes { dict["durationMinutes"] = dur }
        if let reason = reason { dict["reason"] = reason }
        return dict
    }

    static func from(dictionary dict: [String: Any]) -> CommandParams? {
        return CommandParams(
            durationMinutes: dict["durationMinutes"] as? Int,
            reason: dict["reason"] as? String
        )
    }
}
