//
//  pb.swift
//  pocketbase-swift-sdk
//
//  Created by Andrew Althage on 7/12/25.
//

import Alamofire
import Foundation
import os

public typealias PBCollection = Decodable & Encodable & Sendable

// MARK: - Identifiable

public typealias PBIdentifiableCollection = PBBaseRecord & PBCollection

// MARK: - PBEmptyEntity

public struct PBEmptyEntity: Codable, EmptyResponse {

  public static func emptyValue() -> PBEmptyEntity {
    PBEmptyEntity()
  }
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

  /// Get current user ID
  public var currentUserId: String? {
    secureStorage.userId
  }

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
    let _: EmptyResponse = try await httpClient.delete(urlString, output: PBEmptyEntity.self).get()
  }

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
    let _: EmptyResponse = try await httpClient.delete(urlString, output: PBEmptyEntity.self).get()
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

