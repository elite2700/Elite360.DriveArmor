// SettingsViewModel.swift
// Elite360.DriveArmor
//
// Manages account and family settings: sign out, pairing code display,
// notification preferences, and profile updates.

import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Published

    @Published var displayName: String = ""
    @Published var pairingCode: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Services

    private let authService = AuthService()
    private let familyService = FamilyService()

    // MARK: - Load

    func load(user: UserModel, family: FamilyModel?) {
        displayName = user.displayName
        pairingCode = family?.pairingCode ?? ""
    }

    // MARK: - Update Display Name

    func updateDisplayName(uid: String) async {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        do {
            try await authService.updateProfile(uid: uid, fields: ["displayName": trimmed])
        } catch {
            showErrorMessage(error.localizedDescription)
        }
        isLoading = false
    }

    // MARK: - Regenerate Pairing Code (Parent only)

    func regeneratePairingCode(familyId: String) async {
        isLoading = true
        do {
            pairingCode = try await familyService.regeneratePairingCode(familyId: familyId)
        } catch {
            showErrorMessage(error.localizedDescription)
        }
        isLoading = false
    }

    // MARK: - Sign Out

    func signOut(appState: AppState) {
        appState.signOut()
    }

    // MARK: - Helpers

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
