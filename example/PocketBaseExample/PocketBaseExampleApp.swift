//
//  PocketBaseExampleApp.swift
//  PocketBaseExample
//
//  Created by Andrew Althage on 8/2/25.
//

import PocketBase
import SwiftUI

// MARK: - PB

private struct PB: EnvironmentKey {
  static let defaultValue = PocketBase(baseURL: "http://127.0.0.1:8090")
}

extension EnvironmentValues {
  var pocketBase: PocketBase {
    get {
      self[PB.self]
    } set {
      self[PB.self] = newValue
    }
  }
}

// MARK: - PocketBaseExampleApp

@main
struct PocketBaseExampleApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
