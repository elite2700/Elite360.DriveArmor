// GamificationModel.swift
// Elite360.DriveArmor
//
// Tracks badges, streaks, and reward points for child drivers.
// Stored at /families/{familyId}/gamification/{childId}.

import Foundation

// MARK: - Badge

struct Badge: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String          // SF Symbol name
    let description: String
    let earnedAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        icon: String,
        description: String,
        earnedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.earnedAt = earnedAt
    }

    var asDictionary: [String: Any] {
        [
            "id": id,
            "name": name,
            "icon": icon,
            "description": description,
            "earnedAt": earnedAt
        ]
    }

    static func from(dictionary dict: [String: Any]) -> Badge? {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let icon = dict["icon"] as? String else { return nil }
        return Badge(
            id: id,
            name: name,
            icon: icon,
            description: dict["description"] as? String ?? "",
            earnedAt: dict["earnedAt"] as? Date ?? Date()
        )
    }
}

// MARK: - Badge Definitions

enum BadgeType: String, CaseIterable {
    case firstDrive        = "first_drive"
    case safeWeek          = "safe_week"
    case safeMonth         = "safe_month"
    case noDistractions10  = "no_distractions_10"
    case speedCompliant50  = "speed_compliant_50"
    case safeModeChampion  = "safe_mode_champion"
    case streakMaster      = "streak_master"

    var name: String {
        switch self {
        case .firstDrive:        return "First Drive"
        case .safeWeek:          return "Safe Week"
        case .safeMonth:         return "Safe Month"
        case .noDistractions10:  return "Distraction Free x10"
        case .speedCompliant50:  return "Speed Compliant x50"
        case .safeModeChampion:  return "Safe Mode Champion"
        case .streakMaster:      return "Streak Master"
        }
    }

    var icon: String {
        switch self {
        case .firstDrive:        return "car.circle.fill"
        case .safeWeek:          return "shield.checkered"
        case .safeMonth:         return "calendar.badge.checkmark"
        case .noDistractions10:  return "eye.slash.circle.fill"
        case .speedCompliant50:  return "gauge.with.dots.needle.bottom.50percent"
        case .safeModeChampion:  return "lock.shield.fill"
        case .streakMaster:      return "flame.fill"
        }
    }

    var description: String {
        switch self {
        case .firstDrive:        return "Completed your first monitored drive."
        case .safeWeek:          return "7 consecutive days of safe driving."
        case .safeMonth:         return "30 consecutive days of safe driving."
        case .noDistractions10:  return "10 drives with zero distraction attempts."
        case .speedCompliant50:  return "50 drives under the speed threshold."
        case .safeModeChampion:  return "Never overrode safe mode in 20 drives."
        case .streakMaster:      return "Maintained a 14-day safe driving streak."
        }
    }
}

// MARK: - Gamification Profile

struct GamificationProfile: Codable, Equatable {
    let childId: String
    var totalPoints: Int
    var currentStreak: Int        // consecutive safe-driving days
    var longestStreak: Int
    var totalDrives: Int
    var safeDrives: Int           // drives with 0 distraction attempts
    var badges: [Badge]
    var lastDriveDate: Date?

    init(
        childId: String,
        totalPoints: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalDrives: Int = 0,
        safeDrives: Int = 0,
        badges: [Badge] = [],
        lastDriveDate: Date? = nil
    ) {
        self.childId = childId
        self.totalPoints = totalPoints
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalDrives = totalDrives
        self.safeDrives = safeDrives
        self.badges = badges
        self.lastDriveDate = lastDriveDate
    }

    var asDictionary: [String: Any] {
        var dict: [String: Any] = [
            "childId": childId,
            "totalPoints": totalPoints,
            "currentStreak": currentStreak,
            "longestStreak": longestStreak,
            "totalDrives": totalDrives,
            "safeDrives": safeDrives,
            "badges": badges.map { $0.asDictionary }
        ]
        if let lastDriveDate { dict["lastDriveDate"] = lastDriveDate }
        return dict
    }

