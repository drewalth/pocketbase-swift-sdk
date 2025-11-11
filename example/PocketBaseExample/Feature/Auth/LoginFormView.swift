//
//  LoginFormView.swift
//  PocketBaseExample
//
//  Created by Andrew Althage on 11/11/25.
//

import PocketBase
import SwiftUI

struct LoginFormView: View {

    // MARK: Internal

    @Environment(\.pocketBase) var pocketBase
    @Binding var isAuthenticated: Bool

    var body: some View {
        Form {
            Section {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                SecureField("Password", text: $password)
                    .textContentType(.password)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            Section {
                Button {
                    Task {
                        await login()
                    }
                } label: {
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("Logging in...")
                        }
                    } else {
                        Text("Login")
                    }
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty)

                NavigationLink("Forgot Password?", value: AuthDestination.reset)

                NavigationLink("Create Account", value: AuthDestination.signUp)
            }
        }
        .navigationTitle("Login")
    }

    // MARK: Private

    @State private var email = "new@drewalth.com"
    @State private var password = "password123"
    @State private var isLoading = false
    @State private var errorMessage: String?

    private func login() async {
        isLoading = true
        errorMessage = nil

        do {
            let authResult = try await pocketBase.authWithPassword(
                email: email,
                password: password,
                userType: User.self)

            print("✅ User signed in successfully: \(authResult.record.id)")
            isLoading = false
            isAuthenticated = true
        } catch {
            print("❌ Sign in failed: \(error)")
            errorMessage = "Login failed: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        LoginFormView(isAuthenticated: .constant(false))
    }
}
