// GamificationService.swift
// Elite360.DriveArmor
//
// Tracks safe-driving streaks, awards badges, and manages points.
// Reads/writes /families/{familyId}/gamification/{childId}.

import Foundation
import FirebaseFirestore

final class GamificationService {

    private let db = Firestore.firestore()

    private func profileRef(familyId: String, childId: String) -> DocumentReference {
        db.collection("families").document(familyId)
            .collection("gamification").document(childId)
    }

    // MARK: - Fetch

    func fetchProfile(familyId: String, childId: String) async throws -> GamificationProfile {
        let doc = try await profileRef(familyId: familyId, childId: childId).getDocument()
        guard let data = doc.data() else {
            return GamificationProfile(childId: childId)
        }
        return GamificationProfile.from(dictionary: data, childId: childId)
    }

    // MARK: - Save

    func saveProfile(familyId: String, profile: GamificationProfile) async throws {
        try await profileRef(familyId: familyId, childId: profile.childId)
            .setData(profile.asDictionary, merge: true)
    }

    // MARK: - Record Drive Completion

    /// Called when a driving session ends. Updates streaks, points, and checks for new badges.
    func recordDriveCompletion(
        familyId: String,
        childId: String,
        log: DrivingLog
    ) async throws -> GamificationProfile {
        var profile = try await fetchProfile(familyId: familyId, childId: childId)

        profile.totalDrives += 1
        let isSafe = log.distractionAttempts == 0

        if isSafe {
            profile.safeDrives += 1
            profile.totalPoints += 10 // 10 points per safe drive
        } else {
            profile.totalPoints += 2  // 2 points just for driving with the app
        }

        // Streak logic
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let lastDrive = profile.lastDriveDate {
            let lastDay = calendar.startOfDay(for: lastDrive)
            let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if daysBetween == 1 && isSafe {
                profile.currentStreak += 1
            } else if daysBetween > 1 || !isSafe {
                profile.currentStreak = isSafe ? 1 : 0
            }
            // else daysBetween == 0, multiple drives same day — keep streak
        } else {
            profile.currentStreak = isSafe ? 1 : 0
        }

        if profile.currentStreak > profile.longestStreak {
            profile.longestStreak = profile.currentStreak
        }
        profile.lastDriveDate = Date()

        // Check for new badges
        let newBadges = evaluateBadges(for: profile)
        profile.badges.append(contentsOf: newBadges)
        if !newBadges.isEmpty {
            profile.totalPoints += newBadges.count * 50 // 50 bonus points per badge
        }

        try await saveProfile(familyId: familyId, profile: profile)
        return profile
    }

    // MARK: - Badge Evaluation

    private func evaluateBadges(for profile: GamificationProfile) -> [Badge] {
        let earnedIds = Set(profile.badges.map(\.id))
        var newBadges: [Badge] = []

        let checks: [(BadgeType, Bool)] = [
            (.firstDrive, profile.totalDrives >= 1),
            (.safeWeek, profile.currentStreak >= 7),
            (.safeMonth, profile.currentStreak >= 30),
            (.noDistractions10, profile.safeDrives >= 10),
            (.speedCompliant50, profile.safeDrives >= 50),
            (.safeModeChampion, profile.safeDrives >= 20 && profile.totalDrives >= 20),
            (.streakMaster, profile.longestStreak >= 14),
        ]

        for (badgeType, earned) in checks {
            if earned && !earnedIds.contains(badgeType.rawValue) {
                newBadges.append(Badge(
                    id: badgeType.rawValue,
                    name: badgeType.name,
                    icon: badgeType.icon,
                    description: badgeType.description
                ))
            }
        }

        return newBadges
    }
}
