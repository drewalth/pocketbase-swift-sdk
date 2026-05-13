//
//  PostsListView.swift
//  PocketBaseExample
//

import PocketBase
import SwiftUI

struct PostsListView: View {

    // MARK: Internal

    @PBQuery(collection: "posts", sort: \Post.created, order: .reverse)
    private var posts: [Post]

    var body: some View {
        NavigationStack {
            List {
                if $posts.isLoading, posts.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView("Loading posts...")
                        Spacer()
                    }
                } else if let error = $posts.error {
                    VStack {
                        Text("Error loading posts")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.red)
                        Button("Retry") {
                            $posts.refresh()
                        }
                    }
                } else {
                    ForEach(posts) { post in
                        NavigationLink(post.title) {
                            PostDetailView(post: post)
                        }
                    }
                }

                Section {
                    HStack {
                        Text("Realtime server \(connected ? "connected" : "disconnected")")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listRowSpacing(8)
            .navigationTitle("Posts")
            .refreshable {
                $posts.refresh()
            }
            .task {
                await connectRealtime()
            }
            .onDisappear {
                realtime?.unsubscribe()
            }
        }
    }

    // MARK: Private

    @Environment(\.pocketBase) private var pocketBase
    @State private var realtime: Realtime<Post>?
    @State private var connected = false

    private func connectRealtime() async {
        guard let pb = pocketBase else { return }
        realtime = pb.realtime(collection: "posts", onConnect: {
            connected = true
        }, onDisconnect: {
            connected = false
            print("Disconnected from realtime")
        }, onEvent: { event in
            print("Received event: \(event.action) for record: \(event.record.id)")
        })
        do {
            try await realtime?.subscribe()
        } catch {
            print("Error connecting to realtime: \(error)")
        }
    }
}

#Preview {
    PostsListView()
        .environment(\.pocketBase, PocketBase(baseURL: "http://127.0.0.1:8090"))
}
