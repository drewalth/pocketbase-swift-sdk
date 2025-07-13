//
//  crud_operations.swift
//  pocketbase-swift-sdk
//
//  Created by Andrew Althage on 7/12/25.
//

import Testing
@testable import PocketBase

// MARK: - CRUD Tests

@Test
func crud_basic_operations() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

  // Create a new record
  let newRecord = CreatePost(title: "Test Record")
  let createdRecord = try await pb.create(collection: "posts", record: newRecord, output: Post.self)

  #expect(createdRecord.id != "")
  #expect(createdRecord.title == "Test Record")

  // Read the created record
  let retrievedRecord = try await pb.getOne(
    id: createdRecord.id,
    collection: "posts",
    model: Post.self)

  #expect(retrievedRecord.id == createdRecord.id)
  #expect(retrievedRecord.title == createdRecord.title)

  // Update the record
  let updatedRecord = Post(
    id: createdRecord.id,
    title: "Updated Test Record",
    created: createdRecord.created,
    updated: createdRecord.updated)

  let patchedRecord = try await pb.update(
    collection: "posts",
    id: createdRecord.id,
    record: updatedRecord)

  #expect(patchedRecord.title == "Updated Test Record")

  // Delete the record
//  try await pb.delete(collection: "posts", id: createdRecord.id)
}

@Test
func crud_fluent_api() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
  let posts: Collection<Post> = pb.collection("posts")

  // Create a new record using fluent API
  let newRecord = CreatePost(title: "Fluent Test Record")
  let createdRecord = try await posts.create(record: newRecord, output: Post.self)

  #expect(createdRecord.id != "")
  #expect(createdRecord.title == "Fluent Test Record")

  // Read the created record
  let retrievedRecord = try await posts.getOne(id: createdRecord.id)
  #expect(retrievedRecord.id == createdRecord.id)

  // Update the record
  let updatedRecord = Post(
    id: createdRecord.id,
    title: "Updated Fluent Record",
    created: createdRecord.created,
    updated: createdRecord.updated)

  let patchedRecord = try await posts.update(id: createdRecord.id, record: updatedRecord)
  #expect(patchedRecord.title == "Updated Fluent Record")

  // Delete the record
  try await posts.delete(id: createdRecord.id)
}

@Test
func crud_list_operations() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
  let posts: Collection<Post> = pb.collection("posts")

  // Create multiple records
  let record1 = CreatePost(title: "Record 1")
  let record2 = CreatePost(title: "Record 2")

  let created1 = try await posts.create(record: record1, output: Post.self)
  let created2 = try await posts.create(record: record2, output: Post.self)

  // Get list of records
  let records = try await posts.getList(perPage: 10)
  #expect(records.items.count >= 2)

  // Clean up
  try await posts.delete(id: created1.id)
  try await posts.delete(id: created2.id)
}

@Test
func crud_error_handling() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

  // Try to get a non-existent record
  do {
    let _ = try await pb.getOne(
      id: "non-existent-id",
      collection: "posts",
      model: Post.self)
    #expect(false, "Should have thrown an error")
  } catch {
    // Expected error
    #expect(true)
  }

  // Try to update a non-existent record
  do {
    let record = Post(id: "non-existent-id", title: "Non-existent", created: "", updated: "")
    let _ = try await pb.update(
      collection: "posts",
      id: "non-existent-id",
      record: record)
    #expect(false, "Should have thrown an error")
  } catch {
    // Expected error
    #expect(true)
  }
}
