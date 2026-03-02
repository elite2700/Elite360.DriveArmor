// JoinFamilyView.swift
// Elite360.DriveArmor
//
// Child enters the 6-character pairing code provided by their parent
// to join an existing family group.

import SwiftUI

struct JoinFamilyView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = FamilyPairingViewModel()
    @State private var showQRScanner = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "link.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            Text("Join Your Family")
                .font(.title2.bold())

            Text("Ask your parent for the 6-character pairing code and enter it below.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // MARK: - Code Input
            TextField("Pairing Code", text: $viewModel.pairingCode)
                .font(.system(.title2, design: .monospaced))
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
                .padding(.horizontal, 64)

            // MARK: - Join Button
            Button {
                Task { await viewModel.joinFamily(appState: appState) }
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Join Family")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(viewModel.pairingCode.count != 6 || viewModel.isLoading)
            .padding(.horizontal, 32)

            // MARK: - QR Code Option
            Button {
                showQRScanner = true
            } label: {
                Label("Scan QR Code Instead", systemImage: "qrcode.viewfinder")
            }
            .font(.subheadline)

            Spacer()
        }
        .navigationTitle("Join Family")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showQRScanner) {
            NavigationStack {
                QRCodeScannerPlaceholderView(scannedCode: $viewModel.pairingCode)
            }
        }
    }
}

#Preview {
    NavigationStack {
        JoinFamilyView()
            .environmentObject(AppState())
    }
}
