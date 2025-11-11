//
//  UserModel.swift
//  PocketBaseExample
//
//  Created by Andrew Althage on 11/11/25.
//

import Foundation
import PocketBase

// Define your User model
struct User: PBIdentifiableCollection {
    let id: String
    let email: String
    let username: String?
    let name: String?
    let avatar: String?
    let verified: Bool
    let created: String
    let updated: String
    let collectionId: String
    let collectionName: String
    // Add any additional fields your PocketBase user collection has
}
