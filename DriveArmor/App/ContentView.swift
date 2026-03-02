// ContentView.swift
// Elite360.DriveArmor
//
// Root view that routes to the correct experience based on AppState.authStage
// and the user's role (parent vs child).

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            switch appState.authStage {
            case .loading:
                LoadingView(message: "Starting DriveArmor…")

            case .unauthenticated:
                NavigationStack {
                    LoginView()
                }

            case .needsRole:
                NavigationStack {
                    RoleSelectionView()
                }

            case .needsPairing:
                NavigationStack {
                    if appState.currentUser?.role == .parent {
                        CreateFamilyView()
                    } else {
                        JoinFamilyView()
                    }
                }

            case .ready:
                if appState.currentUser?.role == .parent {
                    NavigationStack {
                        ParentDashboardView()
                    }
                } else {
                    NavigationStack {
                        ChildDashboardView()
                    }
                }
            }
        }
        .animation(.easeInOut, value: appState.authStage)
    }
}
