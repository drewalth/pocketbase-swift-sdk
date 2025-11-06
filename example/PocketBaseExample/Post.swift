//
//  Post.swift
//  PocketBaseExample
//
//  Created by Andrew Althage on 8/2/25.
//

import PocketBase

public struct Post: PBBaseRecord, Decodable, Encodable, Sendable, Identifiable {

    // MARK: Lifecycle

    public init(id: String, title: String, created: String, updated: String) {
        self.id = id
        self.title = title
        self.created = created
        self.updated = updated
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        created = try container.decode(String.self, forKey: .created)
        updated = try container.decode(String.self, forKey: .updated)
    }

    // MARK: Public

    public let id: String
    public let title: String
    public let created: String
    public let updated: String

    // MARK: Internal

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case created
        case updated
    }
}
