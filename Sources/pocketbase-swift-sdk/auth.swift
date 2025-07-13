//
//  auth.swift
//  PocketBase
//
//  Created by Andrew Althage on 7/13/25.
//

extension PocketBase {
  // MARK: - Authentication Methods

  /// Authenticate a user with email and password
  public func authWithPassword<T: PBIdentifiableCollection>(
    email: String,
    password: String,
    userType _: T.Type)
    async throws -> AuthModel<T>
  {
    let urlString = "/api/collections/users/auth-with-password"
    let body: [String: String] = ["password": password, "identity": email]

    logger.info("POST \(urlString) - Authenticating user")
    let result: AuthModel<T> = try await httpClient.post(urlString, input: body, output: AuthModel<T>.self).get()

    print(result)

    // Store the token securely
    _ = secureStorage.storeUserToken(result.token, userId: result.record.id)

    return result
  }

  /// Create a new user account
  public func signUp<T: PBIdentifiableCollection>(dto: PBCreateUser, userType _: T.Type)
    async throws -> T
  {
    let urlString = "/api/collections/users/records"

    logger.info("POST \(urlString) - Creating new user account")
    let result: T = try await httpClient.post(urlString, input: dto, output: T.self).get()

    return result
  }

  /// Refresh the user authentication token
  public func authRefresh<T: PBIdentifiableCollection>(userType _: T.Type) async throws -> AuthRefreshResponse<T> {
    let urlString = "/api/collections/users/auth-refresh"

    logger.info("POST \(urlString) - Refreshing user auth token")
    let result: AuthRefreshResponse<T> = try await httpClient.post(
      urlString,
      input: PBEmptyEntity(),
      output: AuthRefreshResponse<T>.self).get()

    // Update the stored token securely
    _ = secureStorage.storeToken(result.token, for: "pocketbase_user_token")

    return result
  }

  /// Request password reset
  public func requestPasswordReset(email: String) async throws -> PBEmptyEntity {
    let urlString = "/api/collections/users/request-password-reset"
    let body = ["email": email]

    logger.info("POST \(urlString) - Requesting password reset")
    return try await httpClient.post(urlString, input: body, output: PBEmptyEntity.self).get()
  }

  /// Confirm password reset
  public func confirmPasswordReset(
    token: String,
    password: String,
    passwordConfirm: String)
    async throws -> PBEmptyEntity
  {
    let urlString = "/api/collections/users/confirm-password-reset"
    let body = [
      "token": token,
      "password": password,
      "passwordConfirm": passwordConfirm,
    ]

    logger.info("POST \(urlString) - Confirming password reset")
    return try await httpClient.post(urlString, input: body, output: PBEmptyEntity.self).get()
  }

  /// Request email verification
  public func requestVerification(email: String) async throws -> PBEmptyEntity {
    let urlString = "/api/collections/users/request-verification"
    let body = ["email": email]

    logger.info("POST \(urlString) - Requesting email verification")
    return try await httpClient.post(urlString, input: body, output: PBEmptyEntity.self).get()
  }

  /// Confirm email verification
  public func confirmVerification(token: String) async throws -> PBEmptyEntity {
    let urlString = "/api/collections/users/confirm-verification"
    let body = ["token": token]

    logger.info("POST \(urlString) - Confirming email verification")
    return try await httpClient.post(urlString, input: body, output: PBEmptyEntity.self).get()
  }

  /// Get available authentication methods
  public func getAuthMethods() async throws -> AuthMethodsList {
    let urlString = "/api/collections/users/auth-methods"

    logger.info("GET \(urlString) - Getting auth methods")
    return try await httpClient.get(urlString, output: AuthMethodsList.self).get()
  }

  /// Sign out (clear stored tokens)
  public func signOut() {
    secureStorage.clearAllTokens()
    logger.info("User signed out - tokens cleared from keychain")
  }
}
