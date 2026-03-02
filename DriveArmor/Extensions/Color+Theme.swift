// Color+Theme.swift
// Elite360.DriveArmor
//
// App color palette. Centralises brand colours so views stay consistent.

import SwiftUI

extension Color {
    // MARK: - Brand
    static let driveArmorBlue   = Color(red: 0.20, green: 0.45, blue: 0.90)
    static let driveArmorOrange = Color(red: 0.95, green: 0.55, blue: 0.15)
    static let driveArmorGreen  = Color(red: 0.25, green: 0.78, blue: 0.45)

    // MARK: - Semantic
    static let safeModeActive   = driveArmorOrange
    static let drivingDetected  = driveArmorBlue
    static let allClear         = driveArmorGreen
}

extension ShapeStyle where Self == Color {
    static var accent: Color { .driveArmorBlue }
}
