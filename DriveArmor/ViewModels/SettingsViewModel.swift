// SettingsViewModel.swift
// Elite360.DriveArmor
//
// Manages account and family settings: sign out, pairing code display,
// notification preferences, profile updates, role switching, and biometric auth.

import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Published

    @Published var displayName: String = ""
    @Published var pairingCode: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var biometricEnabled: Bool = false
    @Published var biometricType: BiometricService.BiometricType = .none

    // MARK: - Services

    private let authService = AuthService()
    private let familyService = FamilyService()
    let biometricService = BiometricService()

    // MARK: - Load

    func load(user: UserModel, family: FamilyModel?) {
        displayName = user.displayName
        pairingCode = family?.pairingCode ?? ""
        biometricType = biometricService.availableBiometric
        biometricEnabled = UserDefaults.standard.bool(forKey: "biometricEnabled")
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

    // MARK: - Role Switching

    func switchRole(appState: AppState, to newRole: UserRole) async {
        isLoading = true
        do {
            try await appState.switchRole(to: newRole)
        } catch {
            showErrorMessage(error.localizedDescription)
        }
        isLoading = false
    }

    // MARK: - Biometric Auth

    func toggleBiometric() async {
        if biometricEnabled {
            // Turning off
            biometricEnabled = false
            UserDefaults.standard.set(false, forKey: "biometricEnabled")
        } else {
            // Verify identity before enabling
            let success = await biometricService.authenticate(reason: "Verify identity to enable biometric lock")
            if success {
                biometricEnabled = true
                UserDefaults.standard.set(true, forKey: "biometricEnabled")
            }
        }
    }

    /// Authenticate before sensitive actions (e.g. changing settings).
    func authenticateForSensitiveAction() async -> Bool {
        guard biometricEnabled else { return true }
        return await biometricService.authenticate(reason: "Authenticate to access this setting")
    }
}
