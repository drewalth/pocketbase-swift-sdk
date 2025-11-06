//
//  filters.swift
//  PocketBase
//
//  Created by Andrew Althage on 7/14/25.
//

// MARK: - FilterOperator

/// PocketBase filter operators
public enum FilterOperator: String, CaseIterable {
    case equal = "="
    case notEqual = "!="
    case greaterThan = ">"
    case greaterThanOrEqual = ">="
    case lessThan = "<"
    case lessThanOrEqual = "<="
    case like = "~"
    case notLike = "!~"
    case contains = "?~"
    case notContains = "!?~"
    case `in` = "?="
    case notIn = "!?="
}

// MARK: - FilterCondition

/// Represents a single filter condition
public struct FilterCondition {

    // MARK: Lifecycle

    public init(field: String, op: FilterOperator, value: String) {
        self.field = field
        self.op = op
        self.value = value
    }

    // MARK: Public

    public let field: String
    public let op: FilterOperator
    public let value: String

    /// Build the filter condition string
    public var conditionString: String {
        let lower = value.lowercased()
        let needsQuotes = !(lower == "null" || lower == "true" || lower == "false" || Double(value) != nil || isDateValue(value))
        let quotedValue = needsQuotes ? "\"\(value)\"" : value
        return "\(field)\(op.rawValue)\(quotedValue)"
    }

    // MARK: Private

    /// Check if a value looks like a date
    private func isDateValue(_ value: String) -> Bool {
        // Simple date pattern matching
        let datePatterns = [
            #"^\d{4}-\d{2}-\d{2}$"#, // YYYY-MM-DD
            #"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$"#, // YYYY-MM-DD HH:MM:SS
            #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}"# // ISO 8601 format
        ]

        return datePatterns.contains { pattern in
            value.range(of: pattern, options: .regularExpression) != nil
        }
    }
}

// MARK: - FiltersQuery

/// Represents a PocketBase filters query with support for multiple conditions
public struct FiltersQuery {

    // MARK: Lifecycle

    public init(_ conditions: FilterCondition...) {
        self.conditions = conditions
    }

    public init(_ conditions: [FilterCondition]) {
        self.conditions = conditions
    }

    // MARK: Public

    /// Build the filters query string for PocketBase API
    public var queryString: String {
        conditions.map { $0.conditionString }.joined(separator: "&&")
    }

    /// Check if the filters query is empty
    public var isEmpty: Bool {
        conditions.isEmpty
    }

    /// Add a filter condition
    public func filter(_ condition: FilterCondition) -> FiltersQuery {
        FiltersQuery(conditions + [condition])
    }

    /// Add a simple filter condition
    public func filter(field: String, op: FilterOperator, value: String) -> FiltersQuery {
        let condition = FilterCondition(field: field, op: op, value: value)
        return filter(condition)
    }

    /// Add an equality filter
    public func equal(field: String, value: String) -> FiltersQuery {
        filter(field: field, op: .equal, value: value)
    }

    /// Add a not equal filter
    public func notEqual(field: String, value: String) -> FiltersQuery {
        filter(field: field, op: .notEqual, value: value)
    }

    /// Add a greater than filter
    public func greaterThan(field: String, value: String) -> FiltersQuery {
        filter(field: field, op: .greaterThan, value: value)
    }

    /// Add a greater than or equal filter
    public func greaterThanOrEqual(field: String, value: String) -> FiltersQuery {
        filter(field: field, op: .greaterThanOrEqual, value: value)
    }

    /// Add a less than filter
    public func lessThan(field: String, value: String) -> FiltersQuery {
        filter(field: field, op: .lessThan, value: value)
    }

    /// Add a less than or equal filter
    public func lessThanOrEqual(field: String, value: String) -> FiltersQuery {
        filter(field: field, op: .lessThanOrEqual, value: value)
    }

    /// Add a like filter (pattern matching)
    public func like(field: String, value: String) -> FiltersQuery {
        filter(field: field, op: .like, value: value)
    }

    /// Add a not like filter
    public func notLike(field: String, value: String) -> FiltersQuery {
        filter(field: field, op: .notLike, value: value)
    }

    /// Add a contains filter
    public func contains(field: String, value: String) -> FiltersQuery {
        filter(field: field, op: .contains, value: value)
    }

