//
//  expand.swift
//  PocketBase
//
//  Created by Andrew Althage on 7/13/25.
//

// MARK: - ExpandQuery

/// Represents a PocketBase expand query with support for nested expansions
public struct ExpandQuery {

  // MARK: Lifecycle

  public init(_ fields: String...) {
    self.fields = fields
  }

  public init(_ fields: [String]) {
    self.fields = fields
  }

  // MARK: Public

  /// Build the expand query string for PocketBase API
  public var queryString: String {
    fields.joined(separator: ",")
  }

  /// Check if the expand query is empty
  public var isEmpty: Bool {
    fields.isEmpty
  }

  /// Add a field to expand
  public func expand(_ field: String) -> ExpandQuery {
    ExpandQuery(fields + [field])
  }

  /// Add nested expansion (e.g., "author.profile")
  public func expandNested(_ path: String) -> ExpandQuery {
    ExpandQuery(fields + [path])
  }

  // MARK: Private

  private let fields: [String]

}

// MARK: - ExpandBuilder

/// Type-safe expand builder for collections
public class ExpandBuilder {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  /// Add a field to expand
  @discardableResult
  public func field(_ field: String) -> ExpandBuilder {
    fields.append(field)
    return self
  }

  /// Add nested expansion (e.g., "author.profile")
  @discardableResult
  public func nested(_ path: String) -> ExpandBuilder {
    fields.append(path)
    return self
  }

  /// Build the expand query
  public func build() -> ExpandQuery {
    ExpandQuery(fields)
  }

  // MARK: Private

  private var fields: [String] = []

}
