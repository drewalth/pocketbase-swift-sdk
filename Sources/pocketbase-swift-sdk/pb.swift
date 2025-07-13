//
//  pb.swift
//  pocketbase-swift-sdk
//
//  Created by Andrew Althage on 7/12/25.
//

import Foundation
import os

public typealias PBCollection = Decodable & Encodable & Sendable

// MARK: - Identifiable

public typealias PBIdentifiableCollection = PBBaseRecord & PBCollection

// MARK: - EmptyResponse

public struct EmptyResponse: Decodable, Encodable, Sendable {
  // Empty response for operations that don't return data
}

// MARK: - PBListResponse

public struct PBListResponse<T: PBCollection>: PBCollection {
  public let page: Int
  public let perPage: Int
  public let totalItems: Int
  public let totalPages: Int
  public let items: [T]
}

// MARK: - AuthModel

public struct AuthModel<T: PBCollection>: PBCollection {
  public let token: String
  public let record: T
  public let meta: AuthMeta?
}

// MARK: - AuthMeta

public struct AuthMeta: PBCollection {
  public let id: String
  public let name: String
  public let username: String?
  public let email: String
  public let avatarUrl: String?
  public let created: String
  public let updated: String
  public let verified: Bool
  public let lastResetSentAt: String?
  public let lastVerificationSentAt: String?
}

// MARK: - AuthRefreshResponse

public struct AuthRefreshResponse<T: PBIdentifiableCollection>: PBCollection {
  public let token: String
  public let record: T
}

// MARK: - AuthMethodsList

public struct AuthMethodsList: PBCollection {
  public let password: PasswordAuthentication
}

// MARK: - PasswordAuthentication

public struct PasswordAuthentication: PBCollection {
  public let enabled: Bool
  public let identityFields: [String]
}

// MARK: - PocketBase

public class PocketBase {

  // MARK: Lifecycle

  public init(baseURL: String) {
    self.baseURL = baseURL
    httpClient = HttpClient(baseUrl: baseURL)
  }

  // MARK: Public

  /// Check if user is authenticated
  public var isAuthenticated: Bool {
    secureStorage.isUserAuthenticated
  }

  /// Check if admin is authenticated
  public var isAdminAuthenticated: Bool {
    secureStorage.isAdminAuthenticated
  }

  /// Get current user ID
  public var currentUserId: String? {
    secureStorage.userId
  }

