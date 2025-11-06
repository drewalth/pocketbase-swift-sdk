//
//  LoadableView.swift
//  PocketBaseExample
//
//  Created by Andrew Althage on 8/2/25.
//

import SwiftUI

// MARK: - Loadable

enum Loadable<T> {
    case initial(T)
    case loading
    case loaded(T)
    case error(Error)
}

// MARK: - LoadableView

struct LoadableView<T, Content: View>: View {

    // MARK: Lifecycle

    init(_ loadable: Loadable<T>, @ViewBuilder content: @escaping (T) -> Content) {
        self.loadable = loadable
        self.content = content
    }

    // MARK: Internal

    let loadable: Loadable<T>
    let content: (T) -> Content

    var body: some View {
        switch loadable {
        case .initial(let value):
            content(value)
        case .loading:
            ProgressView()
        case .loaded(let value):
            content(value)
        case .error(let error):
            Text(error.localizedDescription)
        }
    }
}

#Preview("Loaded") {
    LoadableView(.loaded("Hello")) { value in
        Text("Value: \(value)")
    }
}

#Preview("Loading") {
    LoadableView(.loading) { value in
        Text("Value: \(value)")
    }
}

#Preview("Error") {
    LoadableView(.error(NSError(domain: "Test", code: 1))) { value in
        Text("Value: \(value)")
    }
}
