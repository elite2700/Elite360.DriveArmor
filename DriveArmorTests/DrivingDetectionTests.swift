// DrivingDetectionTests.swift
// DriveArmorTests
//
// Unit tests for driving detection thresholds and DrivingLog model.

import XCTest
@testable import DriveArmor

final class DrivingDetectionTests: XCTestCase {

    // MARK: - Speed Threshold

    func testSpeedThreshold() {
        XCTAssertEqual(DrivingDetectionService.speedThresholdMPH, 20.0,
                       "Threshold should be 20 mph per blueprint spec")
    }

    // MARK: - DrivingLog Model

    func testDrivingLogDuration() {
        let start = Date()
        let end = start.addingTimeInterval(1800) // 30 minutes
        let log = DrivingLog(
            childId: "child-1",
            startTime: start,
            endTime: end,
            maxSpeed: 45,
            averageSpeed: 32,
            distanceKm: 12.5
        )

        XCTAssertEqual(log.durationSeconds, 1800, accuracy: 0.01)
    }

    func testDrivingLogDurationNilWhenActive() {
        let log = DrivingLog(childId: "child-1", startTime: Date())
        XCTAssertNil(log.durationSeconds, "Duration should be nil for an active session")
    }

    func testDrivingLogToDictionary() {
        let log = DrivingLog(
            id: "log-001",
            childId: "child-1",
            maxSpeed: 55,
            averageSpeed: 40,
            distanceKm: 8.3,
            distractionAttempts: 2,
            safeModeWasActive: true
        )
        let dict = log.asDictionary

        XCTAssertEqual(dict["childId"] as? String, "child-1")
        XCTAssertEqual(dict["maxSpeed"] as? Double, 55)
        XCTAssertEqual(dict["distractionAttempts"] as? Int, 2)
        XCTAssertEqual(dict["safeModeWasActive"] as? Bool, true)
    }

    func testDrivingLogFromDictionary() {
        let dict: [String: Any] = [
            "childId": "child-2",
            "startTime": Date(),
            "maxSpeed": 65.0,
            "averageSpeed": 50.0,
            "distanceKm": 25.0,
            "distractionAttempts": 0,
            "safeModeWasActive": false
        ]
        let log = DrivingLog.from(dictionary: dict, id: "log-002")

        XCTAssertNotNil(log)
        XCTAssertEqual(log?.maxSpeed, 65.0)
    }

    // MARK: - DeviceStatus

    func testDeviceStatusDefaults() {
        let status = DeviceStatus(childId: "child-1")
        XCTAssertFalse(status.drivingDetected)
        XCTAssertFalse(status.safeModeActive)
        XCTAssertEqual(status.currentSpeed, 0)
    }
}
