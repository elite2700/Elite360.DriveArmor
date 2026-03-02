// RoleSelectionView.swift
// Elite360.DriveArmor
//
// After sign-up, the user picks Parent or Child.
// This writes the role to Firestore and advances AppState.

import SwiftUI

struct RoleSelectionView: View {
    @EnvironmentObject var appState: AppState
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    private let authService = AuthService()

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("Who are you?")
                    .font(.title.bold())
                Text("Choose your role to get started.")
                    .foregroundStyle(.secondary)
            }

            // MARK: - Role Cards
            HStack(spacing: 20) {
                RoleCard(
                    icon: "person.fill.viewfinder",
                    title: "Parent",
                    description: "Monitor and control your child's device while driving.",
                    color: .blue
                ) {
                    await selectRole(.parent)
                }

                RoleCard(
                    icon: "car.fill",
                    title: "Child",
                    description: "Stay safe with driving detection and safe mode.",
                    color: .green
                ) {
                    await selectRole(.child)
                }
            }
            .padding(.horizontal, 20)

            if isLoading {
                ProgressView("Saving…")
            }

            Spacer()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Action

    private func selectRole(_ role: UserRole) async {
        guard let user = appState.currentUser else { return }
        isLoading = true
        do {
            try await authService.setRole(uid: user.uid, role: role)
            var updated = user
            updated.role = role
            appState.resolveStage(for: updated)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}

// MARK: - Role Card Component

private struct RoleCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () async -> Void

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(color)

                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RoleSelectionView()
        .environmentObject(AppState())
}
