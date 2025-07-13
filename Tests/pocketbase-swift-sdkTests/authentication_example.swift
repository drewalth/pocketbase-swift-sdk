//
//  authentication_example.swift
//  pocketbase-swift-sdkTests
//
//  Created by Andrew Althage on 7/12/25.
//
import Testing
@testable import PocketBase

// MARK: - TestUser

// Define test models that conform to PBIdentifiableCollection
struct TestUser: PBIdentifiableCollection {
  let id: String
  let email: String
  let username: String?
  let name: String?
  let avatar: String?
  let verified: Bool
  let created: String
  let updated: String
  let collectionId: String
  let collectionName: String
}

// MARK: - TestAdmin

struct TestAdmin: PBIdentifiableCollection {
  let id: String
  let email: String
  let avatar: String?
  let created: String
  let updated: String
}

@Test("Authentication: Full user flow")
func authentication_user_flow() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
  var userId: String? = nil

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
    print("❌ Sign up failed: \(error)")
    // If user already exists, try to sign in instead
  }

  // Sign in with existing user
  do {
    let authResult = try await pb.authWithPassword(
      email: "new@drewalth.com",
      password: "password123",
      userType: TestUser.self)

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
    let refreshResult = try await pb.authRefresh(userType: TestUser.self)
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
    let _ = try await pb.requestPasswordReset(email: "test@example.com")
    print("✅ Password reset requested")
  } catch {
    print("❌ Password reset request failed: \(error)")
    #expect(false, "Password reset request should succeed")
  }

  // Request email verification
  do {
    let _ = try await pb.requestVerification(email: "test@example.com")
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
}

@Test("Authentication: State transitions")
func authentication_state_transitions() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
  #expect(!pb.isAuthenticated)
  #expect(!pb.isAdminAuthenticated)
  #expect(pb.currentUserId == nil)
  #expect(pb.currentAdminId == nil)

  // Sign in as user
  do {
    let _ = try await pb.authWithPassword(
      email: "test@example.com",
      password: "password123",
      userType: TestUser.self)
    #expect(pb.isAuthenticated)
    #expect(!pb.isAdminAuthenticated)
    #expect(pb.currentUserId != nil)
    #expect(pb.currentAdminId == nil)
    pb.signOut()
    #expect(!pb.isAuthenticated)
    #expect(!pb.isAdminAuthenticated)
    #expect(pb.currentUserId == nil)
    #expect(pb.currentAdminId == nil)
  } catch {
    print("❌ Authentication state test failed: \(error)")
    #expect(false, "User authentication should succeed")
  }
}
