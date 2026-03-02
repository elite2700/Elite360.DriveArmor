// OverrideRequestsView.swift
// Elite360.DriveArmor
//
// Parent view — lists pending override requests from teens.
// Child view — shows own request history.

import SwiftUI

struct OverrideRequestsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var service = OverrideRequestService()

    private var isParent: Bool { appState.userRole == .parent }

    var body: some View {
        List {
            if service.overrideRequests.isEmpty {
                ContentUnavailableView(
                    isParent ? "No Pending Requests" : "No Override Requests",
                    systemImage: "hand.raised.slash",
                    description: Text(isParent
                        ? "Override requests from your teen will appear here."
                        : "Your override requests will appear here.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(service.overrideRequests) { request in
                    OverrideRequestRow(
                        request: request,
                        isParent: isParent,
                        onApprove: { Task { await respond(request, approved: true) } },
                        onDeny: { Task { await respond(request, approved: false) } }
                    )
                }
            }
        }
        .navigationTitle("Override Requests")
        .task {
            guard let fId = appState.familyId else { return }
            if isParent {
                service.listenForPendingRequests(familyId: fId)
            } else if let uid = appState.userId {
                service.listenForChildRequests(familyId: fId, childId: uid)
            }
        }
    }

    private func respond(_ request: OverrideRequest, approved: Bool) async {
        guard let fId = appState.familyId else { return }
        try? await service.respondToOverrideRequest(
            request,
            approved: approved,
            familyId: fId,
            respondedBy: appState.userId ?? ""
        )
    }
}

// MARK: - Row

private struct OverrideRequestRow: View {
    let request: OverrideRequest
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

            if let respondedAt = request.respondedAt {
                Text("Responded \(respondedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
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

#Preview {
    NavigationStack {
        OverrideRequestsView()
            .environmentObject(AppState())
    }
}
