//
//  auth_state_wrapper.swift
//  PocketBase
//

#if canImport(SwiftUI)
    import Testing
    @testable import PocketBase

    // MARK: - PBAuthState Structural Tests

    @Suite("PBAuthState")
    struct PBAuthStateTests {

        @Test
        func initialAuthInfoIsNotAuthenticated() {
            let state = PBAuthState()
            let info = state.wrappedValue
            #expect(!info.isAuthenticated)
            #expect(info.userId == nil)
        }

        @Test
        func projectedValueReflectsState() {
            let state = PBAuthState()
            let projection = state.projectedValue
            #expect(!projection.isAuthenticated)
            #expect(projection.userId == nil)
        }

        @Test
        func refreshIsCallable() {
            let state = PBAuthState()
            let projection = state.projectedValue
            projection.refresh()
            // After refresh, state should still be not authenticated (no PocketBase instance)
            #expect(!state.wrappedValue.isAuthenticated)
        }
    }
#endif
