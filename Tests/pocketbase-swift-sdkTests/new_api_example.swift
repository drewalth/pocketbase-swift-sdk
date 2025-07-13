//
//  new_api_example.swift
//  pocketbase-swift-sdk
//
//  Created by Andrew Althage on 7/12/25.
//

import Testing
@testable import PocketBase

// MARK: - SpotFeed

// Using the SpotFeed struct from collections.swift

@Test
func new_api_collection_fluent() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

  // Using the new fluent API
  let spotFeedCollection: Collection<SpotFeed> = pb.collection("spot_feed")

  // Get a single record
  let spotFeed = try await spotFeedCollection.getOne(id: "e849z3g13jls740")
  #expect(spotFeed.id == "e849z3g13jls740")

  // Get a list of records
  let spotFeeds = try await spotFeedCollection.getList()
  #expect(spotFeeds.items.count > 0)
}

@Test
func new_api_realtime_basic() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

  // Create a realtime subscription using the basic API
  let realtime: Realtime<SpotFeed> = pb.realtime(
    collection: "spot_feed",
    onEvent: { (event: RealtimeEvent<SpotFeed>) in
      print("Received event: \(event.action) for record: \(event.record.id)")
    })

  // Subscribe to realtime events
  try await realtime.subscribe()

  // Later, unsubscribe
  realtime.unsubscribe()
}

@Test
func new_api_realtime_fluent() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

  // Using the fluent API for realtime
  let spotFeedCollection: Collection<SpotFeed> = pb.collection("spot_feed")

  let realtime: Realtime<SpotFeed> = spotFeedCollection.realtime(
    onEvent: { (event: RealtimeEvent<SpotFeed>) in
      print("Received event: \(event.action) for record: \(event.record.id)")
    })

  // Subscribe to realtime events
  try await realtime.subscribe()

  // Later, unsubscribe
  realtime.unsubscribe()
}

@Test
func new_api_realtime_with_callbacks() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

  // Create a realtime subscription with all callbacks
  let realtime: Realtime<SpotFeed> = pb.realtime(
    collection: "spot_feed",
    onConnect: {
      print("Connected to realtime")
    },
    onDisconnect: {
      print("Disconnected from realtime")
    },
    onEvent: { (event: RealtimeEvent<SpotFeed>) in
      print("Received event: \(event.action) for record: \(event.record.id)")
    })

  // Subscribe to realtime events
  try await realtime.subscribe()

  // Later, unsubscribe
  realtime.unsubscribe()
}
