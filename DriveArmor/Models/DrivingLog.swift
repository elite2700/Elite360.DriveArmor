// DrivingLog.swift
// Elite360.DriveArmor
//
// Represents a completed driving session, stored at
// /families/{familyId}/drivingLogs/{logId}.
// Created when the child's driving session ends; displayed in parent reports.

import Foundation

struct DrivingLog: Codable, Identifiable, Equatable {
    let id: String
    let childId: String
    var startTime: Date
    var endTime: Date?
    var maxSpeed: Double            // mph
    var averageSpeed: Double        // mph
    var distanceKm: Double
    var distractionAttempts: Int    // Times the child tried to use blocked features
    var safeModeWasActive: Bool

    init(
        id: String = UUID().uuidString,
        childId: String,
        startTime: Date = Date(),
        endTime: Date? = nil,
        maxSpeed: Double = 0,
        averageSpeed: Double = 0,
        distanceKm: Double = 0,
        distractionAttempts: Int = 0,
        safeModeWasActive: Bool = false
    ) {
        self.id = id
        self.childId = childId
        self.startTime = startTime
        self.endTime = endTime
        self.maxSpeed = maxSpeed
        self.averageSpeed = averageSpeed
        self.distanceKm = distanceKm
        self.distractionAttempts = distractionAttempts
        self.safeModeWasActive = safeModeWasActive
    }

    /// Duration of the driving session in seconds (nil if still active).
    var durationSeconds: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    // MARK: - Firestore Helpers

    var asDictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "childId": childId,
            "startTime": startTime,
            "maxSpeed": maxSpeed,
            "averageSpeed": averageSpeed,
            "distanceKm": distanceKm,
            "distractionAttempts": distractionAttempts,
            "safeModeWasActive": safeModeWasActive
        ]
        if let endTime = endTime { dict["endTime"] = endTime }
        return dict
    }

    static func from(dictionary dict: [String: Any], id: String) -> DrivingLog? {
        guard let childId = dict["childId"] as? String else { return nil }
        return DrivingLog(
            id: id,
            childId: childId,
            startTime: dict["startTime"] as? Date ?? Date(),
            endTime: dict["endTime"] as? Date,
            maxSpeed: dict["maxSpeed"] as? Double ?? 0,
            averageSpeed: dict["averageSpeed"] as? Double ?? 0,
            distanceKm: dict["distanceKm"] as? Double ?? 0,
            distractionAttempts: dict["distractionAttempts"] as? Int ?? 0,
            safeModeWasActive: dict["safeModeWasActive"] as? Bool ?? false
        )
    }
}
