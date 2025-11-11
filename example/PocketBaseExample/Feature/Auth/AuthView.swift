//
//  AuthView.swift
//  PocketBaseExample
//
//  Created by Andrew Althage on 11/11/25.
//

import PocketBase
import SwiftUI

// MARK: - AuthView

struct AuthView: View {

    // MARK: Internal

    @Environment(\.pocketBase) var pocketBase

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if isAuthenticated {
                    AuthenticatedView(isAuthenticated: $isAuthenticated)
                } else {
                    LoginFormView(isAuthenticated: $isAuthenticated)
                }
            }
            .navigationDestination(for: AuthDestination.self) { destination in
                switch destination {
                case .reset:
                    ResetView()
                case .signUp:
                    SignUpView(isAuthenticated: $isAuthenticated)
                }
            }
        }
        .onAppear {
            isAuthenticated = pocketBase.isAuthenticated
        }
        .onChange(of: isAuthenticated) { _, newValue in
            // Clear navigation path when auth state changes
            if !newValue {
                path = NavigationPath()
            }
        }
    }

    // MARK: Private

    @State private var path = NavigationPath()
    @State private var isAuthenticated = false

}

#Preview("Logged Out") {
    AuthView()
}

// MARK: - AuthDestination

enum AuthDestination: Hashable {
    case reset, signUp
}
