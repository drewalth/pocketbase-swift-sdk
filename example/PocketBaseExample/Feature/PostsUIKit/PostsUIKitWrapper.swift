//
//  PostsUIKitWrapper.swift
//  PocketBaseExample
//

import PocketBase
import SwiftUI

// MARK: - PostsUIKitWrapper

struct PostsUIKitWrapper: UIViewControllerRepresentable {
    let pocketBase: PocketBase

    func makeUIViewController(context: Context) -> PostsUIKitViewController {
        let vc = PostsUIKitViewController(pocketBase: pocketBase)
        vc.onSelectPost = { post in
            let detailVC = UIHostingController(
                rootView: NavigationStack { PostDetailView(post: post) }
            )
            vc.present(detailVC, animated: true)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: PostsUIKitViewController, context: Context) {}
}
