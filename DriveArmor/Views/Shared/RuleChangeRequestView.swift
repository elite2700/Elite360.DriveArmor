// RuleChangeRequestView.swift
// Elite360.DriveArmor
//
// Child: submit rule change requests.
// Parent: review & respond to rule change requests.

import SwiftUI

struct RuleChangeRequestView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var service = OverrideRequestService()
    @State private var showNewRequest = false

    private var isParent: Bool { appState.userRole == .parent }

    var body: some View {
        List {
            if service.ruleChangeRequests.isEmpty {
                ContentUnavailableView(
                    "No Rule Change Requests",
                    systemImage: "doc.badge.gearshape",
                    description: Text(isParent
                        ? "Requests from your teen to adjust rules will appear here."
                        : "Submit a request to your parent to change a driving rule.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(service.ruleChangeRequests) { request in
                    RuleChangeRow(
                        request: request,
                        isParent: isParent,
                        onApprove: { Task { await respond(request, approved: true) } },
                        onDeny: { Task { await respond(request, approved: false) } }
                    )
                }
            }
        }
        .navigationTitle("Rule Changes")
        .toolbar {
            if !isParent {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewRequest = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showNewRequest) {
            NavigationStack {
                NewRuleChangeView { request in
                    Task {
                        guard let fId = appState.familyId else { return }
                        try? await service.submitRuleChangeRequest(request, familyId: fId)
                    }
                }
            }
        }
        .task {
            guard let fId = appState.familyId else { return }
            service.listenForRuleChangeRequests(familyId: fId)
        }
    }

    private func respond(_ request: RuleChangeRequest, approved: Bool) async {
        guard let fId = appState.familyId else { return }
        try? await service.respondToRuleChangeRequest(
            request,
            approved: approved,
            familyId: fId,
            respondedBy: appState.userId ?? ""
        )
    }
}

// MARK: - Row

private struct RuleChangeRow: View {
    let request: RuleChangeRequest
    let isParent: Bool
    let onApprove: () -> Void
    let onDeny: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                statusBadge
                Spacer()
                Text(request.requestedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(request.ruleDescription)
                .font(.headline)

            Text("Current: \(request.currentValue) \u{2192} Requested: \(request.requestedValue)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(request.reason)
                .font(.subheadline)

            if isParent && request.status == .pending {
                HStack(spacing: 12) {
                    Button {
                        onApprove()
                    } label: {
                        Label("Approve", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Button {
                        onDeny()
                    } label: {
                        Label("Deny", systemImage: "xmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusBadge: some View {
        let (text, color): (String, Color) = {
            switch request.status {
            case .pending:  return ("Pending", .orange)
            case .approved: return ("Approved", .green)
            case .denied:   return ("Denied", .red)
            }
        }()

        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - New Rule Change Sheet

struct NewRuleChangeView: View {
    let onSave: (RuleChangeRequest) -> Void

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var ruleDescription = ""
    @State private var currentValue = ""
    @State private var requestedValue = ""
    @State private var reason = ""

    var body: some View {
        Form {
            Section("Rule") {
                TextField("Which rule? (e.g. Speed limit threshold)", text: $ruleDescription)
                TextField("Current value", text: $currentValue)
                TextField("Requested value", text: $requestedValue)
            }
            Section("Reason") {
                TextEditor(text: $reason)
                    .frame(minHeight: 80)
            }
        }
        .navigationTitle("Request Change")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Submit") {
                    submit()
                    dismiss()
                }
                .disabled(ruleDescription.isEmpty || reason.isEmpty)
            }
        }
    }

    private func submit() {
        let request = RuleChangeRequest(
            id: UUID().uuidString,
            childId: appState.userId ?? "",
            ruleDescription: ruleDescription,
            currentValue: currentValue,
            requestedValue: requestedValue,
            reason: reason,
            status: .pending,
            requestedAt: Date(),
            respondedAt: nil,
            respondedBy: nil
        )
        onSave(request)
    }
}

#Preview {
    NavigationStack {
        RuleChangeRequestView()
            .environmentObject(AppState())
    }
}
