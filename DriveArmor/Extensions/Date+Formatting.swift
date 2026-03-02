// Date+Formatting.swift
// Elite360.DriveArmor
//
// Convenience formatters used across the app.

import Foundation

extension Date {
    /// e.g. "2 min ago", "3 hours ago"
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// e.g. "Mar 2, 2026 at 3:15 PM"
    var mediumString: String {
        formatted(date: .abbreviated, time: .shortened)
    }

    /// e.g. "3:15 PM"
    var timeString: String {
        formatted(date: .omitted, time: .shortened)
    }
}
