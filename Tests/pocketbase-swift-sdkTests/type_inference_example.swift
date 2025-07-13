//
//  type_inference_example.swift
//  pocketbase-swift-sdk
//
//  Created by Andrew Althage on 7/12/25.
//

import Testing
@testable import PocketBase

// MARK: - SpotFeed


@Test
func type_inference_examples() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

  // Solution 1: Explicitly specify the type
  let spotFeeds: Collection<SpotFeed> = pb.collection("spot_feed")

  // Solution 2: Use type annotation with var
  var spotFeedCollection = pb.collection("spot_feed") as Collection<SpotFeed>

  // Solution 3: Use the collection directly in a context where type can be inferred
  let records = try await spotFeeds.getList()
  #expect(records.items.count >= 0)

  // Solution 4: Create a helper function
  func getSpotFeedCollection() -> Collection<SpotFeed> {
    pb.collection("spot_feed")
  }

  let spotFeedCollection2 = getSpotFeedCollection()

  // Solution 5: Use the collection method directly in operations
  let record = try await spotFeeds.getOne(id: "some-id")
  #expect(record.id == "some-id")
}

@Test
func proper_error_handling() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
  let spotFeeds: Collection<SpotFeed> = pb.collection("spot_feed")
  // Correct way to handle errors with type inference
  do {
    let records = try await spotFeeds.getList()
    print("Found \(records.items.count) records")
  } catch {
    print("Error: \(error)")
  }

  // Or handle errors at the operation level
  do {
    let records = try await spotFeeds.getList()
    print("Found \(records.items.count) records")
  } catch {
    print("Error fetching records: \(error)")
  }
}
