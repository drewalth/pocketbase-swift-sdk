//
//  environment.swift
//  PocketBase
//

#if canImport(SwiftUI)
    import SwiftUI

    // MARK: - PocketBaseEnvironmentKey

    private struct PocketBaseEnvironmentKey: EnvironmentKey {
        static let defaultValue: PocketBase? = nil
    }

    extension EnvironmentValues {

        // MARK: Public

        public var pocketBase: PocketBase? {
            get { self[PocketBaseEnvironmentKey.self] }
            set { self[PocketBaseEnvironmentKey.self] = newValue }
        }
    }
#endif