  /// Get current admin ID
  public var currentAdminId: String? {
    secureStorage.adminId
  }

//  // MARK: - Authentication Methods
//
//  /// Authenticate a user with email/username and password
//  public func authWithPassword<T: PBIdentifiableCollection>(
//    email: String? = nil,
//    username: String? = nil,
//    password: String,
//    userType _: T.Type)
//    async throws -> AuthModel<T>
//  {
//    let urlString = "/api/collections/users/auth-with-password"
//    let body: [String: String] = {
//      var body: [String: String] = ["password": password]
//      if let email {
//        body["email"] = email
//      }
//      if let username {
//        body["username"] = username
//      }
//      return body
//    }()
//
//    logger.info("POST \(urlString) - Authenticating user")
//    let result: AuthModel<T> = try await httpClient.post(urlString, input: body, output: AuthModel<T>.self).get()
//
//    print(result)
//
//    // Store the token securely
//    _ = secureStorage.storeUserToken(result.token, userId: result.record.id)
//
//    return result
//  }
//
//  /// Authenticate an admin with email and password
//  public func authWithPassword<T: PBIdentifiableCollection>(
//    email: String,
//    password: String,
//    adminType _: T.Type)
//    async throws -> AuthModel<T>
//  {
//    let urlString = "/api/collections/users/auth-with-password"
//    let body = ["identity": email, "password": password]
//
//    logger.info("POST \(urlString) - Authenticating admin")
//    let result: AuthModel<T> = try await httpClient.post(urlString, input: body, output: AuthModel<T>.self).get()
//
//    // Store the token securely
//    _ = secureStorage.storeAdminToken(result.token, adminId: result.record.id)
//
//    return result
//  }
//
//  /// Create a new user account
//  public func signUp<T: PBIdentifiableCollection>(
//    email: String,
//    password: String,
//    passwordConfirm: String,
//    username: String? = nil,
//    name: String? = nil,
//    userType _: T.Type)
//    async throws -> T
//  {
//    let urlString = "/api/collections/users/records"
//    let body: [String: String] = {
//      var body: [String: String] = [
//        "identity": email,
//        "password": password,
//        "passwordConfirm": passwordConfirm,
//      ]
//      if let username {
//        body["username"] = username
//      }
//      if let name {
//        body["name"] = name
//      }
//      return body
//    }()
//
//    logger.info("POST \(urlString) - Creating new user account")
//    let result: T = try await httpClient.post(urlString, input: body, output: T.self).get()
//
//    return result
//  }
//
//  /// Refresh the user authentication token
//  public func authRefresh<T: PBIdentifiableCollection>(userType _: T.Type) async throws -> AuthRefreshResponse<T> {
//    let urlString = "/api/collections/users/auth-refresh"
//
//    logger.info("POST \(urlString) - Refreshing user auth token")
//    let result: AuthRefreshResponse<T> = try await httpClient.post(
//      urlString,
//      input: EmptyResponse(),
//      output: AuthRefreshResponse<T>.self).get()
//
//    // Update the stored token securely
//    _ = secureStorage.storeToken(result.token, for: "pocketbase_user_token")
//
//    return result
//  }
//
//  /// Refresh the admin authentication token
//  public func authRefreshAdmin<T: PBIdentifiableCollection>(adminType _: T.Type) async throws -> AuthModel<T> {
//    let urlString = "/api/admins/auth-refresh"
//
//    logger.info("POST \(urlString) - Refreshing admin auth token")
//    let result: AuthModel<T> = try await httpClient.post(urlString, input: EmptyResponse(), output: AuthModel<T>.self)
//      .get()
//
//    // Update the stored token securely
//    _ = secureStorage.storeToken(result.token, for: "pocketbase_admin_token")
//
//    return result
//  }
//
//  /// Request password reset
//  public func requestPasswordReset(email: String) async throws -> EmptyResponse {
//    let urlString = "/api/collections/users/request-password-reset"
//    let body = ["email": email]
//
//    logger.info("POST \(urlString) - Requesting password reset")
//    return try await httpClient.post(urlString, input: body, output: EmptyResponse.self).get()
//  }
//
//  /// Confirm password reset
//  public func confirmPasswordReset(
//    token: String,
//    password: String,
//    passwordConfirm: String)
//    async throws -> EmptyResponse
//  {
//    let urlString = "/api/collections/users/confirm-password-reset"
//    let body = [
//      "token": token,
//      "password": password,
//      "passwordConfirm": passwordConfirm,
//    ]
//
//    logger.info("POST \(urlString) - Confirming password reset")
//    return try await httpClient.post(urlString, input: body, output: EmptyResponse.self).get()
//  }
//
//  /// Request email verification
//  public func requestVerification(email: String) async throws -> EmptyResponse {
//    let urlString = "/api/collections/users/request-verification"
//    let body = ["email": email]
//
//    logger.info("POST \(urlString) - Requesting email verification")
//    return try await httpClient.post(urlString, input: body, output: EmptyResponse.self).get()
//  }
//
//  /// Confirm email verification
//  public func confirmVerification(token: String) async throws -> EmptyResponse {
//    let urlString = "/api/collections/users/confirm-verification"
//    let body = ["token": token]
//
//    logger.info("POST \(urlString) - Confirming email verification")
//    return try await httpClient.post(urlString, input: body, output: EmptyResponse.self).get()
//  }
//
//  /// Get available authentication methods
//  public func getAuthMethods() async throws -> AuthMethodsList {
//    let urlString = "/api/collections/users/auth-methods"
//
//    logger.info("GET \(urlString) - Getting auth methods")
//    return try await httpClient.get(urlString, output: AuthMethodsList.self).get()
//  }
//
//  /// Sign out (clear stored tokens)
//  public func signOut() {
//    secureStorage.clearAllTokens()
//    logger.info("User signed out - tokens cleared from keychain")
//  }

  // MARK: - CRUD Operations

  public func getOne<Output: PBCollection>(
    id: String,
    collection: String,
    model: Output.Type,
    expand _: String? = nil)
    async throws -> Output
  {
    let urlString = "/api/collections/\(collection)/records/\(id)"
    logger.info("GET \(urlString)")
    return try await httpClient.get(urlString, output: model).get()
  }

  public func getList<T: PBCollection>(
    collection: String,
    model _: T.Type,
    expand: String? = nil,
    page: Int = 1,
    perPage: Int = 100)
    async throws -> PBListResponse<T>
  {
    let baseURLString = "/api/collections/\(collection)/records"
    let queryItems = {
      var baseQueryItems: [URLQueryItem] = [
        URLQueryItem(name: "page", value: "\(page)"),
        URLQueryItem(name: "perPage", value: "\(perPage)"),
      ]

      if let expand {
        baseQueryItems.append(URLQueryItem(name: "expand", value: expand))
      }
      return baseQueryItems
    }()

    var url = URLComponents(string: baseURLString)


    guard url != nil else {
      throw URLError(.badURL)
    }

    url?.queryItems = queryItems

    guard let urlString = url?.string else {
      throw URLError(.badURL)
    }
    logger.info("GET \(urlString)")
    return try await httpClient.get(urlString, output: PBListResponse<T>.self).get()
  }

  public func create<Output: Decodable & Sendable>(
    collection: String,
    record: some Encodable & Sendable,
    output: Output.Type)
    async throws -> Output
  {
    let urlString = "/api/collections/\(collection)/records"
    logger.info("POST \(urlString)")
    return try await httpClient.post(urlString, input: record, output: output).get()
  }

  public func update<T: PBCollection>(
    collection: String,
    id: String,
    record: T)
    async throws -> T
  {
    let urlString = "/api/collections/\(collection)/records/\(id)"
    logger.info("PATCH \(urlString)")
    return try await httpClient.patch(urlString, input: record, output: T.self).get()
  }

