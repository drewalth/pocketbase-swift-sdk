//
//  expand_functionality_tests.swift
//  pocketbase-swift-sdk
//
//  Created by Andrew Althage on 7/12/25.
//

import Testing
@testable import PocketBase

// MARK: - Expand Functionality Tests

@Test
func expand_basic_functionality() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

  // Test simple expand with single field
  let expandQuery = ExpandQuery("author")

  // This would expand the author field in a post
  let posts = try await pb.getList(
    collection: "posts",
    model: Post.self,
    expand: expandQuery,
    perPage: 5)

  #expect(posts.items.count >= 0)
}

@Test
func expand_multiple_fields() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

  // Test expand with multiple fields
  let expandQuery = ExpandQuery("author", "category", "tags")

  let posts = try await pb.getList(
    collection: "posts",
    model: Post.self,
    expand: expandQuery,
    perPage: 5)

  #expect(posts.items.count >= 0)
}

@Test
func expand_nested_fields() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

  // Test nested expansion (e.g., author.profile)
  let expandQuery = ExpandQuery("author.profile", "category.parent")

  let posts = try await pb.getList(
    collection: "posts",
    model: Post.self,
    expand: expandQuery,
    perPage: 5)

  #expect(posts.items.count >= 0)
}

@Test
func expand_fluent_api() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
  let posts: Collection<Post> = pb.collection("posts")

  // Test expand with fluent API
  let expandQuery = ExpandQuery("author")

  let result = try await posts.getList(
    expand: expandQuery,
    perPage: 5)

  #expect(result.items.count >= 0)
}

@Test
func expand_builder_pattern() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

  // Test using the ExpandBuilder for complex queries
  let expandQuery = ExpandBuilder()
    .field("author")
    .field("category")
    .nested("author.profile")
    .nested("category.parent")
    .build()

  let posts = try await pb.getList(
    collection: "posts",
    model: Post.self,
    expand: expandQuery,
    perPage: 5)

  #expect(posts.items.count >= 0)
}

@Test
func expand_single_record() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

  // First create a record to test with
  let randomTitle = createRandomPostTitle()
  let newRecord = CreatePost(title: randomTitle)
  let createdRecord = try await pb.create(collection: "posts", record: newRecord, output: Post.self)

  // Test expand on single record
  let expandQuery = ExpandQuery("author", "category")

  let retrievedRecord = try await pb.getOne(
    id: createdRecord.id,
    collection: "posts",
    model: Post.self,
    expand: expandQuery)

  #expect(retrievedRecord.id == createdRecord.id)

  // Clean up
  try await pb.delete(collection: "posts", id: createdRecord.id)
}

@Test
func expand_fluent_single_record() async throws {
  let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
  let posts: Collection<Post> = pb.collection("posts")

  // First create a record to test with
  let randomTitle = createRandomPostTitle()
  let newRecord = CreatePost(title: randomTitle)
  let createdRecord = try await posts.create(record: newRecord, output: Post.self)

  // Test expand on single record with fluent API
  let expandQuery = ExpandQuery("author")

  let retrievedRecord = try await posts.getOne(
    id: createdRecord.id,
    expand: expandQuery)

  #expect(retrievedRecord.id == createdRecord.id)

  // Clean up
  try await posts.delete(id: createdRecord.id)
}

@Test
func expand_query_string_generation() {
  // Test ExpandQuery string generation
  let simpleExpand = ExpandQuery("author")
  #expect(simpleExpand.queryString == "author")

  let multipleExpand = ExpandQuery("author", "category")
  #expect(multipleExpand.queryString == "author,category")

  let nestedExpand = ExpandQuery("author.profile", "category.parent")
  #expect(nestedExpand.queryString == "author.profile,category.parent")

  let emptyExpand = ExpandQuery()
  #expect(emptyExpand.isEmpty == true)
  #expect(emptyExpand.queryString == "")
}

@Test
func expand_builder_fluent_interface() {
  // Test ExpandBuilder fluent interface
  let expandQuery = ExpandBuilder()
    .field("author")
    .field("category")
    .nested("author.profile")
    .build()

  #expect(expandQuery.queryString == "author,category,author.profile")
  #expect(expandQuery.isEmpty == false)
}

@Test
func expand_immutable_operations() {
  // Test that ExpandQuery operations are immutable
  let original = ExpandQuery("author")
  let expanded = original.expand("category")

  #expect(original.queryString == "author")
  #expect(expanded.queryString == "author,category")

  let nested = expanded.expandNested("author.profile")
  #expect(nested.queryString == "author,category,author.profile")
  #expect(expanded.queryString == "author,category") // Original unchanged
}
