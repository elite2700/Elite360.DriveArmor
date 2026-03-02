// ErrorBanner.swift
// Elite360.DriveArmor
//
// Reusable inline error banner for non-blocking error display.

import SwiftUI

struct ErrorBanner: View {
    let message: String
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)

            Spacer()

            if let onDismiss = onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.9))
        )
        .padding(.horizontal)
    }
}

#Preview {
    VStack {
        ErrorBanner(message: "Network connection lost", onDismiss: {})
        ErrorBanner(message: "Failed to load data")
    }
}
