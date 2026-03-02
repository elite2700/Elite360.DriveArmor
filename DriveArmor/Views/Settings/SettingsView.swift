// SettingsView.swift
// Elite360.DriveArmor
//
// Account settings: profile info, pairing code management (parent),
// notification preferences, and sign out.

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showSignOutConfirm = false
    @State private var showRoleSwitchConfirm = false

    private var isParent: Bool { appState.currentUser?.role == .parent }
    private var targetRole: UserRole { isParent ? .child : .parent }

    var body: some View {
        Form {
            // MARK: - Profile
            Section("Profile") {
                HStack {
                    Image(systemName: isParent ? "person.fill.viewfinder" : "car.fill")
                        .font(.title2)
                        .foregroundStyle(.accent)
                        .frame(width: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Display Name", text: $viewModel.displayName)
                            .font(.headline)
                        Text(appState.currentUser?.email ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button("Update Name") {
                    if let uid = appState.currentUser?.uid {
                        Task { await viewModel.updateDisplayName(uid: uid) }
                    }
                }
                .disabled(viewModel.isLoading)

                LabeledContent("Role") {
                    Text(appState.currentUser?.role?.rawValue.capitalized ?? "Unknown")
                }
            }

            // MARK: - Family
            Section("Family") {
                if let family = appState.currentFamily {
                    LabeledContent("Family Name") {
                        Text(family.name)
                    }
                    LabeledContent("Members") {
                        Text("\(family.childIds.count) child(ren)")
                    }

                    if isParent {
                        LabeledContent("Pairing Code") {
                            Text(viewModel.pairingCode)
                                .font(.system(.body, design: .monospaced).bold())
                        }
                        Button("Regenerate Pairing Code") {
                            Task { await viewModel.regeneratePairingCode(familyId: family.id) }
                        }
                    }
                } else {
                    Text("No family linked")
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - About
            Section("About") {
                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                }
                LabeledContent("Build") {
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                }
            }

            // MARK: - Subscription
            Section("Subscription") {
                NavigationLink(destination: SubscriptionView()) {
                    Label("Manage Subscription", systemImage: "crown.fill")
                }
            }

            // MARK: - Security
            Section("Security") {
                if viewModel.biometricType != .none {
                    Toggle(isOn: $viewModel.biometricEnabled) {
                        Label(
                            viewModel.biometricType == .faceID ? "Face ID Lock" : "Touch ID Lock",
                            systemImage: viewModel.biometricType == .faceID ? "faceid" : "touchid"
                        )
                    }
                    .onChange(of: viewModel.biometricEnabled) { _, _ in
                        Task { await viewModel.toggleBiometric() }
                    }
                }
            }

            // MARK: - Role Switching
            Section("Advanced") {
                Button {
                    showRoleSwitchConfirm = true
                } label: {
                    Label("Switch to \(targetRole.rawValue.capitalized) Mode", systemImage: "arrow.left.arrow.right")
                }
            }

            // MARK: - Sign Out
            Section {
                Button(role: .destructive) {
                    showSignOutConfirm = true
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.load(user: appState.currentUser ?? UserModel(uid: "", email: "", displayName: ""),
                           family: appState.currentFamily)
        }
        .confirmationDialog("Sign out?", isPresented: $showSignOutConfirm) {
            Button("Sign Out", role: .destructive) {
                viewModel.signOut(appState: appState)
            }
        }
        .confirmationDialog(
            "Switch to \(targetRole.rawValue.capitalized) mode?",
            isPresented: $showRoleSwitchConfirm
        ) {
            Button("Switch Role") {
                Task { await viewModel.switchRole(appState: appState, to: targetRole) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will change your role. You may need to re-pair with a family.")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppState())
    }
}
