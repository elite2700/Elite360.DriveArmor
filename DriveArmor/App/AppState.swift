// AppState.swift
// Elite360.DriveArmor
//
// Global observable state that drives top-level navigation.
// Publishes the current authentication status and the user's role so
// ContentView can route to the correct experience.

import Foundation
import Combine
import FirebaseAuth

/// Represents the top-level authentication / onboarding stage.
enum AuthStage {
    case loading        // Checking persisted session
    case unauthenticated
    case needsRole      // Authenticated but role not yet chosen
    case needsPairing   // Role chosen but no family linked
    case ready          // Fully onboarded
}

final class AppState: ObservableObject {

    // MARK: - Published Properties

    @Published var authStage: AuthStage = .loading
    @Published var currentUser: UserModel?
    @Published var currentFamily: FamilyModel?

    // MARK: - Services

    let authService = AuthService()
    let familyService = FamilyService()

    // MARK: - Private

    private var cancellables = Set<AnyCancellable>()
    private var authHandle: AuthStateDidChangeListenerHandle?

    // MARK: - Init

    init() {
        listenForAuthChanges()
    }

    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Auth Listener

    /// Observes Firebase Auth state and resolves the user's profile + family.
    private func listenForAuthChanges() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self = self else { return }

            guard let firebaseUser = firebaseUser else {
                DispatchQueue.main.async {
                    self.currentUser = nil
                    self.currentFamily = nil
                    self.authStage = .unauthenticated
                }
                return
            }

            // Fetch the Firestore user profile
            Task { @MainActor in
                do {
                    if let user = try await self.authService.fetchUserProfile(uid: firebaseUser.uid) {
                        self.currentUser = user
                        self.resolveStage(for: user)
                    } else {
                        // Authenticated but no Firestore profile yet (fresh signup)
                        self.currentUser = UserModel(
                            uid: firebaseUser.uid,
                            email: firebaseUser.email ?? "",
                            displayName: firebaseUser.displayName ?? ""
                        )
                        self.authStage = .needsRole
                    }
                } catch {
                    print("[AppState] Error fetching profile: \(error.localizedDescription)")
                    self.authStage = .unauthenticated
                }
            }
        }
    }

    // MARK: - Stage Resolution

    /// Determine the correct stage based on the user profile.
    @MainActor
    func resolveStage(for user: UserModel) {
        currentUser = user

        guard user.role != nil else {
            authStage = .needsRole
            return
        }
        guard let familyId = user.familyId, !familyId.isEmpty else {
            authStage = .needsPairing
            return
        }

        // Fetch the family document
        Task {
            do {
                let family = try await familyService.fetchFamily(id: familyId)
                self.currentFamily = family
                self.authStage = .ready
            } catch {
                print("[AppState] Error fetching family: \(error.localizedDescription)")
                self.authStage = .needsPairing
            }
        }
    }

    // MARK: - Sign Out

    @MainActor
    func signOut() {
        try? Auth.auth().signOut()
        currentUser = nil
        currentFamily = nil
        authStage = .unauthenticated
    }

    // MARK: - Convenience Accessors

    var userId: String? { currentUser?.uid }
    var familyId: String? { currentFamily?.id }
    var userRole: UserRole? { currentUser?.role }

    // MARK: - Role Switching

    /// Switch current user between parent/child role and persist to Firestore.
    @MainActor
    func switchRole(to newRole: UserRole) async throws {
        guard let uid = currentUser?.uid else { return }
        try await authService.updateProfile(uid: uid, fields: ["role": newRole.rawValue])
        currentUser?.role = newRole
        // Re-resolve stage (may require new pairing)
        if let user = currentUser {
            resolveStage(for: user)
        }
    }
}
