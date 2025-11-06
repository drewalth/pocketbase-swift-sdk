//
//  model.swift
//  PocketBase
//
//  Created by Andrew Althage on 7/13/25.
//

// MARK: - PBBaseRecord

public protocol PBBaseRecord {
    var id: String { get }
    var created: String { get }
    var updated: String { get }
}

// MARK: - PBCreateUser

public protocol PBCreateUser: Encodable, Sendable {
    var email: String { get }
    var emailVisibility: Bool? { get }
    var name: String { get }
    var password: String { get }
    var passwordConfirm: String { get }
    var verified: Bool? { get }
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
        verified: Bool? = nil) {
        self.email = email
        self.emailVisibility = emailVisibility
        self.name = name
        self.password = password
        self.passwordConfirm = passwordConfirm
        self.verified = verified
    }

    // MARK: Public

    public var email: String

    public var emailVisibility: Bool?

    public var name: String

    public var password: String

    public var passwordConfirm: String
    public var verified: Bool?

    // MARK: Internal

    enum CodingKeys: String, CodingKey {
        case email, emailVisibility, name, password, passwordConfirm, verified
    }
}
