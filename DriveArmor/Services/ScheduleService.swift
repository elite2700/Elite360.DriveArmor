// ScheduleService.swift
// Elite360.DriveArmor
//
// Manages safe-mode schedules at /families/{familyId}/schedules/{id}.
// Parent creates schedules; child app checks them to auto-activate safe mode.

import Foundation
import Combine
import FirebaseFirestore

final class ScheduleService: ObservableObject {

    // MARK: - Published

    @Published var schedules: [SafeModeSchedule] = []

    // MARK: - Private

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private func schedulesRef(familyId: String) -> CollectionReference {
        db.collection("families").document(familyId).collection("schedules")
    }

    // MARK: - CRUD

    func createSchedule(familyId: String, schedule: SafeModeSchedule) async throws {
        try await schedulesRef(familyId: familyId)
            .document(schedule.id).setData(schedule.asDictionary)
    }

    func updateSchedule(familyId: String, schedule: SafeModeSchedule) async throws {
        try await schedulesRef(familyId: familyId)
            .document(schedule.id).setData(schedule.asDictionary, merge: true)
    }

    func deleteSchedule(familyId: String, scheduleId: String) async throws {
        try await schedulesRef(familyId: familyId).document(scheduleId).delete()
    }

    // MARK: - Listen

    func listenToSchedules(familyId: String) {
        listener?.remove()
        listener = schedulesRef(familyId: familyId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                let items = documents.compactMap { doc in
                    SafeModeSchedule.from(dictionary: doc.data(), id: doc.documentID)
                }
                DispatchQueue.main.async {
                    self?.schedules = items
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Check Active

    /// Returns true if any enabled schedule covers the current date/time.
    func isScheduleActiveNow() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now) // 1=Sun
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let nowMinutes = hour * 60 + minute

        return schedules.contains { schedule in
            guard schedule.isEnabled, schedule.daysOfWeek.contains(weekday) else { return false }
            let start = schedule.startHour * 60 + schedule.startMinute
            let end = schedule.endHour * 60 + schedule.endMinute
            if start <= end {
                return nowMinutes >= start && nowMinutes < end
            } else {
                // Wraps past midnight
                return nowMinutes >= start || nowMinutes < end
            }
        }
    }
}
