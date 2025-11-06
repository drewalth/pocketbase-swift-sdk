//
//  logging.swift
//  PocketBase
//
//  Created by Andrew Althage on 11/6/25.
//

import os

extension Logger {
    init(category: String) {
        self.init(subsystem: "com.drewalth.pocketbase-swift-sdk", category: category)
    }
}
