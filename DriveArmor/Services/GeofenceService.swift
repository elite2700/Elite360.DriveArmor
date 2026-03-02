// GeofenceService.swift
// Elite360.DriveArmor
//
// Manages geofence CRUD in Firestore and applies CLCircularRegion
// monitoring on the child device.

import Foundation
import Combine
import CoreLocation
import FirebaseFirestore

final class GeofenceService: NSObject, ObservableObject {

    // MARK: - Published

    @Published var geofences: [GeofenceModel] = []
    @Published var lastTriggeredEvent: GeofenceEvent?

    // MARK: - Private

    private let db = Firestore.firestore()
    private let locationManager = CLLocationManager()
    private var listener: ListenerRegistration?

    struct GeofenceEvent: Equatable {
        let geofenceId: String
        let geofenceName: String
        let type: EventType
        let timestamp: Date

        enum EventType: String {
            case entered, exited
        }
    }

    // MARK: - Firestore Refs

    private func geofencesRef(familyId: String) -> CollectionReference {
        db.collection("families").document(familyId).collection("geofences")
    }

    // MARK: - Init

    override init() {
        super.init()
        locationManager.delegate = self
    }

    // MARK: - CRUD

    func createGeofence(familyId: String, geofence: GeofenceModel) async throws {
        try await geofencesRef(familyId: familyId)
            .document(geofence.id).setData(geofence.asDictionary)
    }

    func updateGeofence(familyId: String, geofence: GeofenceModel) async throws {
        try await geofencesRef(familyId: familyId)
            .document(geofence.id).setData(geofence.asDictionary, merge: true)
    }

    func deleteGeofence(familyId: String, geofenceId: String) async throws {
        try await geofencesRef(familyId: familyId).document(geofenceId).delete()
        locationManager.monitoredRegions
            .first { $0.identifier == geofenceId }
            .map { locationManager.stopMonitoring(for: $0) }
    }

    // MARK: - Fetch / Listen

    func fetchGeofences(familyId: String) async throws -> [GeofenceModel] {
        let snapshot = try await geofencesRef(familyId: familyId).getDocuments()
        return snapshot.documents.compactMap { doc in
            GeofenceModel.from(dictionary: doc.data(), id: doc.documentID)
        }
    }

    func listenToGeofences(familyId: String) {
        listener?.remove()
        listener = geofencesRef(familyId: familyId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let fences = documents.compactMap { doc in
                    GeofenceModel.from(dictionary: doc.data(), id: doc.documentID)
                }
                DispatchQueue.main.async {
                    self?.geofences = fences
                    self?.applyMonitoring(fences)
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        // Remove all monitored regions added by us
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }

    // MARK: - Region Monitoring

    private func applyMonitoring(_ fences: [GeofenceModel]) {
        // Remove stale regions
        let activeIds = Set(fences.filter(\.isEnabled).map(\.id))
        for region in locationManager.monitoredRegions {
            if !activeIds.contains(region.identifier) {
                locationManager.stopMonitoring(for: region)
            }
        }
        // Add new regions (max 20 per app)
        for fence in fences where fence.isEnabled {
            if !locationManager.monitoredRegions.contains(where: { $0.identifier == fence.id }) {
                locationManager.startMonitoring(for: fence.region)
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension GeofenceService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let fence = geofences.first(where: { $0.id == region.identifier }) else { return }
        lastTriggeredEvent = GeofenceEvent(
            geofenceId: fence.id,
            geofenceName: fence.name,
            type: .entered,
            timestamp: Date()
        )
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let fence = geofences.first(where: { $0.id == region.identifier }) else { return }
        lastTriggeredEvent = GeofenceEvent(
            geofenceId: fence.id,
            geofenceName: fence.name,
            type: .exited,
            timestamp: Date()
        )
    }
}
