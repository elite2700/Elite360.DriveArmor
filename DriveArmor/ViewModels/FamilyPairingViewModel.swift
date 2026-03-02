// FamilyPairingViewModel.swift
// Elite360.DriveArmor
//
// Drives CreateFamilyView (parent) and JoinFamilyView (child).

import Foundation

@MainActor
final class FamilyPairingViewModel: ObservableObject {

    // MARK: - Published

    @Published var familyName: String = ""
    @Published var pairingCode: String = ""     // Displayed to parent / entered by child
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Services

    private let familyService = FamilyService()
    private let authService = AuthService()

    // MARK: - Parent: Create Family

    /// Parent creates a new family and receives a pairing code.
    func createFamily(appState: AppState) async {
        guard let user = appState.currentUser else { return }
        guard !familyName.trimmingCharacters(in: .whitespaces).isEmpty else {
            showErrorMessage("Enter a family name.")
            return
        }

        isLoading = true
        do {
            let family = try await familyService.createFamily(
                name: familyName.trimmingCharacters(in: .whitespaces),
                parentId: user.uid
            )
            pairingCode = family.pairingCode

            // Update local state
            var updatedUser = user
            updatedUser.familyId = family.id
            appState.currentFamily = family
            appState.resolveStage(for: updatedUser)
        } catch {
            showErrorMessage(error.localizedDescription)
        }
        isLoading = false
    }

    // MARK: - Child: Join Family

    /// Child enters a pairing code to join an existing family.
    func joinFamily(appState: AppState) async {
        guard let user = appState.currentUser else { return }
        let code = pairingCode.trimmingCharacters(in: .whitespaces).uppercased()
        guard code.count == 6 else {
            showErrorMessage("Enter the 6-character pairing code from your parent.")
            return
        }

        isLoading = true
        do {
            let family = try await familyService.joinFamily(childId: user.uid, pairingCode: code)

            var updatedUser = user
            updatedUser.familyId = family.id
            appState.currentFamily = family
            appState.resolveStage(for: updatedUser)
        } catch {
            showErrorMessage(error.localizedDescription)
        }
        isLoading = false
    }

    // MARK: - Regenerate Code

    func regenerateCode(familyId: String) async {
        isLoading = true
        do {
            pairingCode = try await familyService.regeneratePairingCode(familyId: familyId)
        } catch {
            showErrorMessage(error.localizedDescription)
        }
        isLoading = false
    }

    // MARK: - Helpers

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
