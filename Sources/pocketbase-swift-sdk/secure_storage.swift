//
//  secure_storage.swift
//  pocketbase-swift-sdk
//
//  Created by Andrew Althage on 7/12/25.
//

import Foundation
import os
import Security

// MARK: - SecureStorage

public class SecureStorage: @unchecked Sendable {

  // MARK: Public

  /// Get user token
  public var userToken: String? {
    retrieveToken(for: Constants.userTokenKey)
  }

  /// Get user ID
  public var userId: String? {
    retrieveToken(for: Constants.userIdKey)
  }

  /// Get admin token
  public var adminToken: String? {
    retrieveToken(for: Constants.adminTokenKey)
  }

  /// Get admin ID
  public var adminId: String? {
    retrieveToken(for: Constants.adminIdKey)
  }

  /// Check if user is authenticated
  public var isUserAuthenticated: Bool {
    userToken != nil
  }

  /// Check if admin is authenticated
  public var isAdminAuthenticated: Bool {
    adminToken != nil
  }

  // MARK: - Public Methods

  /// Store a token securely in the keychain
  public func storeToken(_ token: String, for key: String) -> Bool {
    // In test environment, use UserDefaults directly to avoid keychain entitlement issues
    if isTestEnvironment {
      UserDefaults.standard.set(token, forKey: "test_\(key)")
      logger.info("Token stored in fallback storage for key: \(key) (test environment)")
      return true
    }

    // Try multiple accessibility levels for better compatibility
    let accessibilityLevels: [CFString] = [
      kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
      kSecAttrAccessibleWhenUnlocked,
      kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
      kSecAttrAccessibleAfterFirstUnlock,
    ]

    for accessibilityLevel in accessibilityLevels {
      let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: Constants.serviceName,
        kSecAttrAccount as String: key,
        kSecValueData as String: token.data(using: .utf8)!,
        kSecAttrAccessible as String: accessibilityLevel,
      ]

      // First, try to delete any existing item
      SecItemDelete(query as CFDictionary)

      // Then add the new item
      let status = SecItemAdd(query as CFDictionary, nil)

      if status == errSecSuccess {
        logger.info("Token stored successfully for key: \(key) with accessibility: \(accessibilityLevel)")
        return true
      } else if status == errSecDuplicateItem {
        // If item already exists, try to update it
        let updateQuery: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrService as String: Constants.serviceName,
          kSecAttrAccount as String: key,
        ]

        let updateAttributes: [String: Any] = [
          kSecValueData as String: token.data(using: .utf8)!,
          kSecAttrAccessible as String: accessibilityLevel,
        ]

        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        if updateStatus == errSecSuccess {
          logger.info("Token updated successfully for key: \(key) with accessibility: \(accessibilityLevel)")
          return true
        }
      }
    }

    logger.error("Failed to store token for key: \(key) in keychain")
    return false
  }

  /// Retrieve a token from the keychain
  public func retrieveToken(for key: String) -> String? {
    // In test environment, check UserDefaults first
    if isTestEnvironment {
      if let fallbackToken = UserDefaults.standard.string(forKey: "test_\(key)") {
        logger.info("Token retrieved from fallback storage for key: \(key) (test environment)")
        return fallbackToken
      }
      logger.warning("No token found in fallback storage for key: \(key) (test environment)")
      return nil
    }

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Constants.serviceName,
      kSecAttrAccount as String: key,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    if
      status == errSecSuccess,
      let data = result as? Data,
      let token = String(data: data, encoding: .utf8)
    {
      logger.info("Token retrieved successfully for key: \(key)")
      return token
    } else {
      logger.warning("No token found in keychain for key: \(key), status: \(status)")
      return nil
    }
  }

  /// Delete a token from the keychain
  public func deleteToken(for key: String) -> Bool {
    // In test environment, only delete from UserDefaults
    if isTestEnvironment {
      UserDefaults.standard.removeObject(forKey: "test_\(key)")
      logger.info("Token deleted from fallback storage for key: \(key) (test environment)")
      return true
    }

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Constants.serviceName,
      kSecAttrAccount as String: key,
    ]

    let status = SecItemDelete(query as CFDictionary)
    let keychainDeleted = status == errSecSuccess || status == errSecItemNotFound

    if keychainDeleted {
      logger.info("Token deleted successfully from keychain for key: \(key)")
    } else {
      logger.warning("Failed to delete token from keychain for key: \(key), status: \(status)")
    }

    return keychainDeleted
  }

  /// Clear all stored tokens
  public func clearAllTokens() {
    let keys = [
      Constants.userTokenKey,
      Constants.userIdKey,
      Constants.adminTokenKey,
      Constants.adminIdKey,
    ]

    for key in keys {
      _ = deleteToken(for: key)
    }

    logger.info("All tokens cleared from keychain and fallback storage")
  }

  /// Clear all fallback storage (useful for testing)
  public func clearFallbackStorage() {
    let keys = [
      Constants.userTokenKey,
      Constants.userIdKey,
      Constants.adminTokenKey,
      Constants.adminIdKey,
    ]

    for key in keys {
      UserDefaults.standard.removeObject(forKey: "test_\(key)")
    }

    logger.info("All fallback storage cleared")
  }

  // MARK: - Convenience Methods

  /// Store user token and ID
  public func storeUserToken(_ token: String, userId: String) -> Bool {
    let tokenStored = storeToken(token, for: Constants.userTokenKey)
    let idStored = storeToken(userId, for: Constants.userIdKey)
    return tokenStored && idStored
  }

  /// Store admin token and ID
  public func storeAdminToken(_ token: String, adminId: String) -> Bool {
    let tokenStored = storeToken(token, for: Constants.adminTokenKey)
    let idStored = storeToken(adminId, for: Constants.adminIdKey)
    return tokenStored && idStored
  }

  /// Clear user authentication
  public func clearUserAuth() {
    _ = deleteToken(for: Constants.userTokenKey)
    _ = deleteToken(for: Constants.userIdKey)
    logger.info("User authentication cleared")
  }

  /// Clear admin authentication
  public func clearAdminAuth() {
    _ = deleteToken(for: Constants.adminTokenKey)
    _ = deleteToken(for: Constants.adminIdKey)
    logger.info("Admin authentication cleared")
  }

  // MARK: Private

  // MARK: - Constants

  private enum Constants {
    static let userTokenKey = "pocketbase_user_token"
    static let userIdKey = "pocketbase_user_id"
    static let adminTokenKey = "pocketbase_admin_token"
    static let adminIdKey = "pocketbase_admin_id"
    static let serviceName = "io.pocketbase.swift.sdk"
  }

  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "io.pocketbase.swift.sdk",
    category: "SecureStorage")

  /// Check if we're running in a test environment
  private var isTestEnvironment: Bool {
    #if DEBUG
    return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    #else
    return false
    #endif
  }

}