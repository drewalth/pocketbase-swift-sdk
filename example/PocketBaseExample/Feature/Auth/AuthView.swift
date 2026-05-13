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

    @PBAuthState private var auth

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if auth.isAuthenticated {
                    AuthenticatedView(onSignOut: { $auth.refresh() })
                } else {
                    LoginFormView(onLogin: { $auth.refresh() })
                }
            }
            .navigationDestination(for: AuthDestination.self) { destination in
                switch destination {
                case .reset:
                    ResetView()
                case .signUp:
                    SignUpView(onSignUp: { $auth.refresh() })
                }
            }
        }
        .onChange(of: auth.isAuthenticated) { _, newValue in
            if !newValue {
                path = NavigationPath()
            }
        }
    }

    // MARK: Private

    @State private var path = NavigationPath()
}

#Preview("Logged Out") {
    AuthView()
}

// MARK: - AuthDestination

enum AuthDestination: Hashable {
    case reset, signUp
}
