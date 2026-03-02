// SafeModeOverlayView.swift
// Elite360.DriveArmor
//
// Full-screen overlay shown on the child device when safe mode is active.
// Blocks interaction with other app content. Provides emergency override.

import SwiftUI

struct SafeModeOverlayView: View {
    let message: String?
    let onOverride: () -> Void

    @State private var showOverrideConfirm = false

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // MARK: - Icon
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.orange)

                // MARK: - Title
                Text("Safe Mode Active")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("Your device is in safe mode to keep you focused on driving.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Parent message
                if let message = message, !message.isEmpty {
                    VStack(spacing: 8) {
                        Text("From your parent:")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Text(""\(message)"")
                            .font(.body.italic())
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding(.horizontal, 24)
                }

                Spacer()

                // MARK: - Emergency info
                VStack(spacing: 8) {
                    Text("Emergency calls and navigation are still available")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))

                    Image(systemName: "phone.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }

                // MARK: - Override Button
                Button(role: .destructive) {
                    showOverrideConfirm = true
                } label: {
                    Label("Emergency Override", systemImage: "exclamationmark.shield.fill")
                        .foregroundStyle(.red)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 24)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .padding(.bottom, 40)
            }
        }
        .confirmationDialog(
            "Override Safe Mode?",
            isPresented: $showOverrideConfirm,
            titleVisibility: .visible
        ) {
            Button("Override (parent will be notified)", role: .destructive) {
                onOverride()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your parent will receive a notification that you overrode safe mode.")
        }
    }
}

#Preview {
    SafeModeOverlayView(
        message: "Focus on the road, please!",
        onOverride: {}
    )
}
