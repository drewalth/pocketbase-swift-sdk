//
//  auth_state.swift
//  PocketBase
//

#if canImport(SwiftUI)
    import SwiftUI

    // MARK: - PBAuthInfo

    public enum PBAuthInfo: Sendable {
        case authenticated(userId: String)
        case notAuthenticated

        public var isAuthenticated: Bool {
            if case .authenticated = self { true } else { false }
        }

        public var userId: String? {
            if case .authenticated(let id) = self { id } else { nil }
        }
    }

    // MARK: - PBAuthProjection

    public struct PBAuthProjection {
        public let isAuthenticated: Bool
        public let userId: String?
        public let error: (any Error)?
        public let refresh: () -> Void
    }

    // MARK: - AuthStorage

    // @unchecked Sendable: all mutable state is accessed exclusively from @MainActor
    // via PBAuthState's @State storage and update() method.
    // @Observable enables SwiftUI to track property-level mutations on this reference type.
    @Observable
    private final class AuthStorage: @unchecked Sendable {
        var isAuthenticated = false
        var userId: String?
        var error: (any Error)?
        var refreshToken = 0
        var lastRefreshToken = 0
    }

    // MARK: - PBAuthState

    @propertyWrapper
    public struct PBAuthState: DynamicProperty {

        // MARK: Lifecycle

        public init() {
            self._storage = State(initialValue: AuthStorage())
        }

        // MARK: Public

        public var wrappedValue: PBAuthInfo {
            if storage.isAuthenticated, let userId = storage.userId {
                .authenticated(userId: userId)
            } else {
                .notAuthenticated
            }
        }

        public var projectedValue: PBAuthProjection {
            PBAuthProjection(
                isAuthenticated: storage.isAuthenticated,
                userId: storage.userId,
                error: storage.error,
                refresh: { [storage] in storage.refreshToken += 1 }
            )
        }

        // MARK: Internal

        public mutating func update() {
            guard let pb = pocketBase else {
                storage.error = PBError.missingEnvironment
                return
            }

            storage.error = nil

            let needsRefresh = storage.refreshToken != storage.lastRefreshToken
            if needsRefresh {
                storage.lastRefreshToken = storage.refreshToken
            }

            let currentAuth = pb.isAuthenticated
            let currentId = pb.currentUserId

            if needsRefresh || storage.isAuthenticated != currentAuth || storage.userId != currentId {
                storage.isAuthenticated = currentAuth
                storage.userId = currentId
            }
        }

        // MARK: Private

        @Environment(\.pocketBase) private var pocketBase
        @State private var storage: AuthStorage
    }
#endif
