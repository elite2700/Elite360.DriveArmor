// ScheduleListView.swift
// Elite360.DriveArmor
//
// Parent view for managing recurring safe-mode schedules.

import SwiftUI

struct ScheduleListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var service = ScheduleService()
    @State private var showAddSheet = false

    var body: some View {
        List {
            if service.schedules.isEmpty {
                ContentUnavailableView(
                    "No Schedules",
                    systemImage: "clock.badge.questionmark",
                    description: Text("Create recurring safe-mode windows so it activates automatically.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(service.schedules) { schedule in
                    ScheduleRow(schedule: schedule, onToggle: {
                        Task { await toggleSchedule(schedule) }
                    })
                }
                .onDelete { offsets in
                    Task { await deleteSchedules(at: offsets) }
                }
            }
        }
        .navigationTitle("Schedules")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                ScheduleEditorView(createdBy: appState.userId ?? "") { schedule in
                    Task {
                        try? await service.createSchedule(familyId: appState.familyId ?? "", schedule: schedule)
                    }
                }
            }
        }
        .task {
            guard let fId = appState.familyId else { return }
            service.listenToSchedules(familyId: fId)
        }
    }

    private func toggleSchedule(_ s: SafeModeSchedule) async {
        var updated = s
        updated.isEnabled.toggle()
        try? await service.updateSchedule(familyId: appState.familyId ?? "", schedule: updated)
    }

    private func deleteSchedules(at offsets: IndexSet) async {
        for i in offsets {
            let s = service.schedules[i]
            try? await service.deleteSchedule(familyId: appState.familyId ?? "", scheduleId: s.id)
        }
    }
}

// MARK: - Row

private struct ScheduleRow: View {
    let schedule: SafeModeSchedule
    let onToggle: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.name)
                    .font(.headline)

                Text(timeRange)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(daysList)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: .constant(schedule.isEnabled))
                .labelsHidden()
                .onTapGesture { onToggle() }
        }
        .padding(.vertical, 4)
    }

    private var timeRange: String {
        "\(schedule.startTimeString) \u{2013} \(schedule.endTimeString)"
    }

    private var daysList: String {
        let dayAbbr = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return schedule.daysOfWeek
            .sorted()
            .compactMap { day in (1...7).contains(day) ? dayAbbr[day - 1] : nil }
            .joined(separator: ", ")
    }
}

// MARK: - Editor

struct ScheduleEditorView: View {
    let createdBy: String
    let onSave: (SafeModeSchedule) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var startHour = 8
    @State private var startMinute = 0
    @State private var endHour = 15
    @State private var endMinute = 0
    @State private var selectedDays: Set<Int> = [2, 3, 4, 5, 6] // Mon-Fri (1=Sun)

    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        Form {
            Section("Schedule Info") {
                TextField("Name (e.g. School hours)", text: $name)
                Stepper("Start Hour: \(startHour)", value: $startHour, in: 0...23)
                Stepper("Start Minute: \(startMinute)", value: $startMinute, in: 0...59)
                Stepper("End Hour: \(endHour)", value: $endHour, in: 0...23)
                Stepper("End Minute: \(endMinute)", value: $endMinute, in: 0...59)
            }

            Section("Days of Week") {
                ForEach(1..<8, id: \.self) { day in
                    Toggle(dayNames[day - 1], isOn: Binding(
                        get: { selectedDays.contains(day) },
                        set: { isOn in
                            if isOn { selectedDays.insert(day) }
                            else { selectedDays.remove(day) }
                        }
                    ))
                }
            }
        }
        .navigationTitle("New Schedule")
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
                .disabled(name.isEmpty || selectedDays.isEmpty)
            }
        }
    }

    private func save() {
        let schedule = SafeModeSchedule(
            id: UUID().uuidString,
            name: name,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            daysOfWeek: Array(selectedDays),
            isEnabled: true,
            createdBy: createdBy
        )
        onSave(schedule)
    }
}

#Preview {
    NavigationStack {
        ScheduleListView()
            .environmentObject(AppState())
    }
}
