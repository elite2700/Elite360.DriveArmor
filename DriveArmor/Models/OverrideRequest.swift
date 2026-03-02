// OverrideRequest.swift
// Elite360.DriveArmor
//
// Model for a child's request to override safe mode.
// Stored at /families/{familyId}/overrideRequests/{requestId}.

import Foundation

enum OverrideRequestStatus: String, Codable {
    case pending
    case approved
    case denied
}

struct OverrideRequest: Codable, Identifiable, Equatable {
    let id: String
    let childId: String
    let reason: String
    var status: OverrideRequestStatus
    let createdAt: Date
    var respondedAt: Date?

    init(
        id: String = UUID().uuidString,
        childId: String,
        reason: String = "",
        status: OverrideRequestStatus = .pending,
        createdAt: Date = Date(),
        respondedAt: Date? = nil
    ) {
        self.id = id
        self.childId = childId
        self.reason = reason
        self.status = status
        self.createdAt = createdAt
        self.respondedAt = respondedAt
    }

    var asDictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "childId": childId,
            "reason": reason,
            "status": status.rawValue,
            "createdAt": createdAt
        ]
        if let respondedAt { dict["respondedAt"] = respondedAt }
        return dict
    }

    static func from(dictionary dict: [String: Any], id: String) -> OverrideRequest? {
        guard let childId = dict["childId"] as? String,
              let statusRaw = dict["status"] as? String,
              let status = OverrideRequestStatus(rawValue: statusRaw) else { return nil }
        return OverrideRequest(
            id: id,
            childId: childId,
            reason: dict["reason"] as? String ?? "",
            status: status,
            createdAt: dict["createdAt"] as? Date ?? Date(),
            respondedAt: dict["respondedAt"] as? Date
        )
    }
}
