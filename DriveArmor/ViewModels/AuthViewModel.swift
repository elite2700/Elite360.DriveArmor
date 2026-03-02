// AuthViewModel.swift
// Elite360.DriveArmor
//
// Drives LoginView and SignUpView. Wraps AuthService with @Published state
// for form fields, validation, loading, and error display.

import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Form Fields

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var displayName: String = ""

    // MARK: - UI State

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Services

    private let authService = AuthService()

    // MARK: - Validation

    var isLoginValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        password.count >= 6
    }

    var isSignUpValid: Bool {
        isLoginValid &&
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        password == confirmPassword
    }

    // MARK: - Actions

    /// Sign in with email and password.
    func signIn() async {
        guard isLoginValid else {
            showErrorMessage("Please fill in all fields. Password must be at least 6 characters.")
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            _ = try await authService.signIn(email: email.trimmingCharacters(in: .whitespaces),
                                             password: password)
            // Auth state listener in AppState will handle navigation
        } catch {
            showErrorMessage(error.localizedDescription)
        }
        isLoading = false
    }

    /// Create a new account.
    func signUp() async {
        guard isSignUpValid else {
            showErrorMessage("Please fill in all fields and ensure passwords match.")
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            _ = try await authService.signUp(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                displayName: displayName.trimmingCharacters(in: .whitespaces)
            )
        } catch {
            showErrorMessage(error.localizedDescription)
        }
        isLoading = false
    }

    /// Send a password reset email.
    func resetPassword() async {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            showErrorMessage("Enter your email address to reset your password.")
            return
        }

        isLoading = true
        do {
            try await authService.sendPasswordReset(email: email.trimmingCharacters(in: .whitespaces))
            showErrorMessage("Password reset email sent. Check your inbox.")
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

    func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        displayName = ""
        errorMessage = nil
        showError = false
    }
}