    static func from(dictionary dict: [String: Any], childId: String) -> GamificationProfile {
        let badgesDicts = dict["badges"] as? [[String: Any]] ?? []
        return GamificationProfile(
            childId: childId,
            totalPoints: dict["totalPoints"] as? Int ?? 0,
            currentStreak: dict["currentStreak"] as? Int ?? 0,
            longestStreak: dict["longestStreak"] as? Int ?? 0,
            totalDrives: dict["totalDrives"] as? Int ?? 0,
            safeDrives: dict["safeDrives"] as? Int ?? 0,
            badges: badgesDicts.compactMap { Badge.from(dictionary: $0) },
            lastDriveDate: dict["lastDriveDate"] as? Date
        )
    }
}

// MARK: - Schedule Model

struct SafeModeSchedule: Codable, Identifiable, Equatable {
    let id: String
    var name: String              // e.g. "School Commute"
    var startHour: Int            // 0-23
    var startMinute: Int          // 0-59
    var endHour: Int
    var endMinute: Int
    var daysOfWeek: [Int]         // 1=Sun...7=Sat
    var isEnabled: Bool
    let createdBy: String         // parent UID

    init(
        id: String = UUID().uuidString,
        name: String,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        daysOfWeek: [Int] = [2, 3, 4, 5, 6], // Mon-Fri by default
        isEnabled: Bool = true,
        createdBy: String
    ) {
        self.id = id
        self.name = name
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.daysOfWeek = daysOfWeek
        self.isEnabled = isEnabled
        self.createdBy = createdBy
    }

    var startTimeString: String {
        String(format: "%02d:%02d", startHour, startMinute)
    }

    var endTimeString: String {
        String(format: "%02d:%02d", endHour, endMinute)
    }

    var asDictionary: [String: Any] {
        [
            "id": id,
            "name": name,
            "startHour": startHour,
            "startMinute": startMinute,
            "endHour": endHour,
            "endMinute": endMinute,
            "daysOfWeek": daysOfWeek,
            "isEnabled": isEnabled,
            "createdBy": createdBy
        ]
    }

    static func from(dictionary dict: [String: Any], id: String) -> SafeModeSchedule? {
        guard let name = dict["name"] as? String,
              let createdBy = dict["createdBy"] as? String else { return nil }
        return SafeModeSchedule(
            id: id,
            name: name,
            startHour: dict["startHour"] as? Int ?? 0,
            startMinute: dict["startMinute"] as? Int ?? 0,
            endHour: dict["endHour"] as? Int ?? 0,
            endMinute: dict["endMinute"] as? Int ?? 0,
            daysOfWeek: dict["daysOfWeek"] as? [Int] ?? [],
            isEnabled: dict["isEnabled"] as? Bool ?? true,
            createdBy: createdBy
        )
    }
}

// MARK: - Rule Change Request (Teen → Parent)

struct RuleChangeRequest: Codable, Identifiable, Equatable {
    let id: String
    let childId: String
    let requestType: String       // e.g. "speed_threshold", "schedule_change", "geofence_removal"
    let message: String
    var status: OverrideRequestStatus
    let createdAt: Date
    var respondedAt: Date?

    init(
        id: String = UUID().uuidString,
        childId: String,
        requestType: String,
        message: String,
        status: OverrideRequestStatus = .pending,
        createdAt: Date = Date(),
        respondedAt: Date? = nil
    ) {
        self.id = id
        self.childId = childId
        self.requestType = requestType
        self.message = message
        self.status = status
        self.createdAt = createdAt
        self.respondedAt = respondedAt
    }

    var asDictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "childId": childId,
            "requestType": requestType,
            "message": message,
            "status": status.rawValue,
            "createdAt": createdAt
        ]
        if let respondedAt { dict["respondedAt"] = respondedAt }
        return dict
    }

    static func from(dictionary dict: [String: Any], id: String) -> RuleChangeRequest? {
        guard let childId = dict["childId"] as? String,
              let statusRaw = dict["status"] as? String,
              let status = OverrideRequestStatus(rawValue: statusRaw) else { return nil }
        return RuleChangeRequest(
            id: id,
            childId: childId,
            requestType: dict["requestType"] as? String ?? "",
            message: dict["message"] as? String ?? "",
            status: status,
            createdAt: dict["createdAt"] as? Date ?? Date(),
            respondedAt: dict["respondedAt"] as? Date
        )
    }
}
