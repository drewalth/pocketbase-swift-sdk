# PocketBase Swift SDK

A lightweight, idiomatic Swift SDK for [PocketBase](https://pocketbase.io/) with SwiftUI property
wrappers and UIKit compatibility.

[![CI](https://github.com/drewalth/pocketbase-swift-sdk/actions/workflows/ci.yaml/badge.svg)](https://github.com/drewalth/pocketbase-swift-sdk/actions/workflows/ci.yaml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdrewalth%2Fpocketbase-swift-sdk%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/drewalth/pocketbase-swift-sdk)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdrewalth%2Fpocketbase-swift-sdk%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/drewalth/pocketbase-swift-sdk)

- [Overview](#overview)
- [Quick start](#quick-start)
- [Installation](#installation)
- [Usage](#usage)
- [Example app](#example-app)
- [License](#license)

## Overview

The SDK provides a type-safe, concurrency-first API for PocketBase's REST and SSE endpoints. Define
your models as `Codable` structs, and property wrappers like `@PBQuery` and `@PBAuthState` keep your
views in sync — similar to SwiftData's `@Query` but driven by your PocketBase server:

```swift
@PBQuery(collection: "posts", sort: \Post.created, order: .reverse)
private var posts: [Post]
```

The core library has **zero UI framework dependencies** — it works from SwiftUI, UIKit, or a
headless Swift target.

## Quick start

Define a model and provide a `PocketBase` instance to the SwiftUI environment:

```swift
import PocketBase
import SwiftUI

struct Post: PBCollection {
  let id: String
  let title: String
  let created: String
  let updated: String
  let collectionId: String
  let collectionName: String
}

@main
struct MyApp: App {
  @State private var pocketBase = PocketBase(baseURL: "http://127.0.0.1:8090")

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.pocketBase, pocketBase)
    }
  }
}
```

Then fetch and display data with `@PBQuery`:

```swift
struct ContentView: View {
  @PBQuery(collection: "posts", sort: \Post.created, order: .reverse)
  private var posts: [Post]

  var body: some View {
    List(posts) { post in
      Text(post.title)
    }
    .refreshable { $posts.refresh() }
  }
}
```

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/drewalth/pocketbase-swift-sdk.git", from: "1.0.0")
],
targets: [
  .target(name: "YourApp", dependencies: [.product(name: "PocketBase", package: "pocketbase-swift-sdk")])
]
```

Or in Xcode: **File → Add Package Dependencies...** and search for
`https://github.com/drewalth/pocketbase-swift-sdk`.

## Usage

### Data models

```swift
// A model for any PocketBase collection
struct Bookmark: PBCollection {
  let id: String
  let title: String
  let url: String
  let created: String
  let updated: String
  let collectionId: String
  let collectionName: String
}

// For user/auth models, use PBIdentifiableCollection
struct User: PBIdentifiableCollection {
  let id: String
  let email: String
  let name: String?
  let verified: Bool
  let created: String
  let updated: String
  let collectionId: String
  let collectionName: String
}
```

### CRUD operations

```swift
let posts: Collection<Post> = pb.collection("posts")

// List
let result = try await posts.getList()
for post in result.items { /* ... */ }

// Single
let post = try await posts.getOne(id: "e849z3g13jls740")

// Create
let newPost = try await posts.create(record: Post(/* ... */))

// Update
let updated = try await posts.update(id: newPost.id, record: Post(/* ... */))

// Delete
try await posts.delete(id: newPost.id)
```

All CRUD methods are also available directly on `PocketBase` without creating a `Collection`:

```swift
let result = try await pb.getList(collection: "posts", model: Post.self)
```

### Authentication

```swift
// Sign in
let auth = try await pb.authWithPassword(
  email: "user@example.com", password: "password", userType: User.self)

// Sign up
let newUser = try await pb.signUp(
  dto: CreateUser(email: "...", name: "...", password: "...", passwordConfirm: "..."),
  userType: User.self)

// Sign out
pb.signOut()

// Password reset
try await pb.requestPasswordReset(email: "user@example.com")
try await pb.confirmPasswordReset(token: "...", password: "...", passwordConfirm: "...")
```

Tokens are stored in the Keychain and automatically attached to every request. In the simulator, the
SDK transparently falls back to `UserDefaults`.

#### SwiftUI auth state

```swift
struct AuthView: View {
  @PBAuthState private var auth

  var body: some View {
    if auth.isAuthenticated {
      Text("Signed in as \(auth.userId ?? "")")
    } else {
      LoginFormView()
    }
  }
}
```

### Sorting

```swift
// Keypath-based
let posts = try await pb.collection("posts").getList(
  sort: PBSortQuery(PBSortDescriptor(\Post.created, order: .reverse)))

// Multiple sort fields
let sort = PBSortQuery(
  PBSortDescriptor(\Post.category, order: .forward),
  PBSortDescriptor(\Post.created, order: .reverse))
```

`@PBQuery` supports keypath sort directly:

```swift
@PBQuery(collection: "posts", sort: \Post.created, order: .reverse)
private var posts: [Post]
```

### Filtering

```swift
// Type-safe filter builder
let filter = FiltersQuery()
  .greaterThan("views", 100)
  .equals("status", "published")

let result = try await pb.collection("posts").getList(filters: filter)

// Or use the builder pattern
let filter = FilterBuilder()
  .greaterThan("views", 100)
  .equals("status", "published")
  .build()
```

Combine filters with `@PBQuery`:

```swift
@PBQuery(
  collection: "posts",
  filter: FiltersQuery().equals("status", "published"),
  sort: \Post.created, order: .reverse)
private var publishedPosts: [Post]
```

### Expanding relations

```swift
// Expand a single relation
let posts = try await pb.collection("posts").getList(expand: ExpandQuery("author"))

// Expand nested relations
let posts = try await pb.collection("posts").getList(expand: ExpandQuery("author.profile"))

// Builder pattern
let expand = ExpandBuilder()
  .field("author")
  .nested("author.profile")
  .build()
```

### Realtime (SSE)

```swift
let realtime = pb.realtime(collection: "bookmarks", onEvent: { (event: RealtimeEvent<Bookmark>) in
  switch event.action {
  case .create: print("Created:", event.record.title)
  case .update: print("Updated:", event.record.title)
  case .delete: print("Deleted:", event.record.id)
  }
})

try await realtime.subscribe()

// Later
realtime.unsubscribe()
```

Enable realtime on `@PBQuery` to automatically refresh the list when server data changes:

```swift
@PBQuery(collection: "posts", sort: \Post.created, order: .reverse, realtime: true)
private var posts: [Post]
```

### UIKit

The SDK core has no SwiftUI dependency. Use it from UIKit with async/await:

```swift
import PocketBase
import UIKit

final class PostsViewController: UITableViewController {
  private let pocketBase = PocketBase(baseURL: "http://127.0.0.1:8090")
  private var posts: [Post] = []

  private func fetch() async {
    do {
      let result = try await pocketBase.collection("posts").getList(
        sort: PBSortQuery(PBSortDescriptor(\Post.created, order: .reverse)))
      posts = result.items
      tableView.reloadData()
    } catch {
      // handle error
    }
  }
}
```

## Example app

The [example app](./example) demonstrates the full API surface — including `@PBQuery`,
`@PBAuthState`, authentication flows, realtime subscriptions, and a UIKit screen — against a local
PocketBase server. Open it with `cd example && xed .`.

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
