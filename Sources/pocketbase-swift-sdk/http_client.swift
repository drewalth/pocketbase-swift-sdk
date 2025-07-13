//
//  http_client.swift
//  pocketbase-swift-sdk
//
//  Created by Andrew Althage on 7/12/25.
//

import Alamofire
import Foundation
@preconcurrency import os

public typealias NetworkError = AFError

// MARK: - HttpClient

struct HttpClient {

  // MARK: Lifecycle

  init(baseUrl: String) {
    self.baseUrl = baseUrl
    secureStorage = SecureStorage()
  }

  // MARK: Internal

  let sessionManager: Session = {
    let cacher = ResponseCacher(behavior: .cache)
    let configuration = URLSessionConfiguration.af.default

    return Session(
      configuration: configuration,
      delegate: SessionDelegate(),
      cachedResponseHandler: cacher)
  }()

  /// Submits HTTP GET request
  func get<Output: Decodable & Sendable>(
    _ url: String,
    output _: Output.Type)
    async -> Result<Output, NetworkError>
  {
    print(baseUrl + url)
    let task = sessionManager.request(baseUrl + url, interceptor: self).validate().serializingDecodable(Output.self)
    return await task.result
  }

  /// Submits HTTP POST request
  func post<Output: Decodable & Sendable>(
    _ url: String,
    input: some Encodable & Sendable,
    output _: Output.Type)
    async -> Result<Output, NetworkError> where Output: Decodable
  {
    let task = sessionManager.request(
      baseUrl + url,
      method: .post,
      parameters: input,
      encoder: .json,
      headers: [
        .init(name: "Content-Type", value: "application/json"),
      ],
      interceptor: self)
      .validate().serializingDecodable(Output.self, emptyResponseCodes: [200, 204, 205])
    return await task.result
  }

  /// Submits HTTP DELETE request
  func delete<Output: Decodable & Sendable>(_ url: String, output _: Output.Type) async -> Result<Output, NetworkError> {
    let task = sessionManager.request(
      baseUrl + url,
      method: .delete,
      interceptor: self)
      .validate()
      .serializingDecodable(Output.self)
    return await task.result
  }

  /// Submits HTTP PUT request
  func put<Output: Decodable & Sendable>(
    _ url: String,
    input: some Encodable & Sendable,
    output _: Output.Type)
    async -> Result<Output, NetworkError>
  {
    let task = sessionManager.request(
      baseUrl + url,
      method: .put,
      parameters: input,
      encoder: .json,
      headers: [
        .init(name: "Content-Type", value: "application/json"),
      ],
      interceptor: self)
      .validate()
      .serializingDecodable(Output.self)

    return await task.result
  }

  /// Submits HTTP PATCH request
  func patch<Output: Decodable & Sendable>(
    _ url: String,
    input: some Encodable & Sendable,
    output _: Output.Type)
    async -> Result<Output, NetworkError>
  {
    let task = sessionManager.request(
      baseUrl + url,
      method: .patch,
      parameters: input,
      encoder: .json,
      headers: [
        .init(name: "Content-Type", value: "application/json"),
      ],
      interceptor: self)
      .validate()
      .serializingDecodable(Output.self)

    return await task.result
  }

  // MARK: Private

  private let baseUrl: String
  private let secureStorage: SecureStorage

  private var retryLimit = 1
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "io.pocketbase.swift.sdk",
    category: "PocketBase.HttpClient")
}

// MARK: RequestInterceptor

extension HttpClient: RequestInterceptor {

  func adapt(
    _ urlRequest: URLRequest,
    for _: Session,
    completion: @escaping (Result<URLRequest, Error>) -> Void)
  {
    var request = urlRequest

    // Check for user token first, then admin token
    if let token = secureStorage.userToken {
      request.headers.add(.init(name: "Authorization", value: token))
    } else if let adminToken = secureStorage.adminToken {
      request.headers.add(.init(name: "Authorization", value: adminToken))
    }

    completion(.success(request))
  }

  func retry(
    _ request: Request,
    for _: Session,
    dueTo _: Error,
    completion: @escaping (RetryResult) -> Void)
  {
    guard request.retryCount < retryLimit else {
      logger.error("Request retry limit reached. Aborting...")
      completion(.doNotRetry)
      return
    }

    if request.error == nil {
      completion(.doNotRetry)
    } else {
      logger.warning("Request failed. Retrying...")
      completion(.retry)
    }
  }
}
