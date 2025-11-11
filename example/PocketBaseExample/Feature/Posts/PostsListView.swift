//
//  PostsListView.swift
//  PocketBaseExample
//
//  Created by Andrew Althage on 8/2/25.
//

import Loadable
import PocketBase
import SwiftUI

struct PostsListView: View {

    // MARK: Internal

    @Environment(\.pocketBase) var pocketBase

    var body: some View {
        NavigationStack {
            List {
                LoadableView(postsData) { posts in
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
            }.listStyle(.insetGrouped)
            .listRowSpacing(8)
            .navigationTitle("Posts")
            .task {
                await loadPosts()
            }.onAppear {
                Task {
                    await connectRealtime()
                }
            }.onDisappear {
                guard let realtime else { return }
                realtime.unsubscribe()
            }
        }
    }

    // MARK: Private

    @State private var postsData: Loadable<[Post]> = .initial
    @State private var realtime: Realtime<Post>?
    @State private var connected = false

    private func loadPosts() async {
        do {
            postsData = .loading
            let postCollection: Collection<Post> = pocketBase.collection("posts")
            let postResult = try await postCollection.getList()
            postsData = .loaded(postResult.items)
        } catch {
            postsData = .error(error)
        }
    }

    private func connectRealtime() async {
        do {
            realtime = pocketBase.realtime(collection: "posts", onConnect: {
                connected = true
            }, onDisconnect: {
                connected = false
                print("Disconnected from realtime")
            }, onEvent: { event in
                print("Received event: \(event.action) for record: \(event.record.id)")
            })
            try await realtime?.subscribe()
        } catch {
            print("Error connecting to realtime: \(error)")
        }
    }
}

#Preview {
    PostsListView()
}
