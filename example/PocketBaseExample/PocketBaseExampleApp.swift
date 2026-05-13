//
//  PocketBaseExampleApp.swift
//  PocketBaseExample
//

import PocketBase
import SwiftUI

// MARK: - PocketBaseExampleApp

@main
struct PocketBaseExampleApp: App {
    @State private var pocketBase = PocketBase(baseURL: "http://127.0.0.1:8090")

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.pocketBase, pocketBase)
        }
    }
}
