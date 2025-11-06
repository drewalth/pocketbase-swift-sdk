//
//  new_api_example.swift
//  pocketbase-swift-sdk
//
//  Created by Andrew Althage on 7/12/25.
//

import Testing
@testable import PocketBase

@Suite("Fluent API")
struct FluentApiTests {

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

}
