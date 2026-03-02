// RemoteControlView.swift
// Elite360.DriveArmor
//
// Detailed remote-control panel for a single child. Allows sending
// safe-mode commands with optional duration and message.

import SwiftUI

struct RemoteControlView: View {
    let child: UserModel
    let status: DeviceStatus?

    @EnvironmentObject var appState: AppState
    @State private var durationMinutes: Double = 0    // 0 = indefinite
    @State private var reason: String = ""
    @State private var isSending = false
    @State private var commandSent = false

    private let commandService = CommandService()

    private var safeModeActive: Bool { status?.safeModeActive ?? false }

    var body: some View {
        Form {
            // MARK: - Current Status
            Section("Device Status") {
                LabeledContent("Driving") {
                    Text(status?.drivingDetected == true ? "Yes" : "No")
                        .foregroundStyle(status?.drivingDetected == true ? .orange : .secondary)
                }
                LabeledContent("Safe Mode") {
                    Text(safeModeActive ? "Active" : "Inactive")
                        .foregroundStyle(safeModeActive ? .green : .secondary)
                }
                LabeledContent("Speed") {
                    Text(String(format: "%.0f mph", status?.currentSpeed ?? 0))
                }
            }

            // MARK: - Enable Safe Mode
            Section("Safe Mode Controls") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Duration: \(durationMinutes == 0 ? "Indefinite" : "\(Int(durationMinutes)) min")")
                        .font(.subheadline)
                    Slider(value: $durationMinutes, in: 0...120, step: 5) {
                        Text("Duration")
                    }
                    .tint(.orange)
                }

                TextField("Optional message to child", text: $reason)

                Button {
                    Task { await sendCommand(type: .enableSafeMode) }
                } label: {
                    Label("Enable Safe Mode", systemImage: "lock.shield.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(safeModeActive || isSending)
            }

            // MARK: - Disable Safe Mode
            Section {
                Button {
                    Task { await sendCommand(type: .disableSafeMode) }
                } label: {
                    Label("Disable Safe Mode", systemImage: "lock.open.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.gray)
                .disabled(!safeModeActive || isSending)
            }
        }
        .navigationTitle("Control \(child.displayName)")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if commandSent {
                VStack {
                    Spacer()
                    Label("Command Sent", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .padding()
                        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Actions

    private func sendCommand(type: CommandType) async {
        guard let familyId = appState.currentFamily?.id,
              let parentId = appState.currentUser?.uid else { return }

        isSending = true
        do {
            _ = try await commandService.sendCommand(
                familyId: familyId,
                type: type,
                targetChildId: child.uid,
                issuedBy: parentId,
                params: CommandParams(
                    durationMinutes: durationMinutes > 0 ? Int(durationMinutes) : nil,
                    reason: reason.isEmpty ? nil : reason
                )
            )
            withAnimation { commandSent = true }
            try? await Task.sleep(for: .seconds(2))
            withAnimation { commandSent = false }
        } catch {
            print("[RemoteControl] Error: \(error.localizedDescription)")
        }
        isSending = false
    }
}
