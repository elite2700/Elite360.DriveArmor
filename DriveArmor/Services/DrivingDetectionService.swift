// DrivingDetectionService.swift
// Elite360.DriveArmor
//
// Uses CoreMotion (CMMotionActivityManager) and CoreLocation to detect
// automotive motion and speed. Publishes driving state changes via Combine.
// Runs on the child device only.

import Foundation
import Combine
import CoreMotion
import CoreLocation

final class DrivingDetectionService: NSObject, ObservableObject {

    // MARK: - Published State

    @Published var isDriving: Bool = false
    @Published var currentSpeed: Double = 0          // mph
    @Published var authorizationDenied: Bool = false

    // MARK: - Configuration

    /// Speed threshold (mph) above which we consider the user to be driving.
    static let speedThresholdMPH: Double = 20.0

    // MARK: - Private

    private let motionManager = CMMotionActivityManager()
    private let locationManager = CLLocationManager()
    private var motionIndicatesDriving = false
    private var speedIndicatesDriving = false

    // Current driving session tracking
    private(set) var sessionStartTime: Date?
    private(set) var maxSpeed: Double = 0
    private var speedSamples: [Double] = []
    private var distanceMeters: Double = 0
    private var lastLocation: CLLocation?

    // MARK: - Init

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .automotiveNavigation
    }

    // MARK: - Start / Stop

    func startMonitoring() {
        requestLocationPermission()
        startMotionUpdates()
    }

    func stopMonitoring() {
        motionManager.stopActivityUpdates()
        locationManager.stopUpdatingLocation()
        endDrivingSession()
    }

    // MARK: - Location Permission

    private func requestLocationPermission() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default:
            authorizationDenied = true
        }
    }

    // MARK: - Core Motion Activity

    private func startMotionUpdates() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            print("[DrivingDetection] Motion activity not available on this device")
            return
        }

        motionManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            let wasMotionDriving = self.motionIndicatesDriving
            self.motionIndicatesDriving = activity.automotive
            if wasMotionDriving != self.motionIndicatesDriving {
                self.evaluateDrivingState()
            }
        }
    }

    // MARK: - Driving State Evaluation

    /// Combine motion + speed signals to determine driving state.
    private func evaluateDrivingState() {
        let nowDriving = motionIndicatesDriving && speedIndicatesDriving

        guard nowDriving != isDriving else { return }

        if nowDriving {
            beginDrivingSession()
        } else {
            endDrivingSession()
        }
        isDriving = nowDriving
    }

    // MARK: - Session Management

    private func beginDrivingSession() {
        sessionStartTime = Date()
        maxSpeed = 0
        speedSamples = []
        distanceMeters = 0
        lastLocation = nil
    }

    private func endDrivingSession() {
        guard sessionStartTime != nil else { return }
        // Session data is available via computed properties until next session starts
        sessionStartTime = nil
    }

    /// Build a DrivingLog from the current/completed session.
    func buildCurrentLog(childId: String) -> DrivingLog? {
        guard let start = sessionStartTime else { return nil }
        let avg = speedSamples.isEmpty ? 0 : speedSamples.reduce(0, +) / Double(speedSamples.count)
        return DrivingLog(
            childId: childId,
            startTime: start,
            endTime: isDriving ? nil : Date(),
            maxSpeed: maxSpeed,
            averageSpeed: avg,
            distanceKm: distanceMeters / 1000.0,
            distractionAttempts: 0,
            safeModeWasActive: false
        )
    }
}

// MARK: - CLLocationManagerDelegate

extension DrivingDetectionService: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            authorizationDenied = false
            manager.startUpdatingLocation()
        case .denied, .restricted:
            authorizationDenied = true
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.speed >= 0 else { return }

        // Convert m/s → mph
        let speedMPH = location.speed * 2.23694
        currentSpeed = max(speedMPH, 0)

        let wasSpeedDriving = speedIndicatesDriving
        speedIndicatesDriving = speedMPH >= Self.speedThresholdMPH

        // Track session data
        if isDriving || (motionIndicatesDriving && speedIndicatesDriving) {
            speedSamples.append(speedMPH)
            if speedMPH > maxSpeed { maxSpeed = speedMPH }
            if let last = lastLocation {
                distanceMeters += location.distance(from: last)
            }
            lastLocation = location
        }

        if wasSpeedDriving != speedIndicatesDriving {
            evaluateDrivingState()
        }
    }
}
