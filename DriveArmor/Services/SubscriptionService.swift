// SubscriptionService.swift
// Elite360.DriveArmor
//
// Manages StoreKit 2 subscription purchases and syncs the active tier
// to the family's Firestore document.

import Foundation
import StoreKit
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
final class SubscriptionService: ObservableObject {

    // MARK: - Published

    @Published var currentTier: SubscriptionTier = .free
    @Published var subscriptionStatus: SubscriptionStatus = SubscriptionStatus()
    @Published var availableProducts: [Product] = []
    @Published var isPurchasing: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private

    private let db = Firestore.firestore()
    private var updateListenerTask: Task<Void, Error>?

    private static let allProductIds: [String] = [
        "com.elite360.DriveArmor.standard.monthly",
        "com.elite360.DriveArmor.standard.annual",
        "com.elite360.DriveArmor.premium.monthly",
        "com.elite360.DriveArmor.premium.annual",
        "com.elite360.DriveArmor.ultimate.monthly",
        "com.elite360.DriveArmor.ultimate.annual"
    ]

    // MARK: - Init

    init() {
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let products = try await Product.products(for: Self.allProductIds)
            availableProducts = products.sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Failed to load subscription options: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateSubscriptionFromTransaction(transaction)
                await transaction.finish()
                return true

            case .userCancelled:
                return false

            case .pending:
                return false

            @unknown default:
                return false
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshSubscriptionStatus()
    }

    // MARK: - Check Current Entitlements

    func refreshSubscriptionStatus() async {
        var highestTier: SubscriptionTier = .free

        for await result in StoreKit.Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                let tier = tierForProductId(transaction.productID)
                if tier > highestTier {
                    highestTier = tier
                }
            }
        }

        currentTier = highestTier
        subscriptionStatus.tier = highestTier
        subscriptionStatus.isActive = true

        // Sync to Firestore
        await syncTierToFirestore(highestTier)
    }

    // MARK: - Sync to Firestore

    /// Store the active tier in the family document so it's accessible family-wide.
    func syncTierToFirestore(_ tier: SubscriptionTier) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            // Get the user's familyId
            let userDoc = try await db.collection("users").document(uid).getDocument()
            guard let familyId = userDoc.data()?["familyId"] as? String else { return }

            try await db.collection("families").document(familyId).updateData([
                "subscription": subscriptionStatus.asDictionary
            ])
        } catch {
            print("[Subscription] Failed to sync tier: \(error.localizedDescription)")
        }
    }

    /// Load the subscription tier from the family document (for non-purchasing members).
    func loadTierFromFamily(familyId: String) async {
        do {
            let doc = try await db.collection("families").document(familyId).getDocument()
            if let subDict = doc.data()?["subscription"] as? [String: Any] {
                let status = SubscriptionStatus.from(dictionary: subDict)
                subscriptionStatus = status
                currentTier = status.tier
            }
        } catch {
            print("[Subscription] Failed to load family tier: \(error.localizedDescription)")
        }
    }

    // MARK: - Feature Gating

    func requiresTier(_ required: SubscriptionTier) -> Bool {
        currentTier >= required
    }

    func canAddDevice(currentCount: Int) -> Bool {
        currentCount < currentTier.maxDevices
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in StoreKit.Transaction.updates {
                if let transaction = try? self?.checkVerified(result) {
                    await self?.updateSubscriptionFromTransaction(transaction)
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - Helpers

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func updateSubscriptionFromTransaction(_ transaction: StoreKit.Transaction) async {
        let tier = tierForProductId(transaction.productID)
        currentTier = tier
        subscriptionStatus = SubscriptionStatus(
            tier: tier,
            isActive: transaction.revocationDate == nil,
            expiresAt: transaction.expirationDate,
            productId: transaction.productID,
            originalTransactionId: String(transaction.originalID)
        )
        await syncTierToFirestore(tier)
    }

    private func tierForProductId(_ productId: String) -> SubscriptionTier {
        if productId.contains("standard") { return .standard }
        if productId.contains("premium") { return .premium }
        if productId.contains("ultimate") { return .familyUltimate }
        return .free
    }
}

// MARK: - Errors

enum SubscriptionError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification: return "Transaction verification failed."
        }
    }
}
