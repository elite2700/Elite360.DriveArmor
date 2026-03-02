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
                NewRuleChangeView { requestType, message in
                    Task {
                        guard let fId = appState.familyId,
                              let uid = appState.userId else { return }
                        _ = try? await service.sendRuleChangeRequest(
                            familyId: fId,
                            childId: uid,
                            requestType: requestType,
                            message: message
                        )
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
            familyId: fId,
            requestId: request.id,
            approved: approved
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
                Text(request.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(request.requestType)
                .font(.headline)

            Text(request.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

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
    let onSave: (_ requestType: String, _ message: String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var requestType = ""
    @State private var message = ""

    var body: some View {
        Form {
            Section("Rule") {
                TextField("Which rule? (e.g. Speed limit, Schedule)", text: $requestType)
            }
            Section("Details") {
                TextEditor(text: $message)
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
                    onSave(requestType, message)
                    dismiss()
                }
                .disabled(requestType.isEmpty || message.isEmpty)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RuleChangeRequestView()
            .environmentObject(AppState())
    }
}
