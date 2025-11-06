//
//  authentication_example.swift
//  pocketbase-swift-sdkTests
//
//  Created by Andrew Althage on 7/12/25.
//
import Testing
@testable import PocketBase

@Suite("Authentication")
class Authentication {

    // MARK: Lifecycle

    deinit {
        // Note: deinit cannot be async, so we can't properly clean up here
        // The cleanup should be done in the test itself or using a separate cleanup method
    }

    // MARK: Internal

    @Test("Authentication: Full user flow")
    func authentication_user_flow() async throws {
        let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
        var userId: String?

        // Sign up a new user
        do {
            let createUserDto = CreateUser(
                email: "new@drewalth.com",
                name: "Test User",
                password: "password123",
                passwordConfirm: "password123")
            let authResult = try await pb.signUp(dto: createUserDto, userType: User.self)
            userId = authResult.id

            #expect(userId != nil)

            print("✅ User signed up successfully: \(userId ?? "nil")")
            #expect(pb.isAuthenticated)
            #expect(pb.currentUserId == userId)
        } catch {
            print("Sign up failed: \(error)")
            // If user already exists, try to sign in instead
        }

        // Sign in with existing user
        do {
            let authResult = try await pb.authWithPassword(
                email: "new@drewalth.com",
                password: "password123",
                userType: User.self)

            #expect(authResult.record.id != "")

            userId = authResult.record.id
            print("✅ User signed in successfully: \(userId ?? "nil")")
            #expect(pb.isAuthenticated)
            #expect(pb.currentUserId == userId)
        } catch {
            print("❌ Sign in failed: \(error)")
            #expect(false, "Sign in should succeed")
        }

        // Refresh authentication token
        do {
            let refreshResult = try await pb.authRefresh(userType: User.self)
            print("✅ Token refreshed: \(refreshResult.token)")
            #expect(pb.isAuthenticated)
        } catch {
            print("❌ Token refresh failed: \(error)")
            #expect(false, "Token refresh should succeed")
        }

        // Get authentication methods
        do {
            let authMethods = try await pb.getAuthMethods()
            print("✅ Auth methods: usernamePassword=\(authMethods)")
            #expect(authMethods.password.enabled, "Password auth method should be enabled")
        } catch {
            print("❌ Get auth methods failed: \(error)")
            #expect(false, "Get auth methods should succeed")
        }

        // Request password reset
        do {
            _ = try await pb.requestPasswordReset(email: "new@drewalth.com")
            print("✅ Password reset requested")
        } catch {
            print("❌ Password reset request failed: \(error)")
            #expect(false, "Password reset request should succeed")
        }

        // Request email verification
        do {
            _ = try await pb.requestVerification(email: "new@drewalth.com")
            print("✅ Email verification requested")
        } catch {
            print("❌ Email verification request failed: \(error)")
            #expect(false, "Email verification request should succeed")
        }

        // Sign out
        pb.signOut()
        print("✅ User signed out")
        #expect(!pb.isAuthenticated)
        #expect(pb.currentUserId == nil)

        // Clean up the test user
        await cleanupTestUser()
    }

    // MARK: Private

    private func cleanupTestUser() async {
        do {
            let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
            let userCollection: Collection<User> = pb.collection("users")

            // Try to find the user by email (not ID)
            let filter = FiltersQuery()
                .equal(field: "email", value: "new@drewalth.com")
            let users = try await userCollection.getList(filters: filter)

            if let user = users.items.first {
                try await userCollection.delete(id: user.id)
                print("✅ Test user deleted: \(user.id)")
            } else {
                print("ℹ️ Test user not found, may have been already deleted")
            }

            // clear all tokens
            let secureStorage = SecureStorage()
            secureStorage.clearAllTokens()
            secureStorage.clearFallbackStorage()
            print("✅ Tokens cleared")
        } catch {
            print("❌ Cleanup failed: \(error)")
        }
    }

}
