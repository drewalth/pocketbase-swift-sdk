//
//  collections.swift
//  pocketbase-swift-sdk
//
//  Created by Andrew Althage on 7/12/25.
//

import Testing
@testable import PocketBase

// MARK: - SpotFeed

struct SpotFeed: Decodable, Encodable, Sendable {
  let id: String
  let name: String
  let feed_id: String
  let feed_password: String?
  let last_synced: String?
  let team_id: String?
  let syncing: Bool
  let created: String
  let updated: String
}

@Test
func collections_getOne() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

  let spotFeed = try await pb.getOne(id: "e849z3g13jls740", collection: "spot_feed", model: SpotFeed.self)

  #expect(spotFeed.id == "e849z3g13jls740")
}

@Test
func collections_getList() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

  let spotFeed = try await pb.getList(collection: "spot_feed", model: SpotFeed.self)

  #expect(spotFeed.items.count > 0)
}
