// QRCodePairingView.swift
// Elite360.DriveArmor
//
// Generates or scans a QR code containing the family pairing code.
// Parent sees the QR code; Child can scan it or type manually.

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodePairingView: View {
    let pairingCode: String
    @State private var qrImage: UIImage?

    var body: some View {
        VStack(spacing: 24) {
            Text("Family Pairing Code")
                .font(.title2.bold())

            if let qrImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
            } else {
                ProgressView()
                    .frame(width: 220, height: 220)
            }

            Text(pairingCode)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .tracking(6)

            Text("Show this QR code to the child device, or share the code above.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            ShareLink(item: pairingCode) {
                Label("Share Code", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .navigationTitle("QR Pairing")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            qrImage = generateQRCode(from: pairingCode)
        }
    }

    // MARK: - QR Generation

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        let scale = 10.0
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Scanner (child side)

struct QRCodeScannerPlaceholderView: View {
    @Binding var scannedCode: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)

            Text("Camera QR scanning requires a physical device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Enter the code manually:")
                .font(.headline)

            TextField("Pairing Code", text: $scannedCode)
                .font(.system(.title2, design: .monospaced))
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.characters)
                .padding(.horizontal, 48)

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(scannedCode.count < 6)
        }
        .padding()
        .navigationTitle("Scan QR Code")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("QR Code") {
    NavigationStack {
        QRCodePairingView(pairingCode: "ABC123")
    }
}

#Preview("Scanner") {
    NavigationStack {
        QRCodeScannerPlaceholderView(scannedCode: .constant(""))
    }
}
