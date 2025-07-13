//
//  test-models.swift
//  PocketBase
//
//  Created by Andrew Althage on 7/13/25.
//

import Foundation
@testable import PocketBase

// MARK: - User

// Copy this to your project and customize as needed

public struct User: PBIdentifiableCollection {
  public let id: String
  public let email: String
  public let username: String?
  public let name: String?
  public let avatar: String?
  public let verified: Bool
  public let created: String
  public let updated: String
  public let collectionId: String
  public let collectionName: String
}

// MARK: - CreateUser

public struct CreateUser: PBCreateUser, Encodable, Sendable {

  // MARK: Lifecycle

  public init(
    email: String,
    emailVisibility: Bool? = nil,
    name: String,
    password: String,
    passwordConfirm: String,
    verified: Bool? = nil)
  {
    self.email = email
    self.emailVisibility = emailVisibility
    self.name = name
    self.password = password
    self.passwordConfirm = passwordConfirm
    self.verified = verified
  }

  // MARK: Public

  public let email: String
  public let emailVisibility: Bool?
  public let name: String
  public let password: String
  public let passwordConfirm: String
  public let verified: Bool?

  // MARK: Internal

  enum CodingKeys: String, CodingKey {
    case email, emailVisibility, name, password, passwordConfirm, verified
  }
}


// MARK: - Post

public struct Post: PBBaseRecord, Decodable, Encodable, Sendable {

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

// MARK: - CreatePost

// Use this struct when creating new posts (omits auto-generated fields)
public struct CreatePost: Encodable, Sendable {
  public let title: String

  public init(title: String) {
    self.title = title
  }

  enum CodingKeys: String, CodingKey {
    case title
  }
}
