// GeofenceListView.swift
// Elite360.DriveArmor
//
// Parent-only view for managing geofence zones.

import SwiftUI
import MapKit

struct GeofenceListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var service = GeofenceService()
    @State private var showAddSheet = false
    @State private var editingFence: GeofenceModel?

    var body: some View {
        List {
            if service.geofences.isEmpty {
                ContentUnavailableView(
                    "No Geofences",
                    systemImage: "mappin.slash",
                    description: Text("Tap + to define safe zones for your teen driver.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(service.geofences) { fence in
                    GeofenceRow(fence: fence, onToggle: {
                        Task { await toggleFence(fence) }
                    })
                    .contentShape(Rectangle())
                    .onTapGesture { editingFence = fence }
                }
                .onDelete { offsets in
                    Task { await deleteFences(at: offsets) }
                }
            }
        }
        .navigationTitle("Geofences")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                GeofenceEditorView(familyId: appState.familyId ?? "") { newFence in
                    Task {
                        try? await service.addGeofence(newFence, familyId: appState.familyId ?? "")
                    }
                }
            }
        }
        .sheet(item: $editingFence) { fence in
            NavigationStack {
                GeofenceEditorView(
                    familyId: appState.familyId ?? "",
                    existing: fence
                ) { updated in
                    Task {
                        try? await service.updateGeofence(updated, familyId: appState.familyId ?? "")
                    }
                }
            }
        }
        .task {
            guard let fId = appState.familyId else { return }
            service.startListening(familyId: fId)
        }
    }

    private func toggleFence(_ fence: GeofenceModel) async {
        var updated = fence
        updated.isEnabled.toggle()
        try? await service.updateGeofence(updated, familyId: appState.familyId ?? "")
    }

    private func deleteFences(at offsets: IndexSet) async {
        for index in offsets {
            let fence = service.geofences[index]
            try? await service.deleteGeofence(fence, familyId: appState.familyId ?? "")
        }
    }
}

// MARK: - Row

private struct GeofenceRow: View {
    let fence: GeofenceModel
    let onToggle: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(fence.name)
                    .font(.headline)
                Text("\(Int(fence.radiusMeters))m radius")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    if fence.notifyOnEntry {
                        Label("Entry", systemImage: "arrow.down.right.circle")
                            .font(.caption2)
                    }
                    if fence.notifyOnExit {
                        Label("Exit", systemImage: "arrow.up.left.circle")
                            .font(.caption2)
                    }
                }
                .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: .constant(fence.isEnabled))
                .labelsHidden()
                .onTapGesture { onToggle() }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Editor

struct GeofenceEditorView: View {
    let familyId: String
    var existing: GeofenceModel?
    let onSave: (GeofenceModel) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var latitude: String = ""
    @State private var longitude: String = ""
    @State private var radius: String = "200"
    @State private var notifyEntry = true
    @State private var notifyExit = true

    var body: some View {
        Form {
            Section("Zone Info") {
                TextField("Name", text: $name)
                TextField("Latitude", text: $latitude)
                    .keyboardType(.decimalPad)
                TextField("Longitude", text: $longitude)
                    .keyboardType(.decimalPad)
                TextField("Radius (meters)", text: $radius)
                    .keyboardType(.numberPad)
            }

            Section("Notifications") {
                Toggle("Notify on Entry", isOn: $notifyEntry)
                Toggle("Notify on Exit", isOn: $notifyExit)
            }
        }
        .navigationTitle(existing == nil ? "Add Geofence" : "Edit Geofence")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                    dismiss()
                }
                .disabled(name.isEmpty || latitude.isEmpty || longitude.isEmpty)
            }
        }
        .onAppear {
            if let existing {
                name = existing.name
                latitude = String(existing.latitude)
                longitude = String(existing.longitude)
                radius = String(Int(existing.radiusMeters))
                notifyEntry = existing.notifyOnEntry
                notifyExit = existing.notifyOnExit
            }
        }
    }

    private func save() {
        guard let lat = Double(latitude),
              let lng = Double(longitude),
              let rad = Double(radius) else { return }

        let fence = GeofenceModel(
            id: existing?.id ?? UUID().uuidString,
            name: name,
            latitude: lat,
            longitude: lng,
            radiusMeters: rad,
            notifyOnEntry: notifyEntry,
            notifyOnExit: notifyExit,
            isEnabled: existing?.isEnabled ?? true,
            createdAt: existing?.createdAt ?? Date()
        )
        onSave(fence)
    }
}

#Preview {
    NavigationStack {
        GeofenceListView()
            .environmentObject(AppState())
    }
}
