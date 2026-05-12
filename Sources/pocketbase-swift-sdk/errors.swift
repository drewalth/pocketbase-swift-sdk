//
//  errors.swift
//  PocketBase
//

import Foundation

// MARK: - PBError

public enum PBError: Error, LocalizedError {
    case missingEnvironment
    case notAuthenticated
    case fetchCancelled

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case .missingEnvironment:
            "PocketBase instance not found in SwiftUI environment. Use .environment(\\.pocketBase, pocketBase) in your App."
        case .notAuthenticated:
            "User is not authenticated."
        case .fetchCancelled:
            "Fetch was cancelled."
        }
    }
}
