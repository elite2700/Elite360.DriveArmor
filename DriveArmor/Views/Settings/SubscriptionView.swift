// SubscriptionView.swift
// Elite360.DriveArmor
//
// Paywall / subscription management screen. Shows tiers, current plan,
// and handles purchases via StoreKit 2.

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var subscriptionService = SubscriptionService()
    @State private var selectedTier: SubscriptionTier?
    @State private var billingPeriod: BillingPeriod = .monthly

    enum BillingPeriod: String, CaseIterable {
        case monthly = "Monthly"
        case annual = "Annual"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Current Plan
                currentPlanBanner

                // MARK: - Billing Toggle
                Picker("Billing", selection: $billingPeriod) {
                    ForEach(BillingPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // MARK: - Tier Cards
                ForEach(SubscriptionTier.allCases, id: \.self) { tier in
                    TierCard(
                        tier: tier,
                        isCurrentTier: tier == subscriptionService.currentTier,
                        billingPeriod: billingPeriod,
                        onSelect: {
                            selectedTier = tier
                            Task { await purchaseTier(tier) }
                        }
                    )
                }

                // MARK: - Restore
                Button("Restore Purchases") {
                    Task { await subscriptionService.restorePurchases() }
                }
                .font(.footnote)
                .padding(.top, 8)
            }
            .padding(.vertical)
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if subscriptionService.isPurchasing {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Processing…")
                    .padding()
                    .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .task {
            await subscriptionService.loadProducts()
            await subscriptionService.refreshSubscriptionStatus()
        }
        .alert("Error", isPresented: .constant(subscriptionService.errorMessage != nil)) {
            Button("OK") { subscriptionService.errorMessage = nil }
        } message: {
            Text(subscriptionService.errorMessage ?? "")
        }
    }

    // MARK: - Current Plan Banner

    private var currentPlanBanner: some View {
        VStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.largeTitle)
                .foregroundStyle(.yellow)

            Text(subscriptionService.currentTier.displayName)
                .font(.title2.bold())

            if let expires = subscriptionService.subscriptionStatus.expiresAt {
                Text("Renews \(expires.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.accentColor.opacity(0.08))
        )
        .padding(.horizontal)
    }

    // MARK: - Purchase

    private func purchaseTier(_ tier: SubscriptionTier) async {
        let productId: String?
        switch billingPeriod {
        case .monthly: productId = tier.monthlyProductId
        case .annual:  productId = tier.annualProductId
        }
        guard let productId,
              let product = subscriptionService.availableProducts.first(where: { $0.id == productId }) else {
            return
        }
        _ = await subscriptionService.purchase(product)
    }
}

// MARK: - Tier Card

private struct TierCard: View {
    let tier: SubscriptionTier
    let isCurrentTier: Bool
    let billingPeriod: SubscriptionView.BillingPeriod
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(tier.displayName)
                    .font(.headline)
                Spacer()
                Text(billingPeriod == .monthly ? tier.monthlyPrice : (tier.annualPrice ?? tier.monthlyPrice))
                    .font(.title3.bold())
                if billingPeriod == .monthly {
                    Text("/mo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("/yr")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(tier.features, id: \.self) { feature in
                Label(feature, systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }

            if isCurrentTier {
                Text("Current Plan")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            } else if tier != .free {
                Button {
                    onSelect()
                } label: {
                    Text("Subscribe")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: isCurrentTier ? .accentColor.opacity(0.3) : .black.opacity(0.06),
                        radius: isCurrentTier ? 4 : 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrentTier ? Color.accentColor : .clear, lineWidth: 2)
        )
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        SubscriptionView()
            .environmentObject(AppState())
    }
}
