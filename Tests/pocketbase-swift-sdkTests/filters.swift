//
//  filters_examples.swift
//  pocketbase-swift-sdkTests
//
//  Created by Andrew Althage on 7/14/25.
//

import Testing
@testable import PocketBase

// MARK: - FiltersExamples

@Suite("Filters Examples")
struct FiltersExamples {

  @Test("Basic filter usage")
  func testBasicFilterUsage() throws {
    // Example 1: Simple equality filter
    let filter1 = FiltersQuery()
      .equal(field: "status", value: "active")

    #expect(filter1.queryString == "status=\"active\"")

    // Example 2: Multiple conditions
    let filter2 = FiltersQuery()
      .equal(field: "status", value: "active")
      .greaterThan(field: "age", value: "18")

    #expect(filter2.queryString == "status=\"active\"&&age>18")
  }

  @Test("Filter builder usage")
  func testFilterBuilderUsage() throws {
    // Using the builder pattern
    let filter = FilterBuilder()
      .equal(field: "category", value: "electronics")
      .greaterThan(field: "price", value: "100")
      .contains(field: "name", value: "phone")
      .build()

    #expect(filter.queryString == "category=\"electronics\"&&price>100&&name?~\"phone\"")
  }

  @Test("String filters")
  func testStringFilters() throws {
    // Like filter for pattern matching
    let likeFilter = FiltersQuery()
      .like(field: "name", value: "john")

    #expect(likeFilter.queryString == "name~\"john\"")

    // Contains filter
    let containsFilter = FiltersQuery()
      .contains(field: "description", value: "important")

    #expect(containsFilter.queryString == "description?~\"important\"")

    // Not contains filter
    let notContainsFilter = FiltersQuery()
      .notContains(field: "tags", value: "deprecated")

    #expect(notContainsFilter.queryString == "tags!?~\"deprecated\"")
  }

  @Test("Numeric filters")
  func testNumericFilters() throws {
    // Range filters
    let rangeFilter = FiltersQuery()
      .greaterThanOrEqual(field: "price", value: "10")
      .lessThanOrEqual(field: "price", value: "100")

    #expect(rangeFilter.queryString == "price>=10&&price<=100")

    // Not equal
    let notEqualFilter = FiltersQuery()
      .notEqual(field: "quantity", value: "0")

    #expect(notEqualFilter.queryString == "quantity!=0")
  }

  @Test("Array filters")
  func testArrayFilters() throws {
    // In filter
    let inFilter = FiltersQuery()
      .in(field: "status", values: ["active", "pending", "review"])

    #expect(inFilter.queryString == "status?=\"active,pending,review\"")

    // Not in filter
    let notInFilter = FiltersQuery()
      .notIn(field: "category", values: ["deleted", "archived"])

    #expect(notInFilter.queryString == "category!?=\"deleted,archived\"")
  }

  @Test("Null filters")
  func testNullFilters() throws {
    // Is null
    let isNullFilter = FiltersQuery()
      .isNull(field: "deleted_at")

    #expect(isNullFilter.queryString == "deleted_at=null")

    // Is not null
    let isNotNullFilter = FiltersQuery()
      .isNotNull(field: "email")

    #expect(isNotNullFilter.queryString == "email!=null")
  }

  @Test("Complex filters")
  func testComplexFilters() throws {
    // Complex filter with multiple conditions
    let complexFilter = FilterBuilder()
      .equal(field: "status", value: "active")
      .greaterThan(field: "created_at", value: "2024-01-01")
      .contains(field: "title", value: "important")
      .notIn(field: "category", values: ["deleted", "archived"])
      .isNotNull(field: "user_id")
      .build()

    let expected = "status=\"active\"&&created_at>2024-01-01&&title?~\"important\"&&category!?=\"deleted,archived\"&&user_id!=null"
    #expect(complexFilter.queryString == expected)
  }

  @Test("Filter condition direct usage")
  func testFilterConditionDirectUsage() throws {
    // Direct FilterCondition usage
    let condition1 = FilterCondition(field: "name", op: .like, value: "john")
    let condition2 = FilterCondition(field: "age", op: .greaterThan, value: "25")

    let filter = FiltersQuery(condition1, condition2)

    #expect(filter.queryString == "name~\"john\"&&age>25")
  }

  @Test("Empty filters")
  func testEmptyFilters() throws {
    // Empty filter
    let emptyFilter = FiltersQuery()
    #expect(emptyFilter.isEmpty)
    #expect(emptyFilter.queryString == "")

    // Empty builder
    let emptyBuilder = FilterBuilder().build()
    #expect(emptyBuilder.isEmpty)
    #expect(emptyBuilder.queryString == "")
  }

