//
//  environment.swift
//  PocketBase
//

#if canImport(SwiftUI)
    import SwiftUI

    extension EnvironmentValues {
        @Entry public var pocketBase: PocketBase? = nil
    }
#endif
