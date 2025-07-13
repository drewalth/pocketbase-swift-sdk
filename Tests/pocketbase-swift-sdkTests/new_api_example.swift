//
//  new_api_example.swift
//  pocketbase-swift-sdk
//
//  Created by Andrew Althage on 7/12/25.
//

import Testing
@testable import PocketBase

// MARK: - Post

// Using the Post struct from test-models.swift

@Test
func new_api_collection_fluent() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

  // Using the new fluent API
  let postCollection: Collection<Post> = pb.collection("posts")

  let posts = try await postCollection.getList()
  #expect(posts.items.count > 0)

  let testID = posts.items[0].id

  // Get a single record
  let post = try await postCollection.getOne(id: testID)
  #expect(post.id == testID)
}

@Test
func new_api_realtime_basic() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

  // Create a realtime subscription using the basic API
  let realtime: Realtime<Post> = pb.realtime(
    collection: "posts",
    onEvent: { (event: RealtimeEvent<Post>) in
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
  let postCollection: Collection<Post> = pb.collection("posts")

  let realtime: Realtime<Post> = postCollection.realtime(
    onEvent: { (event: RealtimeEvent<Post>) in
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
  let realtime: Realtime<Post> = pb.realtime(
    collection: "posts",
    onConnect: {
      print("Connected to realtime")
    },
    onDisconnect: {
      print("Disconnected from realtime")
    },
    onEvent: { (event: RealtimeEvent<Post>) in
      print("Received event: \(event.action) for record: \(event.record.id)")
    })

  // Subscribe to realtime events
  try await realtime.subscribe()

  // Later, unsubscribe
  realtime.unsubscribe()
}
