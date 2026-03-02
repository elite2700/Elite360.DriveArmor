// LoginView.swift
// Elite360.DriveArmor
//
// Email/password sign-in screen with navigation to sign-up.

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // MARK: - Logo / Title
            VStack(spacing: 8) {
                Image("DriveArmorLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 192, height: 192)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .accentColor.opacity(0.3), radius: 8, y: 4)

                Text("DriveArmor")
                    .font(.largeTitle.bold())

                Text("by The Elite360 Corporation")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Image("E360Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
            }
            .padding(.bottom, 32)

            // MARK: - Form
            VStack(spacing: 16) {
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)

                Button {
                    Task { await viewModel.signIn() }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Sign In")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.isLoginValid || viewModel.isLoading)

                Button("Forgot password?") {
                    Task { await viewModel.resetPassword() }
                }
                .font(.footnote)
            }
            .padding(.horizontal, 32)

            Spacer()

            // MARK: - Sign Up Link
            NavigationLink {
                SignUpView()
            } label: {
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    Text("Sign Up")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
            }
            .padding(.bottom, 24)
        }
        .alert("Notice", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AppState())
    }
}
