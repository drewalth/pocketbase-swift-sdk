//
//  ResetView.swift
//  PocketBaseExample
//
//  Created by Andrew Althage on 11/11/25.
//

import PocketBase
import SwiftUI

struct ResetView: View {

    // MARK: Internal

    enum ResetAction: String, CaseIterable {
        case passwordReset = "Password Reset"
        case emailVerification = "Email Verification"
    }

    @Environment(\.pocketBase) var pocketBase
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section {
                Picker("Action", selection: $selectedAction) {
                    ForEach(ResetAction.allCases, id: \.self) { action in
                        Text(action.rawValue).tag(action)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
            } header: {
                Text("Enter your email address")
            } footer: {
                if selectedAction == .passwordReset {
                    Text("You will receive a password reset link via email")
                } else {
                    Text("You will receive a verification email")
                }
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
                        await performAction()
                    }
                } label: {
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("Sending...")
                        }
                    } else {
                        Text("Send Request")
                    }
                }
                .disabled(isLoading || email.isEmpty)
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Demo email:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("new@drewalth.com")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(selectedAction.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Success!", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            if selectedAction == .passwordReset {
                Text("Password reset email sent! Check your inbox.")
            } else {
                Text("Verification email sent! Check your inbox.")
            }
        }
    }

    // MARK: Private

    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var selectedAction: ResetAction = .passwordReset

    private func performAction() async {
        isLoading = true
        errorMessage = nil

        do {
            if selectedAction == .passwordReset {
                _ = try await pocketBase.requestPasswordReset(email: email)
                print("✅ Password reset requested")
            } else {
                _ = try await pocketBase.requestVerification(email: email)
                print("✅ Email verification requested")
            }

            showSuccess = true
            isLoading = false
        } catch {
            print("❌ Request failed: \(error)")
            errorMessage = "Request failed: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        ResetView()
    }
}
