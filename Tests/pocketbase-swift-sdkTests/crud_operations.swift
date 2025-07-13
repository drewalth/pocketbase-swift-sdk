//
//  crud_operations.swift
//  pocketbase-swift-sdk
//
//  Created by Andrew Althage on 7/12/25.
//

import Testing
@testable import PocketBase

// MARK: - TestRecord

struct TestRecord: Decodable, Encodable, Sendable {
  let id: String?
  let name: String
  let description: String?
  let created: String?
  let updated: String?

  init(id: String? = nil, name: String, description: String? = nil) {
    self.id = id
    self.name = name
    self.description = description
    created = nil
    updated = nil
  }
}

// MARK: - CRUD Tests

@Test
func crud_basic_operations() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

  // Create a new record
  let newRecord = TestRecord(name: "Test Record", description: "This is a test record")
  let createdRecord = try await pb.create(collection: "test_collection", record: newRecord)

  #expect(createdRecord.id != nil)
  #expect(createdRecord.name == "Test Record")

  // Read the created record
  let retrievedRecord = try await pb.getOne(
    id: createdRecord.id!,
    collection: "test_collection",
    model: TestRecord.self)

  #expect(retrievedRecord.id == createdRecord.id)
  #expect(retrievedRecord.name == createdRecord.name)

  // Update the record
  let updatedRecord = TestRecord(
    id: createdRecord.id,
    name: "Updated Test Record",
    description: "This is an updated test record")

  let patchedRecord = try await pb.update(
    collection: "test_collection",
    id: createdRecord.id!,
    record: updatedRecord)

  #expect(patchedRecord.name == "Updated Test Record")

  // Delete the record
  try await pb.delete(collection: "test_collection", id: createdRecord.id!)
}

@Test
func crud_fluent_api() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
  let testCollection: Collection<TestRecord> = pb.collection("test_collection")

  // Create a new record using fluent API
  let newRecord = TestRecord(name: "Fluent Test Record", description: "Created via fluent API")
  let createdRecord = try await testCollection.create(record: newRecord)

  #expect(createdRecord.id != nil)
  #expect(createdRecord.name == "Fluent Test Record")

  // Read the created record
  let retrievedRecord = try await testCollection.getOne(id: createdRecord.id!)
  #expect(retrievedRecord.id == createdRecord.id)

  // Update the record
  let updatedRecord = TestRecord(
    id: createdRecord.id,
    name: "Updated Fluent Record",
    description: "Updated via fluent API")

  let patchedRecord = try await testCollection.update(id: createdRecord.id!, record: updatedRecord)
  #expect(patchedRecord.name == "Updated Fluent Record")

  // Delete the record
  try await testCollection.delete(id: createdRecord.id!)
}

@Test
func crud_list_operations() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
  let testCollection: Collection<TestRecord> = pb.collection("test_collection")

  // Create multiple records
  let record1 = TestRecord(name: "Record 1", description: "First test record")
  let record2 = TestRecord(name: "Record 2", description: "Second test record")

  let created1 = try await testCollection.create(record: record1)
  let created2 = try await testCollection.create(record: record2)

  // Get list of records
  let records = try await testCollection.getList(perPage: 10)
  #expect(records.items.count >= 2)

  // Clean up
  try await testCollection.delete(id: created1.id!)
  try await testCollection.delete(id: created2.id!)
}

@Test
func crud_error_handling() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

  // Try to get a non-existent record
  do {
    let _ = try await pb.getOne(
      id: "non-existent-id",
      collection: "test_collection",
      model: TestRecord.self)
    #expect(false, "Should have thrown an error")
  } catch {
    // Expected error
    #expect(true)
  }

  // Try to update a non-existent record
  do {
    let record = TestRecord(name: "Non-existent", description: "This should fail")
    let _ = try await pb.update(
      collection: "test_collection",
      id: "non-existent-id",
      record: record)
    #expect(false, "Should have thrown an error")
  } catch {
    // Expected error
    #expect(true)
  }
}
