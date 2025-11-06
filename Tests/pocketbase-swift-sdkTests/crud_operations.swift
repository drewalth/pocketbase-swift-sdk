//
//  crud_operations.swift
//  pocketbase-swift-sdk
//
//  Created by Andrew Althage on 7/12/25.
//

import Testing
@testable import PocketBase

// MARK: - CRUD Tests

@Suite("CRUD Operations")
class CRUDOperations {

    // MARK: Lifecycle

    deinit {
        // Capture the IDs before creating the Task to avoid capturing self
        let postIdsToDelete = createdPostIds
        Task {
            // delete all created posts
            let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
            let posts: Collection<Post> = pb.collection("posts")
            for id in postIdsToDelete {
                try await posts.delete(id: id)
            }
        }
    }

    // MARK: Internal

    var createdPostIds: Set<String> = []

    @Test
    func crud_basic_operations() async throws {
        let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

        // Create a new record
        let randomTitle = createRandomPostTitle()
        let newRecord = CreatePost(title: randomTitle)
        let createdRecord = try await pb.create(collection: "posts", record: newRecord, output: Post.self)

        createdPostIds.insert(createdRecord.id)

        #expect(createdRecord.id != "")
        #expect(createdRecord.title == randomTitle)

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
        let randomTitle = createRandomPostTitle()
        let newRecord = CreatePost(title: randomTitle)
        let createdRecord = try await posts.create(record: newRecord, output: Post.self)

        createdPostIds.insert(createdRecord.id)

        #expect(createdRecord.id != "")
        #expect(createdRecord.title == randomTitle)

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
        //  try await posts.delete(id: createdRecord.id)
    }

    @Test
    func crud_list_operations() async throws {
        let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
        let posts: Collection<Post> = pb.collection("posts")
        let randomTitle1 = createRandomPostTitle()
        let randomTitle2 = createRandomPostTitle()
        // Create multiple records
        let record1 = CreatePost(title: randomTitle1)
        let record2 = CreatePost(title: randomTitle2)

        let created1 = try await posts.create(record: record1, output: Post.self)
        let created2 = try await posts.create(record: record2, output: Post.self)

        // Get list of records
        let records = try await posts.getList(perPage: 10)
        #expect(records.items.count >= 2)

        // Clean up
        createdPostIds.insert(created1.id)
        createdPostIds.insert(created2.id)
    }

    @Test
    func crud_error_handling() async throws {
        let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

        // Try to get a non-existent record
        do {
            _ = try await pb.getOne(
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
            _ = try await pb.update(
                collection: "posts",
                id: "non-existent-id",
                record: record)
            #expect(false, "Should have thrown an error")
        } catch {
            // Expected error
            #expect(true)
        }
    }
}