    /// Add a not contains filter
    public func notContains(field: String, value: String) -> FiltersQuery {
        filter(field: field, op: .notContains, value: value)
    }

    /// Add an in filter (value in array)
    public func `in`(field: String, values: [String]) -> FiltersQuery {
        let valueString = values.joined(separator: ",")
        return filter(field: field, op: .in, value: valueString)
    }

    /// Add a not in filter
    public func notIn(field: String, values: [String]) -> FiltersQuery {
        let valueString = values.joined(separator: ",")
        return filter(field: field, op: .notIn, value: valueString)
    }

    /// Add an is null filter
    public func isNull(field: String) -> FiltersQuery {
        filter(field: field, op: .equal, value: "null")
    }

    /// Add an is not null filter
    public func isNotNull(field: String) -> FiltersQuery {
        filter(field: field, op: .notEqual, value: "null")
    }

    // MARK: Private

    private let conditions: [FilterCondition]
}

// MARK: - FilterBuilder

/// Type-safe filter builder for collections
public class FilterBuilder {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    /// Add a filter condition
    @discardableResult
    public func condition(_ condition: FilterCondition) -> FilterBuilder {
        conditions.append(condition)
        return self
    }

    /// Add a simple filter condition
    @discardableResult
    public func filter(field: String, op: FilterOperator, value: String) -> FilterBuilder {
        let condition = FilterCondition(field: field, op: op, value: value)
        conditions.append(condition)
        return self
    }

    /// Add an equality filter
    @discardableResult
    public func equal(field: String, value: String) -> FilterBuilder {
        filter(field: field, op: .equal, value: value)
    }

    /// Add a not equal filter
    @discardableResult
    public func notEqual(field: String, value: String) -> FilterBuilder {
        filter(field: field, op: .notEqual, value: value)
    }

    /// Add a greater than filter
    @discardableResult
    public func greaterThan(field: String, value: String) -> FilterBuilder {
        filter(field: field, op: .greaterThan, value: value)
    }

    /// Add a greater than or equal filter
    @discardableResult
    public func greaterThanOrEqual(field: String, value: String) -> FilterBuilder {
        filter(field: field, op: .greaterThanOrEqual, value: value)
    }

    /// Add a less than filter
    @discardableResult
    public func lessThan(field: String, value: String) -> FilterBuilder {
        filter(field: field, op: .lessThan, value: value)
    }

    /// Add a less than or equal filter
    @discardableResult
    public func lessThanOrEqual(field: String, value: String) -> FilterBuilder {
        filter(field: field, op: .lessThanOrEqual, value: value)
    }

    /// Add a like filter (pattern matching)
    @discardableResult
    public func like(field: String, value: String) -> FilterBuilder {
        filter(field: field, op: .like, value: value)
    }

    /// Add a not like filter
    @discardableResult
    public func notLike(field: String, value: String) -> FilterBuilder {
        filter(field: field, op: .notLike, value: value)
    }

    /// Add a contains filter
    @discardableResult
    public func contains(field: String, value: String) -> FilterBuilder {
        filter(field: field, op: .contains, value: value)
    }

    /// Add a not contains filter
    @discardableResult
    public func notContains(field: String, value: String) -> FilterBuilder {
        filter(field: field, op: .notContains, value: value)
    }

    /// Add an in filter (value in array)
    @discardableResult
    public func `in`(field: String, values: [String]) -> FilterBuilder {
        let valueString = values.joined(separator: ",")
        return filter(field: field, op: .in, value: valueString)
    }

    /// Add a not in filter
    @discardableResult
    public func notIn(field: String, values: [String]) -> FilterBuilder {
        let valueString = values.joined(separator: ",")
        return filter(field: field, op: .notIn, value: valueString)
    }

    /// Add an is null filter
    @discardableResult
    public func isNull(field: String) -> FilterBuilder {
        filter(field: field, op: .equal, value: "null")
    }

    /// Add an is not null filter
    @discardableResult
    public func isNotNull(field: String) -> FilterBuilder {
        filter(field: field, op: .notEqual, value: "null")
    }

    /// Build the filters query
    public func build() -> FiltersQuery {
        FiltersQuery(conditions)
    }

    // MARK: Private

    private var conditions: [FilterCondition] = []
}
