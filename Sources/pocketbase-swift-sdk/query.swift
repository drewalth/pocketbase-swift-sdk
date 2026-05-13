//
//  query.swift
//  PocketBase
//

#if canImport(SwiftUI)
    import os
    import SwiftUI

    // MARK: - PBQueryProjection

    public struct PBQueryProjection<T: PBCollection> {
        public let isLoading: Bool
        public let error: (any Error)?
        public let refresh: () -> Void
    }

    // MARK: - QueryStorage

    // @unchecked Sendable: all mutable state is accessed exclusively from @MainActor
    // via PBQuery's @State storage and @MainActor runFetch/setupRealtime methods.
    // @Observable enables SwiftUI to track property-level mutations on this reference type.
    @Observable
    private final class QueryStorage<T: PBCollection>: @unchecked Sendable {
        var items: [T] = []
        var isLoading = false
        var error: (any Error)?
        var configHash = 0
        var refreshToken = 0
        var lastRefreshToken = 0
        var fetchTask: Task<Void, Never>?
        var realtimeSubscription: Realtime<T>?

        deinit {
            fetchTask?.cancel()
            realtimeSubscription?.unsubscribe()
        }
    }

    // MARK: - PBQuery

    @propertyWrapper
    public struct PBQuery<T: PBCollection>: DynamicProperty {

        // MARK: Lifecycle

        public init(
            collection: String,
            filter: FiltersQuery? = nil,
            sort: [PBSortDescriptor<T>] = [],
            expand: ExpandQuery? = nil,
            perPage: Int = 100,
            realtime: Bool = false
        ) {
            self.collectionName = collection
            self.filter = filter
            self.sortDescriptors = sort
            self.expand = expand
            self.perPage = perPage
            self.realtimeEnabled = realtime
            self._storage = State(initialValue: QueryStorage())
        }

        public init<V>(
            collection: String,
            filter: FiltersQuery? = nil,
            sort keyPath: KeyPath<T, V> & Sendable,
            order: PBSortOrder = .forward,
            expand: ExpandQuery? = nil,
            perPage: Int = 100,
            realtime: Bool = false
        ) {
            self.init(
                collection: collection,
                filter: filter,
                sort: [PBSortDescriptor(keyPath, order: order)],
                expand: expand,
                perPage: perPage,
                realtime: realtime
            )
        }

        // MARK: Public

        public var wrappedValue: [T] { storage.items }

        public var projectedValue: PBQueryProjection<T> {
            PBQueryProjection(
                isLoading: storage.isLoading,
                error: storage.error,
                refresh: { [storage] in storage.refreshToken += 1 }
            )
        }

        // MARK: Internal

        public mutating func update() {
            guard let pb = pocketBase else {
                if storage.items.isEmpty, !storage.isLoading {
                    storage.error = PBError.missingEnvironment
                }
                return
            }

            if (storage.error as? PBError) == .missingEnvironment {
                storage.error = nil
            }

            let newHash = computeConfigHash()
            let tokenChanged = storage.refreshToken != storage.lastRefreshToken

            if tokenChanged {
                storage.lastRefreshToken = storage.refreshToken
            }

            let configChanged = newHash != storage.configHash
            let needsInitialFetch = storage.items.isEmpty && !storage.isLoading && storage.error == nil && storage.fetchTask == nil

            guard configChanged || tokenChanged || needsInitialFetch else { return }

            storage.configHash = newHash
            storage.fetchTask?.cancel()

            if configChanged {
                storage.realtimeSubscription?.unsubscribe()
                storage.realtimeSubscription = nil
            }

            let s = storage
            let name = collectionName
            let f = filter
            let descs = sortDescriptors
            let exp = expand
            let pp = perPage
            let rt = realtimeEnabled

            storage.fetchTask = Task { @MainActor [weak s] in
                guard let s else { return }
                await Self.runFetch(
                    pb: pb,
                    storage: s,
                    collection: name,
                    filter: f,
                    sortDescriptors: descs,
                    expand: exp,
                    perPage: pp,
                    realtime: rt
                )
            }
        }

        // MARK: Private

        @Environment(\.pocketBase) private var pocketBase
        @State private var storage: QueryStorage<T>

        private let collectionName: String
        private let filter: FiltersQuery?
        private let sortDescriptors: [PBSortDescriptor<T>]
        private let expand: ExpandQuery?
        private let perPage: Int
        private let realtimeEnabled: Bool

        private func computeConfigHash() -> Int {
            var hasher = Hasher()
            hasher.combine(collectionName)
            hasher.combine(filter?.queryString)
            for desc in sortDescriptors {
                hasher.combine(desc.fieldName)
                hasher.combine(desc.order)
            }
            hasher.combine(expand?.queryString)
            hasher.combine(perPage)
            hasher.combine(realtimeEnabled)
            return hasher.finalize()
        }

        @MainActor
        private static func runFetch(
            pb: PocketBase,
            storage: QueryStorage<T>,
            collection: String,
            filter: FiltersQuery?,
            sortDescriptors: [PBSortDescriptor<T>],
            expand: ExpandQuery?,
            perPage: Int,
            realtime: Bool
        ) async {
            let logger = Logger(category: "PBQuery")
            storage.isLoading = true
            storage.error = nil
            defer { storage.isLoading = false }

            do {
                let sortQuery = sortDescriptors.isEmpty ? nil : PBSortQuery(sortDescriptors)
                let result = try await pb.collection(collection).getList(
                    expand: expand,
                    filters: filter,
                    sort: sortQuery,
                    page: 1,
                    perPage: perPage
                )
                storage.items = result.items
            } catch is CancellationError {
                logger.debug("Fetch cancelled for collection '\(collection)'")
                return
            } catch {
                logger.error("Fetch failed for collection '\(collection)': \(error.localizedDescription)")
                storage.error = error
            }

            if realtime, storage.realtimeSubscription == nil {
                setupRealtime(
                    pb: pb,
                    storage: storage,
                    collection: collection,
                    filter: filter,
                    sortDescriptors: sortDescriptors,
                    expand: expand,
                    perPage: perPage
                )
            }
        }

        @MainActor
        private static func setupRealtime(
            pb: PocketBase,
            storage: QueryStorage<T>,
            collection: String,
            filter: FiltersQuery?,
            sortDescriptors: [PBSortDescriptor<T>],
            expand: ExpandQuery?,
            perPage: Int
        ) {
            let rt: Realtime<T> = pb.realtime(
                collection: collection,
                record: "*",
                onConnect: {},
                onDisconnect: {},
                onEvent: { [weak storage] _ in
                    guard let storage else { return }
                    storage.fetchTask?.cancel()
                    storage.fetchTask = Task { @MainActor [weak storage] in
                        guard let storage else { return }
                        await runFetch(
                            pb: pb,
                            storage: storage,
                            collection: collection,
                            filter: filter,
                            sortDescriptors: sortDescriptors,
                            expand: expand,
                            perPage: perPage,
                            realtime: false
                        )
                    }
                }
            )
            storage.realtimeSubscription = rt
            Task {
                do {
                    try await rt.subscribe()
                } catch {
                    let logger = Logger(category: "PBQuery")
                    logger.error("Realtime subscription failed for collection '\(collection)': \(error.localizedDescription)")
                    storage.error = error
                }
            }
        }
    }
#endif
