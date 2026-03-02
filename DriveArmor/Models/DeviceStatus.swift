// DeviceStatus.swift
// Elite360.DriveArmor
//
// Represents the real-time status of a child's device, stored at
// /families/{familyId}/deviceStatus/{childId}.
// The child app writes updates; the parent dashboard subscribes.

import Foundation

struct DeviceStatus: Codable, Identifiable, Equatable {
    /// The child UID (also the Firestore document ID).
    var id: String { childId }

    let childId: String
    var drivingDetected: Bool
    var safeModeActive: Bool
    var currentSpeed: Double        // mph
    var lastLatitude: Double?
    var lastLongitude: Double?
    var batteryLevel: Double?       // 0.0–1.0
    var lastUpdated: Date

    init(
        childId: String,
        drivingDetected: Bool = false,
        safeModeActive: Bool = false,
        currentSpeed: Double = 0,
        lastLatitude: Double? = nil,
        lastLongitude: Double? = nil,
        batteryLevel: Double? = nil,
        lastUpdated: Date = Date()
    ) {
        self.childId = childId
        self.drivingDetected = drivingDetected
        self.safeModeActive = safeModeActive
        self.currentSpeed = currentSpeed
        self.lastLatitude = lastLatitude
        self.lastLongitude = lastLongitude
        self.batteryLevel = batteryLevel
        self.lastUpdated = lastUpdated
    }

    // MARK: - Firestore Helpers

    var asDictionary: [String: Any] {
        var dict: [String: Any] = [
            "childId": childId,
            "drivingDetected": drivingDetected,
            "safeModeActive": safeModeActive,
            "currentSpeed": currentSpeed,
            "lastUpdated": lastUpdated
        ]
        if let lat = lastLatitude { dict["lastLatitude"] = lat }
        if let lon = lastLongitude { dict["lastLongitude"] = lon }
        if let battery = batteryLevel { dict["batteryLevel"] = battery }
        return dict
    }

    static func from(dictionary dict: [String: Any], childId: String) -> DeviceStatus? {
        return DeviceStatus(
            childId: childId,
            drivingDetected: dict["drivingDetected"] as? Bool ?? false,
            safeModeActive: dict["safeModeActive"] as? Bool ?? false,
            currentSpeed: dict["currentSpeed"] as? Double ?? 0,
            lastLatitude: dict["lastLatitude"] as? Double,
            lastLongitude: dict["lastLongitude"] as? Double,
            batteryLevel: dict["batteryLevel"] as? Double,
            lastUpdated: dict["lastUpdated"] as? Date ?? Date()
        )
    }
}
