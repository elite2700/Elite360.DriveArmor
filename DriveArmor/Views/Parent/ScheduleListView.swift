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
                ScheduleEditorView { schedule in
                    Task {
                        try? await service.addSchedule(schedule, familyId: appState.familyId ?? "")
                    }
                }
            }
        }
        .task {
            guard let fId = appState.familyId else { return }
            service.startListening(familyId: fId)
        }
    }

    private func toggleSchedule(_ s: SafeModeSchedule) async {
        var updated = s
        updated.isEnabled.toggle()
        try? await service.updateSchedule(updated, familyId: appState.familyId ?? "")
    }

    private func deleteSchedules(at offsets: IndexSet) async {
        for i in offsets {
            let s = service.schedules[i]
            try? await service.deleteSchedule(s, familyId: appState.familyId ?? "")
        }
    }
}

// MARK: - Row

private struct ScheduleRow: View {
    let schedule: SafeModeSchedule
    let onToggle: () -> Void

    private static let dayAbbreviations = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

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
        "\(schedule.startTime) – \(schedule.endTime)"
    }

    private var daysList: String {
        schedule.daysOfWeek
            .sorted()
            .map { Self.dayAbbreviations[safe: $0] ?? "?" }
            .joined(separator: ", ")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Editor

struct ScheduleEditorView: View {
    let onSave: (SafeModeSchedule) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var startTime = "08:00"
    @State private var endTime = "15:00"
    @State private var selectedDays: Set<Int> = [1, 2, 3, 4, 5] // Mon-Fri

    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        Form {
            Section("Schedule Info") {
                TextField("Name (e.g. School hours)", text: $name)
                TextField("Start Time (HH:mm)", text: $startTime)
                    .keyboardType(.numbersAndPunctuation)
                TextField("End Time (HH:mm)", text: $endTime)
                    .keyboardType(.numbersAndPunctuation)
            }

            Section("Days of Week") {
                ForEach(0..<7, id: \.self) { day in
                    Toggle(dayNames[day], isOn: Binding(
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
            startTime: startTime,
            endTime: endTime,
            daysOfWeek: Array(selectedDays),
            isEnabled: true,
            createdAt: Date()
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
