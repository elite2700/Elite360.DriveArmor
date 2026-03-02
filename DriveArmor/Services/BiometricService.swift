// BiometricService.swift
// Elite360.DriveArmor
//
// Wraps LocalAuthentication for Face ID / Touch ID gating on sensitive
// parent actions (viewing logs, unlinking devices, etc.).

import Foundation
import LocalAuthentication

final class BiometricService {

    enum BiometricType {
        case faceID, touchID, none
    }

    /// Returns the biometric type available on this device.
    var availableBiometric: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch context.biometryType {
        case .faceID:  return .faceID
        case .touchID: return .touchID
        default:       return .none
        }
    }

    /// Prompt the user for biometric authentication.
    /// Returns `true` if authentication succeeds.
    func authenticate(reason: String = "Authenticate to continue") async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch {
            print("[Biometric] Auth failed: \(error.localizedDescription)")
            return false
        }
    }
}
