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

    var body: some View {
        TabView {
            PostsListView()
                .tag(Tabs.postList)
                .tabItem {
                    Label("Posts", systemImage: "list.bullet")
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
    case auth
}
