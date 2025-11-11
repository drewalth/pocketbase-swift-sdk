//
//  SignUpView.swift
//  PocketBaseExample
//
//  Created by Andrew Althage on 11/11/25.
//

import PocketBase
import SwiftUI

struct SignUpView: View {

    // MARK: Internal

    @Environment(\.pocketBase) var pocketBase
    @Environment(\.dismiss) var dismiss
    @Binding var isAuthenticated: Bool

    var body: some View {
        Form {
            Section {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                TextField("Name", text: $name)
                    .textContentType(.name)

                SecureField("Password", text: $password)
                    .textContentType(.newPassword)

                SecureField("Confirm Password", text: $passwordConfirm)
                    .textContentType(.newPassword)
            } header: {
                Text("Account Information")
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
                        await signUp()
                    }
                } label: {
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("Creating account...")
                        }
                    } else {
                        Text("Sign Up")
                    }
                }
                .disabled(isLoading || !isFormValid)
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Demo Credentials:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Email: new@drewalth.com")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("Password: password123")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Private

    @State private var email = ""
    @State private var name = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var isFormValid: Bool {
        !email.isEmpty &&
            !name.isEmpty &&
            !password.isEmpty &&
            password == passwordConfirm &&
            password.count >= 8
    }

    private func signUp() async {
        isLoading = true
        errorMessage = nil

        do {
            let createUserDto = CreateUser(
                email: email,
                name: name,
                password: password,
                passwordConfirm: passwordConfirm)

            let authResult = try await pocketBase.signUp(
                dto: createUserDto,
                userType: User.self)

            print("✅ User signed up successfully: \(authResult.id)")
            isLoading = false

            // Sign in the newly created user
            _ = try await pocketBase.authWithPassword(
                email: email,
                password: password,
                userType: User.self)

            isAuthenticated = true
            dismiss()
        } catch {
            print("❌ Sign up failed: \(error)")
            errorMessage = "Sign up failed: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView(isAuthenticated: .constant(false))
    }
}
