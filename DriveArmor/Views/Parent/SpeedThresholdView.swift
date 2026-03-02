// SpeedThresholdView.swift
// Elite360.DriveArmor
//
// Parent view for customizing speed alert thresholds per child.

import SwiftUI

struct SpeedThresholdView: View {
    @EnvironmentObject var appState: AppState
    @State private var generalLimit: Double = 70
    @State private var schoolZoneLimit: Double = 25
    @State private var residentialLimit: Double = 35
    @State private var highwayLimit: Double = 75
    @State private var isSaving = false

    private let db = FirestoreReference.shared

    var body: some View {
        Form {
            Section {
                Text("Set speed thresholds (mph). You\u{2019}ll receive alerts when your teen exceeds these limits.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("General Speed Limit") {
                SpeedSlider(label: "Max Speed", value: $generalLimit, range: 15...100)
            }

            Section("Zone-Specific Limits") {
                SpeedSlider(label: "School Zone", value: $schoolZoneLimit, range: 10...45)
                SpeedSlider(label: "Residential", value: $residentialLimit, range: 15...55)
                SpeedSlider(label: "Highway", value: $highwayLimit, range: 45...100)
            }

            Section {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Save Thresholds")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
            }
        }
        .navigationTitle("Speed Alerts")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadThresholds() }
    }

    // MARK: - Persistence

    private func loadThresholds() async {
        guard let fId = appState.familyId else { return }
        do {
            let doc = try await db.document("families/\(fId)").getDocument()
            if let data = doc.data()?["speedThresholds"] as? [String: Any] {
                generalLimit = data["general"] as? Double ?? 70
                schoolZoneLimit = data["schoolZone"] as? Double ?? 25
                residentialLimit = data["residential"] as? Double ?? 35
                highwayLimit = data["highway"] as? Double ?? 75
            }
        } catch {
            print("Failed to load speed thresholds: \(error)")
        }
    }

    private func save() async {
        guard let fId = appState.familyId else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await db.document("families/\(fId)").updateData([
                "speedThresholds": [
                    "general": generalLimit,
                    "schoolZone": schoolZoneLimit,
                    "residential": residentialLimit,
                    "highway": highwayLimit
                ]
            ])
        } catch {
            print("Failed to save speed thresholds: \(error)")
        }
    }
}

// MARK: - Speed Slider

private struct SpeedSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text("\(Int(value)) mph")
                    .font(.headline)
                    .monospacedDigit()
            }
            Slider(value: $value, in: range, step: 5)
        }
        .padding(.vertical, 4)
    }
}

/// Thin Firestore reference wrapper so the view can talk to Firestore
/// without importing Firebase directly (keeps the pattern consistent).
private enum FirestoreReference {
    static let shared = FirebaseFirestore.Firestore.firestore()
}

import FirebaseFirestore

#Preview {
    NavigationStack {
        SpeedThresholdView()
            .environmentObject(AppState())
    }
}
