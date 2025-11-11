//
//  AuthenticatedView.swift
//  PocketBaseExample
//
//  Created by Andrew Althage on 11/11/25.
//
import PocketBase
import SwiftUI

// MARK: - AuthenticatedView

struct AuthenticatedView: View {

    // MARK: Internal

    @Environment(\.pocketBase) var pocketBase
    @Binding var isAuthenticated: Bool

    var body: some View {
        Form {
            // User Info Section
            Section {
                if let user = currentUser {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)

                            VStack(alignment: .leading) {
                                if let name = user.name {
                                    Text(name)
                                        .font(.headline)
                                }
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Divider()

                        LabeledContent("User ID", value: user.id)
                            .font(.caption)

                        LabeledContent("Verified", value: user.verified ? "✅ Yes" : "❌ No")
                            .font(.caption)

                        LabeledContent("Created", value: formatDate(user.created))
                            .font(.caption)
                    }
                } else {
                    HStack {
                        ProgressView()
                        Text("Loading user info...")
                    }
                }
            } header: {
                Text("User Profile")
            }

            // Auth Actions Section
            Section {
                Button {
                    Task {
                        await refreshToken()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Token")
                        Spacer()
                        if isRefreshing {
                            ProgressView()
                        }
                    }
                }
                .disabled(isRefreshing)

                Button {
                    Task {
                        await loadAuthMethods()
                    }
                } label: {
                    HStack {
                        Image(systemName: "key.fill")
                        Text("Get Auth Methods")
                        Spacer()
                        if isLoadingAuthMethods {
                            ProgressView()
                        }
                    }
                }
                .disabled(isLoadingAuthMethods)
            } header: {
                Text("Auth Actions")
            }

            // Auth Methods Info
            if let authMethods {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: authMethods.password.enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(authMethods.password.enabled ? .green : .red)
                            Text("Password Authentication")
                            Spacer()
                            Text(authMethods.password.enabled ? "Enabled" : "Disabled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if !authMethods.password.identityFields.isEmpty {
                            Divider()
                            Text("Identity Fields:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ForEach(authMethods.password.identityFields, id: \.self) { field in
                                HStack {
                                    Image(systemName: "person.text.rectangle")
                                        .foregroundColor(.blue)
                                    Text(field)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Available Auth Methods")
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            // Sign Out Section
            Section {
                Button(role: .destructive) {
                    showLogoutConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                }
            }
        }
        .navigationTitle("Account")
        .task {
            await loadCurrentUser()
        }
        .confirmationDialog("Sign Out", isPresented: $showLogoutConfirm) {
            Button("Sign Out", role: .destructive) {
                signOut()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    // MARK: Private

    @State private var currentUser: User?
    @State private var isRefreshing = false
    @State private var authMethods: AuthMethodsList?
    @State private var isLoadingAuthMethods = false
    @State private var showLogoutConfirm = false
    @State private var errorMessage: String?

    private func loadCurrentUser() async {
        guard let userId = pocketBase.currentUserId else { return }

        do {
            let userCollection: Collection<User> = pocketBase.collection("users")
            currentUser = try await userCollection.getOne(id: userId)
            print("✅ Loaded current user: \(userId)")
        } catch {
            print("❌ Failed to load user: \(error)")
            errorMessage = "Failed to load user: \(error.localizedDescription)"
        }
    }

    private func refreshToken() async {
        isRefreshing = true
        errorMessage = nil

        do {
            let refreshResult = try await pocketBase.authRefresh(userType: User.self)
            print("✅ Token refreshed: \(refreshResult.token)")
            currentUser = refreshResult.record
            isRefreshing = false
        } catch {
            print("❌ Token refresh failed: \(error)")
            errorMessage = "Token refresh failed: \(error.localizedDescription)"
            isRefreshing = false
        }
    }

    private func loadAuthMethods() async {
        isLoadingAuthMethods = true
        errorMessage = nil

        do {
            authMethods = try await pocketBase.getAuthMethods()
            print("✅ Auth methods loaded: password=\(authMethods?.password.enabled ?? false)")
            isLoadingAuthMethods = false
        } catch {
            print("❌ Get auth methods failed: \(error)")
            errorMessage = "Get auth methods failed: \(error.localizedDescription)"
            isLoadingAuthMethods = false
        }
    }

    private func signOut() {
        pocketBase.signOut()
        print("✅ User signed out")
        currentUser = nil
        authMethods = nil
        isAuthenticated = false
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

#Preview("Logged In") {
    @Previewable @State var isAuthenticated = true
    AuthenticatedView(isAuthenticated: $isAuthenticated)
}
