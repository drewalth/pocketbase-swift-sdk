//
//  realtime.swift
//  PocketBase
//
//  Created by Andrew Althage on 7/14/25.
//

import Testing
@testable import PocketBase

@Suite("Realtime")
struct RealtimeTests {
  @Test
  func new_api_realtime_fluent() async throws {
    let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

    // Using the fluent API for realtime
    let postCollection: Collection<Post> = pb.collection("posts")

    // Create a new record using fluent API
    let randomTitle = createRandomPostTitle()
    let newRecord = CreatePost(title: randomTitle)
    let createdRecord = try await postCollection.create(record: newRecord, output: Post.self)

    let realtime: Realtime<Post> = postCollection.realtime(
      record: createdRecord.id,
      onEvent: { (event: RealtimeEvent<Post>) in
        // TODO: this isnt getting called...
        #expect(event.record.title == "Realtime Updated Fluent Record foo")
      })

    // Subscribe to realtime events
    try await realtime.subscribe()

    let randomRealTimeTitle = createRandomPostTitle()
    // Update the record
    let updatedRecord = Post(
      id: createdRecord.id,
      title: "Realtime Updated Fluent Record \(randomRealTimeTitle)",
      created: createdRecord.created,
      updated: createdRecord.updated)

    let patchedRecord = try await postCollection.update(id: createdRecord.id, record: updatedRecord)
    #expect(patchedRecord.title == "Realtime Updated Fluent Record \(randomRealTimeTitle)")

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
}
