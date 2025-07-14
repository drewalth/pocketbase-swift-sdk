//
//  expand_examples.swift
//  pocketbase-swift-sdk
//
//  Created by Andrew Althage on 7/12/25.
//

import Foundation
@testable import PocketBase

// MARK: - Expand Examples

/// This file demonstrates various ways to use the improved expand functionality
/// in the PocketBase Swift SDK.

class ExpandExamples {

  // MARK: Internal

  // MARK: - Basic Expand Examples

  func basicExpandExample() async throws {
    // Simple single field expansion
    let expandQuery = ExpandQuery("author")

    let posts = try await pb.getList(
      collection: "posts",
      model: Post.self,
      expand: expandQuery)

    // The posts will now include expanded author data
    print("Retrieved \(posts.items.count) posts with author data")
  }

  func multipleFieldsExpandExample() async throws {
    // Expand multiple fields at once
    let expandQuery = ExpandQuery("author", "category", "tags")

    let posts = try await pb.getList(
      collection: "posts",
      model: Post.self,
      expand: expandQuery)

    // Posts will include author, category, and tags data
    print("Retrieved posts with author, category, and tags")
  }

  // MARK: - Nested Expand Examples

  func nestedExpandExample() async throws {
    // Expand nested relationships (e.g., author.profile)
    let expandQuery = ExpandQuery("author.profile", "category.parent")

    let posts = try await pb.getList(
      collection: "posts",
      model: Post.self,
      expand: expandQuery)

    // Posts will include author's profile and category's parent
    print("Retrieved posts with nested author profile and category parent")
  }

  func deepNestedExpandExample() async throws {
    // Deep nested expansion (e.g., author.profile.avatar)
    let expandQuery = ExpandQuery("author.profile.avatar", "category.parent.grandparent")

    let posts = try await pb.getList(
      collection: "posts",
      model: Post.self,
      expand: expandQuery)

    // Deep nested expansion for complex relationships
    print("Retrieved posts with deep nested expansions")
  }

  // MARK: - Builder Pattern Examples

  func builderPatternExample() async throws {
    // Using the ExpandBuilder for complex queries
    let expandQuery = ExpandBuilder()
      .field("author")
      .field("category")
      .nested("author.profile")
      .nested("category.parent")
      .field("tags")
      .build()

    let posts = try await pb.getList(
      collection: "posts",
      model: Post.self,
      expand: expandQuery)

    // Complex expansion built using fluent interface
    print("Retrieved posts using builder pattern")
  }

  func conditionalExpandExample() async throws {
    // Conditional expansion based on user preferences
    let shouldExpandAuthor = true
    let shouldExpandCategory = false

    let builder = ExpandBuilder()

    if shouldExpandAuthor {
      builder.field("author")
    }

    if shouldExpandCategory {
      builder.field("category")
    }

    let expandQuery = builder.build()

    let posts = try await pb.getList(
      collection: "posts",
      model: Post.self,
      expand: expandQuery)

    print("Conditional expansion applied")
  }

  // MARK: - Fluent API Examples

  func fluentAPIExample() async throws {
    let posts: Collection<Post> = pb.collection("posts")

    // Using expand with fluent API
    let expandQuery = ExpandQuery("author", "category")

    let result = try await posts.getList(
      expand: expandQuery,
      perPage: 10)

    print("Used fluent API with expand")
  }

  func fluentAPISingleRecordExample() async throws {
    let posts: Collection<Post> = pb.collection("posts")

    // Expand on single record retrieval
    let expandQuery = ExpandQuery("author.profile", "category")

    let post = try await posts.getOne(
      id: "some-post-id",
      expand: expandQuery)

    print("Retrieved single post with expanded data")
  }

  // MARK: - Immutable Operations Examples

  func immutableOperationsExample() {
    // Demonstrate immutable nature of ExpandQuery
    let baseExpand = ExpandQuery("author")

    // Create variations without modifying the original
    let withCategory = baseExpand.expand("category")
    let withNested = withCategory.expandNested("author.profile")

    print("Base: \(baseExpand.queryString)")
    print("With category: \(withCategory.queryString)")
    print("With nested: \(withNested.queryString)")

    // Original remains unchanged
    assert(baseExpand.queryString == "author")
  }

  // MARK: - Performance Considerations

  func performanceOptimizedExample() async throws {
    // Only expand what you need to minimize data transfer
    let expandQuery = ExpandQuery("author") // Only author, not author.profile.avatar

    let posts = try await pb.getList(
      collection: "posts",
      model: Post.self,
      expand: expandQuery,
      perPage: 20 // Limit results
    )

    print("Performance optimized expansion")
  }

  // MARK: - Error Handling Examples

  func errorHandlingExample() async throws {
    do {
      let expandQuery = ExpandQuery("non_existent_field")

      let posts = try await pb.getList(
        collection: "posts",
        model: Post.self,
        expand: expandQuery)

      print("Successfully retrieved posts")
    } catch {
      print("Error with expand: \(error)")
      // Handle the error appropriately
    }
  }

  // MARK: - Real-world Usage Patterns

  func blogPostWithAuthorExample() async throws {
    // Typical blog post with author expansion
    let expandQuery = ExpandQuery("author", "category", "tags")

    let posts = try await pb.getList(
      collection: "posts",
      model: Post.self,
      expand: expandQuery,
      perPage: 10)

    // Process posts with full author, category, and tags data
    for post in posts.items {
      // Access expanded data here
      print("Post: \(post.title)")
    }
  }

  func userProfileWithPostsExample() async throws {
    // Get user profile with their posts
    let expandQuery = ExpandQuery("posts", "profile")

    let users = try await pb.getList(
      collection: "users",
      model: User.self,
      expand: expandQuery,
      perPage: 5)

    // Users will include their posts and profile data
    print("Retrieved users with posts and profiles")
  }

  // MARK: Private

  private let pb = PocketBase(baseURL: "http://127.0.0.1:8090")

}

// MARK: - Best Practices

// Best Practices for Using Expand Functionality:
//
// 1. **Only expand what you need**: Don't expand fields you won't use
// 2. **Use nested expansions sparingly**: Deep nesting can impact performance
// 3. **Consider pagination**: Large datasets with expansions can be slow
// 4. **Cache expanded data**: Consider caching frequently accessed expanded data
// 5. **Handle errors gracefully**: Invalid expand fields will cause errors
// 6. **Use the builder pattern for complex queries**: More readable and maintainable
// 7. **Test with your actual data**: Ensure your models support the expanded fields
// 8. **Monitor performance**: Track response times with different expansion levels