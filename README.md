# Pocketbase Swift SDK

A Swift SDK for [Pocketbase](https://pocketbase.io/) v0.28.2.

> Note: This is a work in progress. The SDK is not yet complete.

## Usage

```swift
let pb = PocketBase(baseURL: "http://127.0.0.1:8090")
let bookmarksCollection = pb.collection("bookmarks")

// Get a single record
let bookmark = try await bookmarksCollection.getOne(id: "e849z3g13jls740")

// Get a list of records
let bookmarks = try await bookmarksCollection.getList()

// Create a new record
let newBookmark = try await bookmarksCollection.create(data: [
  "title": "My First Bookmark",
  "url": "https://www.google.com"
])

// Update a record
let updatedBookmark = try await bookmarksCollection.update(id: newBookmark.id, data: [
  "title": "My Updated Bookmark"
])

// Delete a record
try await bookmarksCollection.delete(id: newBookmark.id)
```

## Realtime

```swift
let realtime = Realtime(baseURL: "http://127.0.0.1:8090", collection: "bookmarks", record: "*", onConnect: {
  print("Connected to realtime")
}, onDisconnect: {
  print("Disconnected from realtime")
}, onEvent: { event in
  print("Received event: \(event)")
})

try await realtime.subscribe()

// Unsubscribe from realtime
try await realtime.unsubscribe()
```