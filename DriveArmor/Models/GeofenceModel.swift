// GeofenceModel.swift
// Elite360.DriveArmor
//
// Defines a geographic zone set by the parent. Alerts fire when the child
// enters or exits the zone. Stored at /families/{familyId}/geofences/{id}.

import Foundation
import CoreLocation

struct GeofenceModel: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var latitude: Double
    var longitude: Double
    var radiusMeters: Double      // Default 200 m
    var notifyOnEntry: Bool
    var notifyOnExit: Bool
    var isEnabled: Bool
    let createdBy: String         // parent UID
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double = 200,
        notifyOnEntry: Bool = true,
        notifyOnExit: Bool = true,
        isEnabled: Bool = true,
        createdBy: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radiusMeters = radiusMeters
        self.notifyOnEntry = notifyOnEntry
        self.notifyOnExit = notifyOnExit
        self.isEnabled = isEnabled
        self.createdBy = createdBy
        self.createdAt = createdAt
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var region: CLCircularRegion {
        let r = CLCircularRegion(center: coordinate, radius: radiusMeters, identifier: id)
        r.notifyOnEntry = notifyOnEntry
        r.notifyOnExit = notifyOnExit
        return r
    }

    var asDictionary: [String: Any] {
        [
            "id": id,
            "name": name,
            "latitude": latitude,
            "longitude": longitude,
            "radiusMeters": radiusMeters,
            "notifyOnEntry": notifyOnEntry,
            "notifyOnExit": notifyOnExit,
            "isEnabled": isEnabled,
            "createdBy": createdBy,
            "createdAt": createdAt
        ]
    }

    static func from(dictionary dict: [String: Any], id: String) -> GeofenceModel? {
        guard let name = dict["name"] as? String,
              let lat = dict["latitude"] as? Double,
              let lon = dict["longitude"] as? Double,
              let createdBy = dict["createdBy"] as? String else { return nil }
        return GeofenceModel(
            id: id,
            name: name,
            latitude: lat,
            longitude: lon,
            radiusMeters: dict["radiusMeters"] as? Double ?? 200,
            notifyOnEntry: dict["notifyOnEntry"] as? Bool ?? true,
            notifyOnExit: dict["notifyOnExit"] as? Bool ?? true,
            isEnabled: dict["isEnabled"] as? Bool ?? true,
            createdBy: createdBy,
            createdAt: dict["createdAt"] as? Date ?? Date()
        )
    }
}
