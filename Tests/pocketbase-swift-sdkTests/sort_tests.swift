//
//  sort.swift
//  PocketBase
//

import Foundation
import Testing
@testable import PocketBase

// MARK: - PBSortDescriptor Tests

@Suite("PBSortDescriptor")
struct PBSortDescriptorTests {

    @Test
    func keyPathExtraction() {
        let desc = PBSortDescriptor(\Post.title)
        #expect(desc.fieldName == "title")
    }

    @Test
    func keyPathNestedExtraction() {
        // Nested key paths should produce dot-notation field names
        let desc = PBSortDescriptor(\Post.title, order: .reverse)
        #expect(desc.fieldName == "title")
    }

    @Test
    func stringInit() {
        let desc = PBSortDescriptor<Post>("custom_field")
        #expect(desc.fieldName == "custom_field")
        #expect(desc.order == .forward)
    }

    @Test
    func stringInitReverse() {
        let desc = PBSortDescriptor<Post>("created", order: .reverse)
        #expect(desc.fieldName == "created")
        #expect(desc.order == .reverse)
    }

    @Test
    func queryStringForward() {
        let desc = PBSortDescriptor(\Post.title, order: .forward)
        #expect(desc.queryString == "title")
    }

    @Test
    func queryStringReverse() {
        let desc = PBSortDescriptor(\Post.title, order: .reverse)
        #expect(desc.queryString == "-title")
    }

    @Test
    func equatable() {
        let a = PBSortDescriptor(\Post.title, order: .forward)
        let b = PBSortDescriptor(\Post.title, order: .forward)
        let c = PBSortDescriptor(\Post.title, order: .reverse)
        #expect(a == b)
        #expect(a != c)
    }
}

// MARK: - PBSortQuery Tests

@Suite("PBSortQuery")
struct PBSortQueryTests {

    @Test
    func empty() {
        let query = PBSortQuery<Post>()
        #expect(query.isEmpty)
        #expect(query.queryString == "")
    }

    @Test
    func singleDescriptor() {
        let query = PBSortQuery<Post>(PBSortDescriptor(\Post.title))
        #expect(!query.isEmpty)
        #expect(query.queryString == "title")
    }

    @Test
    func multipleDescriptors() {
        let query = PBSortQuery<Post>(
            PBSortDescriptor(\Post.title, order: .reverse),
            PBSortDescriptor(\Post.created)
        )
        #expect(query.queryString == "-title,created")
    }

    @Test
    func variadicInit() {
        let query = PBSortQuery<Post>(
            PBSortDescriptor("field1"),
            PBSortDescriptor("field2", order: .reverse),
            PBSortDescriptor("field3")
        )
        #expect(query.queryString == "field1,-field2,field3")
    }
}

// MARK: - Sort Integration Tests

@Suite("Sort Integration")
class SortIntegrationTests {

    // MARK: Lifecycle

    deinit {
        let ids = createdPostIds
        Task {
            let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
            let posts: Collection<Post> = pb.collection("posts")
            for id in ids {
                try? await posts.delete(id: id)
            }
        }
    }

    // MARK: Internal

    var createdPostIds: Set<String> = []

    @Test
    func getListWithSort() async throws {
        let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
        let prefix = "SORT-ASC-\(UUID().uuidString.prefix(4))"

        // Create posts with known sortable titles
        let post1 = try await pb.create(collection: "posts", record: CreatePost(title: "\(prefix)-B"), output: Post.self)
        let post2 = try await pb.create(collection: "posts", record: CreatePost(title: "\(prefix)-A"), output: Post.self)
        let post3 = try await pb.create(collection: "posts", record: CreatePost(title: "\(prefix)-C"), output: Post.self)
        createdPostIds = [post1.id, post2.id, post3.id]

        // Sort by title ascending
        let posts: Collection<Post> = pb.collection("posts")
        let sortQuery = PBSortQuery(PBSortDescriptor(\Post.title, order: .forward))
        let result = try await posts.getList(sort: sortQuery, perPage: 100)
        let ourTitles = result.items.compactMap {
            $0.title.hasPrefix(prefix) ? $0.title : nil
        }
        #expect(ourTitles == ["\(prefix)-A", "\(prefix)-B", "\(prefix)-C"])
    }

    @Test
    func getListWithSortDescending() async throws {
        let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
        let prefix = "SORT-DESC-\(UUID().uuidString.prefix(4))"

        let post1 = try await pb.create(collection: "posts", record: CreatePost(title: "\(prefix)-B"), output: Post.self)
        let post2 = try await pb.create(collection: "posts", record: CreatePost(title: "\(prefix)-A"), output: Post.self)
        let post3 = try await pb.create(collection: "posts", record: CreatePost(title: "\(prefix)-C"), output: Post.self)
        createdPostIds = [post1.id, post2.id, post3.id]

        let posts: Collection<Post> = pb.collection("posts")
        let sortQuery = PBSortQuery(PBSortDescriptor(\Post.title, order: .reverse))
        let result = try await posts.getList(sort: sortQuery, perPage: 100)
        let ourTitles = result.items.compactMap {
            $0.title.hasPrefix(prefix) ? $0.title : nil
        }
        #expect(ourTitles == ["\(prefix)-C", "\(prefix)-B", "\(prefix)-A"])
    }

    @Test
    func untypedGetListWithSortString() async throws {
        let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
        let prefix = "UTSORT-\(UUID().uuidString.prefix(4))"

        let post1 = try await pb.create(collection: "posts", record: CreatePost(title: "\(prefix)-Z"), output: Post.self)
        let post2 = try await pb.create(collection: "posts", record: CreatePost(title: "\(prefix)-A"), output: Post.self)
        createdPostIds = [post1.id, post2.id]

        // Use raw sort string on untyped API
        let result = try await pb.getList(collection: "posts", model: Post.self, sort: "title", perPage: 100)
        let ourTitles = result.items.compactMap {
            $0.title.hasPrefix(prefix) ? $0.title : nil
        }
        #expect(ourTitles == ["\(prefix)-A", "\(prefix)-Z"])
    }

    @Test
    func getListWithoutSort() async throws {
        let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

        let posts: Collection<Post> = pb.collection("posts")
        let result = try await posts.getList(perPage: 10)
        // Should return results without error (default PocketBase order)
        #expect(result.perPage == 10)
    }

    // MARK: Private

    private func createRandomPostTitle() -> String {
        "Test Post \(UUID().uuidString.prefix(8))"
    }
}
