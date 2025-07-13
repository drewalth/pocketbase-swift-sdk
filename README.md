# Pocketbase Swift SDK

A Swift SDK for [Pocketbase](https://pocketbase.io/) v0.28.2.

> Note: This is a work in progress. The SDK is not yet complete.

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-username/pocketbase-swift-sdk.git", from: "1.0.0")
]
```

## Usage

### Basic Setup

```swift
let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
```

### Data Models

The SDK uses generics to support any user model that conforms to `PBIdentifiableCollection`. You need to define your own User and Admin models:

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

// Define your Admin model
struct Admin: PBIdentifiableCollection {
    let id: String
    let email: String
    let avatar: String?
    let created: String
    let updated: String
    // Add any additional fields your PocketBase admin collection has
}
```

### Authentication

The SDK provides comprehensive authentication functionality with generic support:

#### User Authentication

```swift
// Sign up a new user
let authResult = try await pb.signUp(
    email: "user@example.com",
    password: "password123",
    passwordConfirm: "password123",
    username: "username",
    name: "John Doe",
    userType: User.self
)

// Sign in with email/username and password
let authResult = try await pb.authWithPassword(
    email: "user@example.com",
    password: "password123",
    userType: User.self
)

// Or sign in with username
let authResult = try await pb.authWithPassword(
    username: "username",
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

#### Admin Authentication

```swift
// Sign in as admin
let adminAuth = try await pb.authWithPassword(
    email: "admin@example.com",
    password: "adminpassword",
    adminType: Admin.self
)

// Refresh admin token
let adminRefresh = try await pb.authRefreshAdmin(adminType: Admin.self)

// Check admin authentication status
if pb.isAdminAuthenticated {
    print("Admin is authenticated")
    print("Admin ID: \(pb.currentAdminId ?? "Unknown")")
}
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

#### Authentication Methods

```swift
// Get available authentication methods
let authMethods = try await pb.getAuthMethods()
print("Username/Password enabled: \(authMethods.usernamePassword)")
print("Email/Password enabled: \(authMethods.emailPassword)")
print("Auth providers: \(authMethods.authProviders)")
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

## Features

- ✅ Generic user and admin authentication (supports any model)
- ✅ User authentication (sign up, sign in, sign out)
- ✅ Admin authentication
- ✅ Token refresh
- ✅ Password reset
- ✅ Email verification
- ✅ CRUD operations
- ✅ Realtime subscriptions
- ✅ Type-safe data models
- ✅ Automatic token management