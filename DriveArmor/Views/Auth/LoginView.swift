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
                Image(systemName: "car.front.waves.up.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.accent)

                Text("DriveArmor")
                    .font(.largeTitle.bold())

                Text("Keep your family safe on the road")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 40)

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
