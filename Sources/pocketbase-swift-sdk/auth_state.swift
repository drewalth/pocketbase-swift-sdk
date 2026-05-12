//
//  auth_state.swift
//  PocketBase
//

#if canImport(SwiftUI)
    import SwiftUI

    // MARK: - PBAuthInfo

    public enum PBAuthInfo {
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

    // MARK: - PBAuthState

    @propertyWrapper
    public struct PBAuthState: DynamicProperty {

        // MARK: Lifecycle

        public init() {
            self._isAuthenticated = State(initialValue: false)
            self._userId = State(initialValue: nil)
            self._error = State(initialValue: nil)
            self._refreshToken = State(initialValue: 0)
            self._lastRefreshToken = State(initialValue: 0)
        }

        // MARK: Public

        public var wrappedValue: PBAuthInfo {
            if isAuthenticated, let userId {
                .authenticated(userId: userId)
            } else {
                .notAuthenticated
            }
        }

        public var projectedValue: PBAuthProjection {
            PBAuthProjection(
                isAuthenticated: isAuthenticated,
                userId: userId,
                error: error,
                refresh: { refreshToken += 1 }
            )
        }

        // MARK: Internal

        public mutating func update() {
            guard let pb = pocketBase else {
                error = PBError.missingEnvironment
                return
            }

            error = nil

            let needsRefresh = refreshToken != lastRefreshToken
            if needsRefresh {
                lastRefreshToken = refreshToken
            }

            let currentAuth = pb.isAuthenticated
            let currentId = pb.currentUserId

            if needsRefresh || isAuthenticated != currentAuth || userId != currentId {
                isAuthenticated = currentAuth
                userId = currentId
            }
        }

        // MARK: Private

        @Environment(\.pocketBase) private var pocketBase

        @State private var isAuthenticated: Bool
        @State private var userId: String?
        @State private var error: (any Error)?
        @State private var refreshToken: Int
        @State private var lastRefreshToken: Int
    }
#endif