  @Test("Filter chaining")
  func testFilterChaining() throws {
    // Chaining filters
    let filter = FiltersQuery()
      .equal(field: "type", value: "user")
      .filter(field: "active", op: .equal, value: "true")
      .like(field: "email", value: "@example.com")

    #expect(filter.queryString == "type=\"user\"&&active=true&&email~\"@example.com\"")
  }

  @Test("Filter operators")
  func testFilterOperators() throws {
    // Test all operators
    let operators: [FilterOperator] = [
      .equal, .notEqual, .greaterThan, .greaterThanOrEqual,
      .lessThan, .lessThanOrEqual, .like, .notLike,
      .contains, .notContains, .`in`, .notIn,
    ]

    for op in operators {
      let condition = FilterCondition(field: "test", op: op, value: "value")
      #expect(!condition.conditionString.isEmpty)
    }
  }
}

// MARK: - RealWorldFilterExamples

@Suite("Real-world Filter Examples")
struct RealWorldFilterExamples {

  @Test("User search example")
  func testUserSearchExample() throws {
    // Example: Search for active users with specific criteria
    let userFilter = FilterBuilder()
      .equal(field: "status", value: "active")
      .greaterThan(field: "last_login", value: "2024-01-01")
      .contains(field: "email", value: "@company.com")
      .notIn(field: "role", values: ["admin", "superuser"])
      .isNotNull(field: "profile_completed")
      .build()

    // This would generate: status="active"&&last_login>2024-01-01&&email?~"@company.com"&&role!?="admin,superuser"&&profile_completed!=null
    #expect(!userFilter.isEmpty)
    #expect(userFilter.queryString.contains("status=\"active\""))
    #expect(userFilter.queryString.contains("email?~\"@company.com\""))
  }

  @Test("Product search example")
  func testProductSearchExample() throws {
    // Example: Product search with price range and category
    let productFilter = FilterBuilder()
      .equal(field: "category", value: "electronics")
      .greaterThanOrEqual(field: "price", value: "50")
      .lessThanOrEqual(field: "price", value: "500")
      .like(field: "name", value: "phone")
      .notEqual(field: "stock", value: "0")
      .build()

    // This would generate: category="electronics"&&price>=50&&price<=500&&name~"phone"&&stock!=0
    #expect(!productFilter.isEmpty)
    #expect(productFilter.queryString.contains("price>="))
    #expect(productFilter.queryString.contains("price<="))
  }

  @Test("Order filter example")
  func testOrderFilterExample() throws {
    // Example: Order filtering with date range and status
    let orderFilter = FilterBuilder()
      .in(field: "status", values: ["pending", "processing", "shipped"])
      .greaterThan(field: "created_at", value: "2024-01-01")
      .lessThan(field: "created_at", value: "2024-12-31")
      .greaterThan(field: "total", value: "100")
      .build()

    // This would generate: status?="pending,processing,shipped"&&created_at>2024-01-01&&created_at<2024-12-31&&total>100
    #expect(!orderFilter.isEmpty)
    #expect(orderFilter.queryString.contains("status?="))
    #expect(orderFilter.queryString.contains("total>100"))
  }
}

// MARK: - FilterEdgeCases

@Suite("Filter Edge Cases")
struct FilterEdgeCases {

  @Test("Special characters in values")
  func testSpecialCharactersInValues() throws {
    let filter = FiltersQuery()
      .equal(field: "name", value: "John Doe")
      .contains(field: "description", value: "test@example.com")
      .like(field: "path", value: "/api/users")

    #expect(filter.queryString.contains("name=\"John Doe\""))
    #expect(filter.queryString.contains("description?~\"test@example.com\""))
    #expect(filter.queryString.contains("path~\"/api/users\""))
  }

  @Test("Empty values")
  func testEmptyValues() throws {
    let filter = FiltersQuery()
      .equal(field: "empty_field", value: "")
      .isNull(field: "null_field")

    #expect(filter.queryString.contains("empty_field=\"\""))
    #expect(filter.queryString.contains("null_field=null"))
  }

  @Test("Single condition filters")
  func testSingleConditionFilters() throws {
    let singleFilter = FiltersQuery()
      .equal(field: "status", value: "active")

    #expect(singleFilter.queryString == "status=\"active\"")
    #expect(!singleFilter.isEmpty)
  }

  @Test("Filter with spaces in field names")
  func testFilterWithSpacesInFieldNames() throws {
    let filter = FiltersQuery()
      .equal(field: "user name", value: "John")
      .greaterThan(field: "created date", value: "2024-01-01")

    #expect(filter.queryString.contains("user name=\"John\""))
    #expect(filter.queryString.contains("created date>2024-01-01"))
  }
}