//
//  type_inference_example.swift
//  pocketbase-swift-sdk
//
//  Created by Andrew Althage on 7/12/25.
//

import Testing
@testable import PocketBase

// MARK: - Post

@Suite("Type Inference")
struct TypeInference {

  @Test
  func type_inference_examples() async throws {
    let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

    // Solution 1: Explicitly specify the type
    let posts: Collection<Post> = pb.collection("posts")

    // Solution 2: Use type annotation with var
    var postCollection = pb.collection("posts") as Collection<Post>

    // Solution 3: Use the collection directly in a context where type can be inferred
    let records = try await posts.getList()
    #expect(records.items.count >= 0)

    // Solution 4: Create a helper function
    func getPostCollection() -> Collection<Post> {
      pb.collection("posts")
    }

    let postCollection2 = getPostCollection()

    let testID = records.items.first!.id

    // Solution 5: Use the collection method directly in operations
    let record = try await posts.getOne(id: testID)
    #expect(record.id == testID)
  }

  @Test
  func proper_error_handling() async throws {
    let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
    let posts: Collection<Post> = pb.collection("posts")
    // Correct way to handle errors with type inference
    do {
      let records = try await posts.getList()
      print("Found \(records.items.count) records")
    } catch {
      print("Error: \(error)")
    }

    // Or handle errors at the operation level
    do {
      let records = try await posts.getList()
      print("Found \(records.items.count) records")
    } catch {
      print("Error fetching records: \(error)")
    }
  }

}