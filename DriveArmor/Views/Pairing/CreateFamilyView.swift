// CreateFamilyView.swift
// Elite360.DriveArmor
//
// Parent enters a family name → creates the family → receives a pairing code.

import SwiftUI

struct CreateFamilyView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = FamilyPairingViewModel()

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "house.fill")
                .font(.system(size: 56))
                .foregroundStyle(.accent)

            Text("Create Your Family")
                .font(.title2.bold())

            Text("Set up a family group so your children can connect their devices.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // MARK: - Name Input
            TextField("Family Name (e.g. Smith Family)", text: $viewModel.familyName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 32)

            // MARK: - Create Button
            Button {
                Task { await viewModel.createFamily(appState: appState) }
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Create Family")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.familyName.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
            .padding(.horizontal, 32)

            // MARK: - Pairing Code (shown after creation)
            if !viewModel.pairingCode.isEmpty {
                VStack(spacing: 8) {
                    Text("Share this code with your child:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(viewModel.pairingCode)
                        .font(.system(.largeTitle, design: .monospaced).bold())
                        .kerning(6)
                        .foregroundStyle(.accent)

                    NavigationLink("Show QR Code") {
                        QRCodePairingView(pairingCode: viewModel.pairingCode)
                    }
                    .font(.subheadline)
                    .padding(.top, 4)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor.opacity(0.08))
                )
                .padding(.horizontal, 32)
            }

            Spacer()
        }
        .navigationTitle("Family Setup")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        CreateFamilyView()
            .environmentObject(AppState())
    }
}
