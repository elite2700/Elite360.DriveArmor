// LocationService.swift
// Elite360.DriveArmor
//
// Thin wrapper around CLLocationManager providing structured concurrency
// and Combine publishers for the child's location data.
// Used by DrivingDetectionService; also supports geofence features.

import Foundation
import Combine
import CoreLocation

final class LocationService: NSObject, ObservableObject {

    // MARK: - Published

    @Published var currentLocation: CLLocation?
    @Published var currentSpeedMPH: Double = 0
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // MARK: - Private

    private let manager = CLLocationManager()

    // MARK: - Init

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.allowsBackgroundLocationUpdates = true
        manager.activityType = .automotiveNavigation
    }

    // MARK: - Public API

    func requestAlwaysAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    /// Use significant-change monitoring for battery-efficient background tracking.
    func startSignificantChangeMonitoring() {
        manager.startMonitoringSignificantLocationChanges()
    }

    func stopSignificantChangeMonitoring() {
        manager.stopMonitoringSignificantLocationChanges()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        currentSpeedMPH = max(location.speed * 2.23694, 0) // m/s → mph, floor at 0
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationService] Error: \(error.localizedDescription)")
    }
}
