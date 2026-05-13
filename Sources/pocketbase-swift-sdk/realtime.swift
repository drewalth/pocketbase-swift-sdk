//
//  realtime.swift
//  pocketbase-swift-sdk
//
//  Created by Andrew Althage on 7/12/25.
//

import EventSource
import Foundation
import os

extension PocketBase {
    // MARK: - Realtime

    public func realtime<T: PBCollection>(
        collection: String,
        record: String = "*",
        onConnect: @escaping @MainActor () -> Void,
        onDisconnect: @escaping @MainActor () -> Void,
        onEvent: @escaping @MainActor (RealtimeEvent<T>) -> Void)
    -> Realtime<T> {
        Realtime(
            baseURL: baseURL,
            collection: collection,
            record: record,
            onConnect: onConnect,
            onDisconnect: onDisconnect,
            onEvent: onEvent)
    }

    public func realtime<T: PBCollection>(
        collection: String,
        record: String = "*",
        onEvent: @escaping @MainActor (RealtimeEvent<T>) -> Void)
    -> Realtime<T> {
        Realtime(
            baseURL: baseURL,
            collection: collection,
            record: record,
            onConnect: { },
            onDisconnect: { },
            onEvent: onEvent)
    }
}

// MARK: - Realtime

public final class Realtime<T: PBCollection>: Equatable, @unchecked Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: String,
        collection: String,
        record: String = "*",
        onConnect: @escaping @MainActor () -> Void,
        onDisconnect: @escaping @MainActor () -> Void,
        onEvent: @escaping @MainActor (RealtimeEvent<T>) -> Void) {
        self.baseURL = baseURL
        self.onConnect = onConnect
        self.onDisconnect = onDisconnect
        self.collection = collection
        self.record = record
        self.onEvent = onEvent
    }

    deinit {
        subscriptionTask?.cancel()
    }

    // MARK: Public

    @MainActor public var connected = false

    public static func == (lhs: Realtime, rhs: Realtime) -> Bool {
        lhs.clientID == rhs.clientID
    }

    public func subscribe()
    async throws {
        let realtimeURL = "\(baseURL)/api/realtime"

        guard let url = URL(string: realtimeURL) else {
            throw URLError(.badURL)
        }

        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        dataTask = eventSource.dataTask(for: urlRequest)

        guard let dataTask else {
            logger.warning("No data task to subscribe to realtime events.")
            return
        }

        subscriptionTask = Task { @concurrent [weak self] in
            guard let self else { return }
            for await event in dataTask.events() {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    switch event {
                    case .open:
                        logger.info("Realtime connection initiated.")
                    case .error(let error):
                        logger.error("\(error.localizedDescription)")
                        connected = false
                        onDisconnect()
                    case .event(let event):
                        if event.event == "PB_CONNECT" {
                            logger.info("Realtime connection handshake received.")
                            if handlePBConnect(data: event.data) {
                                connected = true
                                onConnect()
                            }
                        } else {
                            handleRealtimeEvent(data: event.data)
                        }
                    case .closed:
                        logger.info("Realtime connection closed.")
                        connected = false
                        onDisconnect()
                    }
                }
            }
        }
    }

    public func unsubscribe() {
        subscriptionTask?.cancel()
        Task { @MainActor [weak self] in
            guard let self else { return }
            connected = false
            onDisconnect()
        }
    }

    // MARK: Private

    private struct PBCONNECT: Codable {
        let clientId: String
    }

    private let onEvent: @MainActor (RealtimeEvent<T>) -> Void

    private let baseURL: String

    private var dataTask: EventSource.DataTask?
    private var subscriptionTask: Task<Void, Never>?

    private let logger = Logger(category: "RealTime")
    private let onConnect: @MainActor () -> Void
    private let onDisconnect: @MainActor () -> Void
    private let collection: String
    private let record: String
    private var eventSource = EventSource()

    private var clientID: String? {
        didSet {
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.subscribeToRecord()
            }
        }
    }

    private func handlePBConnect(data: String?) -> Bool {
        do {
            guard let data else {
                logger.warning("No data received for PB_CONNECT")
                return false
            }
            let decoder = JSONDecoder()
            guard let jsonData = data.data(using: .utf8) else {
                logger.error("PB_CONNECT data is not valid UTF-8")
                return false
            }
            let pbConnect = try decoder.decode(PBCONNECT.self, from: jsonData)
            clientID = pbConnect.clientId
            return true
        } catch {
            logger.error("Error decoding PB_CONNECT: \(error)")
            return false
        }
    }

    @MainActor private func handleRealtimeEvent(data: String?) {
        do {
            guard let data else {
                logger.warning("No data received for realtime event")
                return
            }

            let decoder = JSONDecoder()
            guard let jsonData = data.data(using: .utf8) else {
                logger.error("Realtime event data is not valid UTF-8")
                return
            }

            // Decode the realtime event
            let realtimeEvent = try decoder.decode(RealtimeEvent<T>.self, from: jsonData)

            // Call the onEvent callback with the decoded event
            onEvent(realtimeEvent)
        } catch {
            logger.error("Error decoding realtime event: \(error)")
        }
    }

    @MainActor private func subscribeToRecord() async {
        guard let clientID else {
            logger.error("No client ID found")
            return
        }

        let realtimeURL = "\(baseURL)/api/realtime"
        guard let urlComps = URLComponents(string: realtimeURL), let url = urlComps.url else {
            logger.error("Invalid realtime URL: \(realtimeURL)")
            return
        }

        let parameters: [String: Any] = [
            "clientId": clientID,
            "subscriptions": ["\(collection)/\(record)"]
        ]

        do {
            _ = try await sendPostRequest(url: url, parameters: parameters)
            logger.info("Subscribed")
        } catch {
            logger.error("Error subscribing to record: \(error.localizedDescription)")
            connected = false
            onDisconnect()
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
