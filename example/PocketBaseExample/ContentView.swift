//
//  ContentView.swift
//  PocketBaseExample
//
//  Created by Andrew Althage on 8/2/25.
//

import PocketBase
import SwiftUI

// MARK: - ContentView

struct ContentView: View {

    @Environment(\.pocketBase) private var pocketBase

    var body: some View {
        TabView {
            PostsListView()
                .tag(Tabs.postList)
                .tabItem {
                    Label("Posts", systemImage: "list.bullet")
                }
            if let pocketBase {
                PostsUIKitWrapper(pocketBase: pocketBase)
                    .tag(Tabs.postsUIKit)
                    .tabItem {
                        Label("Posts UIKit", systemImage: "rectangle.grid.1x2")
                    }
            }
            AuthView()
                .tag(Tabs.auth)
                .tabItem {
                    Label("Auth", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Tabs

enum Tabs {
    case postList
    case postsUIKit
    case auth
}
