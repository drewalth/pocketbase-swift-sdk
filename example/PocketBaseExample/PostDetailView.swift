//
//  PostDetailView.swift
//  PocketBaseExample
//
//  Created by Andrew Althage on 8/2/25.
//

import SwiftUI

struct PostDetailView: View {

  private let post: Post

  init(post: Post) {
    self.post = post
  }

  var body: some View {
    VStack {
      VStack(alignment: .leading) {
        Text("ID: \(post.id)")
        Text("Created: \(post.created)")
        Text("Updated: \(post.updated)")
      }
    }.navigationTitle(post.title)
      .navigationBarTitleDisplayMode(.inline)
  }
}
