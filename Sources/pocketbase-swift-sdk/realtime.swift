//
//  realtime.swift
//  pocketbase-swift-sdk
//
//  Created by Andrew Althage on 7/12/25.
//

import EventSource
import Foundation
import os


// MARK: - Realtime

public final class Realtime<T: PBCollection>: Equatable, @unchecked Sendable {


  // MARK: Lifecycle

  public init(
    baseURL: String,
    collection: String,
    record: String = "*",
    onConnect: @escaping () -> Void,
    onDisconnect: @escaping () -> Void,
    onEvent: @escaping (RealtimeEvent<T>) -> Void)
  {
    self.baseURL = baseURL
    self.onConnect = onConnect
    self.onDisconnect = onDisconnect
    self.collection = collection
    self.record = record
    self.onEvent = onEvent
  }

  deinit {
    if self.connected {
      guard let eventSource = self.eventSource else { return }
      eventSource.disconnect()
    }
  }

  // MARK: Public

  public var connected = false

  public static func == (lhs: Realtime, rhs: Realtime) -> Bool {
    lhs.clientID == rhs.clientID
  }

  public func subscribe()
    async throws
  {
    let realtimeURL = "\(baseURL)/api/realtime"

    guard let url = URL(string: realtimeURL) else {
      throw URLError(.badURL)
    }
    let eventSource = EventSource(url: url)

    eventSource.onOpen {
      self.logger.log("Realtime connected")
      self.connected = true
      self.onConnect()
    }

    eventSource.onMessage { id, event, data in
      self.handleMessage(id: id, event: event, data: data)
    }


    eventSource.addEventListener("PB_CONNECT") { _, _, data in
      self.handlePBConnect(data: data)
    }

    eventSource.addEventListener("\(collection)/\(record)") { _, event, data in
      self.handleMessage(id: nil, event: event, data: data)
      self.handleRealtimeEvent(data: data)
    }

    self.eventSource = eventSource
    self.eventSource?.connect()
  }

  public func unsubscribe() {
    connected = false
    onDisconnect()
  }

  // MARK: Private

  private struct PBCONNECT: Codable {
    let clientId: String
  }

  private let onEvent: (RealtimeEvent<T>) -> Void

  private let baseURL: String


  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "io.pocketbase.swift.sdk",
    category: "PocketBase.RealTime")
  private let onConnect: () -> Void
  private let onDisconnect: () -> Void
  private let collection: String
  private let record: String
  private var eventSource: EventSource? = nil

  private var clientID: String? = nil {
    didSet {
      Task {
        await self.subscribeToRecord()
      }
    }
  }

  private func handlePBConnection() { }


  private func handleMessage(id: String?, event: String?, data: String?) {
    logger.info("id: \(id ?? "No ID"), event: \(event ?? "No event"), data: \(data ?? "No data")")
  }

  private func handlePBConnect(data: String?) {
    do {
      guard let data else {
        logger.warning("No data received for PB_CONNECT")
        return
      }
      let decoder = JSONDecoder()
      let jsonData = data.data(using: .utf8)!
      let pbConnect = try decoder.decode(PBCONNECT.self, from: jsonData)
      clientID = pbConnect.clientId
    } catch {
      logger.error("Error decoding PB_CONNECT: \(error)")
    }
  }

  private func handleRealtimeEvent(data: String?) {
    do {
      guard let data else {
        logger.warning("No data received for realtime event")
        return
      }

      let decoder = JSONDecoder()
      let jsonData = data.data(using: .utf8)!

      // Decode the realtime event
      let realtimeEvent = try decoder.decode(RealtimeEvent<T>.self, from: jsonData)

      // Call the onEvent callback with the decoded event
      onEvent(realtimeEvent)

    } catch {
      logger.error("Error decoding realtime event: \(error)")
    }
  }

  private func subscribeToRecord() async {
    guard let clientID else {
      logger.error("No client ID found")
      return
    }

    let realtimeURL = "\(baseURL)/api/realtime"
    let urlComps = URLComponents(string: realtimeURL)!
    let url = urlComps.url!



    let parameters: [String: Any] = [
      "clientId": clientID,
      "subscriptions": ["\(collection)/\(record)"],
    ]

    do {
      let _ = try await sendPostRequest(url: url, parameters: parameters)
      logger.info("Subscribed")
    } catch {
      logger.error("Error: \(error)")
    }
  }

  private func sendPostRequest(url: URL, parameters: [String: Any]) async throws -> (Data, URLResponse) {
    // Create the URLRequest object
    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    // Set the request headers
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    // Convert parameters to JSON data
    let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
    request.httpBody = jsonData

    // Use URLSession with async/await to send the request
    let (data, response) = try await URLSession.shared.data(for: request)

    return (data, response)
  }
}

// MARK: - RealtimeEventAction

public enum RealtimeEventAction: String, Decodable, Sendable, Encodable {
  case create, update, delete
}

// MARK: - RealtimeEvent

public struct RealtimeEvent<T: PBCollection>: PBCollection {
  public let action: RealtimeEventAction
  public let record: T
}
