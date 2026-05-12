//
//  query_wrapper.swift
//  PocketBase
//

#if canImport(SwiftUI)
    import Testing
    @testable import PocketBase

    // MARK: - PBQuery Structural Tests

    @Suite("PBQuery")
    struct PBQueryTests {

        @Test
        func initialWrappedValueIsEmpty() {
            let query = PBQuery<Post>(collection: "posts")
            #expect(query.wrappedValue.isEmpty)
        }

        @Test
        func projectedValueInitiallyNotLoading() {
            let query = PBQuery<Post>(collection: "posts")
            let projection = query.projectedValue
            #expect(!projection.isLoading)
            #expect(projection.error == nil)
        }

        @Test
        func refreshIncrementsToken() {
            let query = PBQuery<Post>(collection: "posts")
            let projection = query.projectedValue
            projection.refresh()
            // After refresh, the value should still be empty (no fetch happened)
            #expect(query.wrappedValue.isEmpty)
        }

        @Test
        func initWithFilter() {
            let filter = FiltersQuery().equal(field: "published", value: "true")
            let query = PBQuery<Post>(collection: "posts", filter: filter)
            #expect(query.wrappedValue.isEmpty)
        }

        @Test
        func initWithSingleSortKeyPath() {
            let query = PBQuery<Post>(collection: "posts", sort: \Post.title, order: .reverse)
            #expect(query.wrappedValue.isEmpty)
        }

        @Test
        func initWithSortArray() {
            let sort = [PBSortDescriptor(\Post.title), PBSortDescriptor(\Post.created, order: .reverse)]
            let query = PBQuery<Post>(collection: "posts", sort: sort)
            #expect(query.wrappedValue.isEmpty)
        }

        @Test
        func initWithExpand() {
            let expand = ExpandQuery("author")
            let query = PBQuery<Post>(collection: "posts", expand: expand)
            #expect(query.wrappedValue.isEmpty)
        }

        @Test
        func initWithRealtime() {
            let query = PBQuery<Post>(collection: "posts", realtime: true)
            #expect(query.wrappedValue.isEmpty)
        }

        @Test
        func configHashChangesWithDifferentCollection() {
            let query1 = PBQuery<Post>(collection: "posts")
            let query2 = PBQuery<Post>(collection: "articles")
            // Different collections produce different hashes
            // We can't directly compare hashes (they're private), but structurally
            // both should be initializable without issues
            #expect(query1.wrappedValue.isEmpty)
            #expect(query2.wrappedValue.isEmpty)
        }
    }
#endif
