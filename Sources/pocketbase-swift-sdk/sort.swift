//
//  sort.swift
//  PocketBase
//

import Foundation

// MARK: - PBSortOrder

public enum PBSortOrder: String, Sendable, CaseIterable {
    case forward
    case reverse
}

// MARK: - PBSortDescriptor

public struct PBSortDescriptor<T>: Equatable, Hashable, Sendable {

    // MARK: Lifecycle

    public init<V>(_ keyPath: KeyPath<T, V> & Sendable, order: PBSortOrder = .forward) {
        self.fieldName = Self.extractFieldName(from: keyPath)
        self.order = order
    }

    public init(_ fieldName: String, order: PBSortOrder = .forward) {
        precondition(!fieldName.isEmpty, "PBSortDescriptor fieldName must not be empty")
        self.fieldName = fieldName
        self.order = order
    }

    // MARK: Public

    public let fieldName: String
    public let order: PBSortOrder

    public var queryString: String {
        switch order {
        case .forward: fieldName
        case .reverse: "-\(fieldName)"
        }
    }

    // MARK: Private

    // Relies on String(describing: keyPath) producing the "\TypeName.property" format.
    // If Swift changes KeyPath's description format in a future version, this may silently
    // produce incorrect field names. Use the String-based init as an escape hatch.
    private static func extractFieldName<V>(from keyPath: KeyPath<T, V>) -> String {
        let description = String(describing: keyPath)
        guard let backslashIndex = description.firstIndex(of: "\\") else {
            return description
        }
        let afterBackslash = description[description.index(after: backslashIndex)...]
        guard let dotIndex = afterBackslash.firstIndex(of: ".") else {
            return String(afterBackslash)
        }
        return String(afterBackslash[afterBackslash.index(after: dotIndex)...])
    }
}

// MARK: - PBSortQuery

public struct PBSortQuery<T>: Equatable, Sendable {

    // MARK: Lifecycle

    public init(_ descriptors: PBSortDescriptor<T>...) {
        self.descriptors = descriptors
    }

    public init(_ descriptors: [PBSortDescriptor<T>]) {
        self.descriptors = descriptors
    }

    // MARK: Public

    public let descriptors: [PBSortDescriptor<T>]

    public var queryString: String {
        descriptors.map(\.queryString).joined(separator: ",")
    }

    public var isEmpty: Bool {
        descriptors.isEmpty
    }
}