  public func delete(
    collection: String,
    id: String)
    async throws
  {
    let urlString = "/api/collections/\(collection)/records/\(id)"
    logger.info("DELETE \(urlString)")
    let _: EmptyResponse = try await httpClient.delete(urlString, output: EmptyResponse.self).get()
  }

//  // MARK: - Realtime
//
//  public func realtime<T: PBCollection>(
//    collection: String,
//    record: String = "*",
//    onConnect: @escaping () -> Void,
//    onDisconnect: @escaping () -> Void,
//    onEvent: @escaping (RealtimeEvent<T>) -> Void)
//    -> Realtime<T>
//  {
//    Realtime(
//      baseURL: baseURL,
//      collection: collection,
//      record: record,
//      onConnect: onConnect,
//      onDisconnect: onDisconnect,
//      onEvent: onEvent)
//  }
//
//  public func realtime<T: PBCollection>(
//    collection: String,
//    record: String = "*",
//    onEvent: @escaping (RealtimeEvent<T>) -> Void)
//    -> Realtime<T>
//  {
//    Realtime(
//      baseURL: baseURL,
//      collection: collection,
//      record: record,
//      onConnect: { },
//      onDisconnect: { },
//      onEvent: onEvent)
//  }

  public func collection<T: PBCollection>(_ name: String) -> Collection<T> {
    Collection(baseURL: baseURL, collectionName: name)
  }

  // MARK: Internal

  let baseURL: String
  var httpClient: HttpClient
  let secureStorage = SecureStorage()
  let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "io.pocketbase.swift.sdk", category: "PocketBase")

}

// MARK: - Collection

public class Collection<T: PBCollection> {

  // MARK: Lifecycle

  init(baseURL: String, collectionName: String) {
    self.baseURL = baseURL
    self.collectionName = collectionName
    httpClient = HttpClient(baseUrl: baseURL)
  }

  // MARK: Public

  public func getOne(
    id: String,
    expand _: String? = nil)
    async throws -> T
  {
    let urlString = "/api/collections/\(collectionName)/records/\(id)"
    logger.info("GET \(urlString)")
    return try await httpClient.get(urlString, output: T.self).get()
  }

  public func getList(
    expand: String? = nil,
    page: Int = 1,
    perPage: Int = 100)
    async throws -> PBListResponse<T>
  {
    let baseURLString = "/api/collections/\(collectionName)/records"
    let queryItems = {
      var baseQueryItems: [URLQueryItem] = [
        URLQueryItem(name: "page", value: "\(page)"),
        URLQueryItem(name: "perPage", value: "\(perPage)"),
      ]

      if let expand {
        baseQueryItems.append(URLQueryItem(name: "expand", value: expand))
      }
      return baseQueryItems
    }()

    var url = URLComponents(string: baseURLString)

    guard url != nil else {
      throw URLError(.badURL)
    }

    url?.queryItems = queryItems

    guard let urlString = url?.string else {
      throw URLError(.badURL)
    }
    logger.info("GET \(urlString)")
    return try await httpClient.get(urlString, output: PBListResponse<T>.self).get()
  }

  public func create<Output: Decodable & Sendable>(
    record: some Encodable & Sendable,
    output: Output.Type)
    async throws -> Output
  {
    let urlString = "/api/collections/\(collectionName)/records"
    logger.info("POST \(urlString)")
    return try await httpClient.post(urlString, input: record, output: output).get()
  }

  public func update(
    id: String,
    record: T)
    async throws -> T
  {
    let urlString = "/api/collections/\(collectionName)/records/\(id)"
    logger.info("PATCH \(urlString)")
    return try await httpClient.patch(urlString, input: record, output: T.self).get()
  }

  public func delete(
    id: String)
    async throws
  {
    let urlString = "/api/collections/\(collectionName)/records/\(id)"
    logger.info("DELETE \(urlString)")
    let _: EmptyResponse = try await httpClient.delete(urlString, output: EmptyResponse.self).get()
  }

  public func realtime(
    record: String = "*",
    onConnect: @escaping () -> Void,
    onDisconnect: @escaping () -> Void,
    onEvent: @escaping (RealtimeEvent<T>) -> Void)
    -> Realtime<T>
  {
    Realtime(
      baseURL: baseURL,
      collection: collectionName,
      record: record,
      onConnect: onConnect,
      onDisconnect: onDisconnect,
      onEvent: onEvent)
  }

  public func realtime(
    record: String = "*",
    onEvent: @escaping (RealtimeEvent<T>) -> Void)
    -> Realtime<T>
  {
    Realtime(
      baseURL: baseURL,
      collection: collectionName,
      record: record,
      onConnect: { },
      onDisconnect: { },
      onEvent: onEvent)
  }

  // MARK: Private

  private let baseURL: String
  private let collectionName: String
  private let httpClient: HttpClient
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "io.pocketbase.swift.sdk",
    category: "PocketBase.Collection")

}

