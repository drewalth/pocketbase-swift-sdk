# Pocketbase Swift SDK

A Swift SDK for [Pocketbase](https://pocketbase.io/) v0.28.2.

[![Build](https://github.com/drewalth/pocketbase-swift-sdk/actions/workflows/main.yaml/badge.svg)](https://github.com/drewalth/pocketbase-swift-sdk/actions/workflows/main.yaml) [![Swift](https://img.shields.io/badge/Swift-6.0-orange?style=flat-square)](https://img.shields.io/badge/Swift-6.0-Orange?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-macOS_iOS-yellowgreen?style=flat-square)](https://img.shields.io/badge/Platforms-macOS_iOS-YellowGreen?style=flat-square)


## Features

- ✅ Generic user authentication (supports any model)
- ✅ User authentication (sign up, sign in, sign out)
- ✅ Token refresh
- ✅ Password reset
- ✅ CRUD operations
- ✅ Realtime subscriptions
- ✅ Type-safe data models
- ✅ Automatic token management (stores tokens securely)


> Note: This is a work in progress. The SDK is not yet have 100% feature parity with the [js-sdk](https://github.com/pocketbase/js-sdk) but it's close.
> Any contributions are welcome!

## Motivation

Pocketbase is a great framework for quick prototyping and small scale applications. In an ideal world, Pocketbase would generate Swagger/OpenAPI documentation, but currently it doesn't. And there is [no plan](https://github.com/pocketbase/pocketbase/issues/945) to add it in the future. 

This SDK aims to make it easier to use Pocketbase with Swift projects.

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/drewalth/pocketbase-swift-sdk.git", from: "1.0.0")
]
```

## Usage

### Basic Setup

```swift
let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
```

### Data Models

The SDK uses generics to support any user model that conforms to `PBIdentifiableCollection`. You need to define your own User models:

```swift
// Define your User model
struct User: PBIdentifiableCollection {
    let id: String
    let email: String
    let username: String?
    let name: String?
    let avatar: String?
    let verified: Bool
    let created: String
    let updated: String
    let collectionId: String
    let collectionName: String
    // Add any additional fields your PocketBase user collection has
}
```

### Authentication

The SDK provides comprehensive authentication functionality with generic support:

#### User Authentication

```swift
// Sign up a new user
let createUserDto = CreateUser(
    email: "new@drewalth.com",
    name: "Test User",
    password: "password123",
    passwordConfirm: "password123")
let authResult = try await pb.signUp(dto: createUserDto, userType: User.self)

// Sign in with email/username and password
let authResult = try await pb.authWithPassword(
    email: "user@example.com",
    password: "password123",
    userType: User.self
)

// Refresh authentication token
let refreshResult = try await pb.authRefresh(userType: User.self)

// Check authentication status
if pb.isAuthenticated {
    print("User is authenticated")
    print("User ID: \(pb.currentUserId ?? "Unknown")")
}

// Sign out
pb.signOut()
```

#### Password Reset and Email Verification

```swift
// Request password reset
try await pb.requestPasswordReset(email: "user@example.com")

// Confirm password reset (with token from email)
try await pb.confirmPasswordReset(
    token: "reset_token_from_email",
    password: "newpassword",
    passwordConfirm: "newpassword"
)

// Request email verification
try await pb.requestVerification(email: "user@example.com")

// Confirm email verification (with token from email)
try await pb.confirmVerification(token: "verification_token_from_email")
```

### CRUD Operations

```swift
let bookmarksCollection = pb.collection("bookmarks")

// Get a single record
let bookmark = try await bookmarksCollection.getOne(id: "e849z3g13jls740")

// Get a list of records
let bookmarks = try await bookmarksCollection.getList()

// Create a new record
let newBookmark = try await bookmarksCollection.create(record: Bookmark(
    title: "My First Bookmark",
    url: "https://www.google.com"
))

// Update a record
let updatedBookmark = try await bookmarksCollection.update(
    id: newBookmark.id,
    record: Bookmark(
        title: "My Updated Bookmark",
        url: "https://www.google.com"
    )
)

// Delete a record
try await bookmarksCollection.delete(id: newBookmark.id)
```

### Expand Functionality

The SDK provides powerful expand functionality to include related data in your queries:

#### Basic Expansion

```swift
// Expand a single field
let expandQuery = ExpandQuery("author")
let posts = try await pb.getList(
    collection: "posts",
    model: Post.self,
    expand: expandQuery
)

// Expand multiple fields
let expandQuery = ExpandQuery("author", "category", "tags")
let posts = try await pb.getList(
    collection: "posts",
    model: Post.self,
    expand: expandQuery
)
```

#### Nested Expansion

```swift
// Expand nested relationships
let expandQuery = ExpandQuery("author.profile", "category.parent")
let posts = try await pb.getList(
    collection: "posts",
    model: Post.self,
    expand: expandQuery
)
```

#### Builder Pattern

```swift
// Use the builder pattern for complex expansions
let expandQuery = ExpandBuilder()
    .field("author")
    .field("category")
    .nested("author.profile")
    .nested("category.parent")
    .build()

let posts = try await pb.getList(
    collection: "posts",
    model: Post.self,
    expand: expandQuery
)
```

#### Fluent API with Expand

```swift
let posts: Collection<Post> = pb.collection("posts")

// Expand with fluent API
let expandQuery = ExpandQuery("author", "category")
let result = try await posts.getList(expand: expandQuery)

// Expand on single record
let post = try await posts.getOne(
    id: "post-id",
    expand: ExpandQuery("author.profile")
)
```

#### Conditional Expansion

```swift
let builder = ExpandBuilder()

if shouldIncludeAuthor {
    builder.field("author")
}

if shouldIncludeCategory {
    builder.field("category")
}

let expandQuery = builder.build()
let posts = try await pb.getList(
    collection: "posts",
    model: Post.self,
    expand: expandQuery
)
```

### Realtime

```swift
let realtime = pb.realtime(
    collection: "bookmarks",
    record: "*",
    onConnect: {
        print("Connected to realtime")
    },
    onDisconnect: {
        print("Disconnected from realtime")
    },
    onEvent: { event in
        print("Received event: \(event.action) for record: \(event.record)")
    }
)

try await realtime.subscribe()

// Unsubscribe from realtime
realtime.unsubscribe()
```

## Data Models

Define your data models by conforming to `PBCollection`:

```swift
struct Bookmark: PBCollection {
    let id: String
    let title: String
    let url: String
    let created: String
    let updated: String
    let collectionId: String
    let collectionName: String
}
```

For models that need an `id` property (like User and Admin), use `PBIdentifiableCollection`:

```swift
struct User: PBIdentifiableCollection {
    let id: String
    let email: String
    // ... other properties
}
```

