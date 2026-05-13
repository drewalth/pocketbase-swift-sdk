//
//  PostsUIKitViewController.swift
//  PocketBaseExample
//

import PocketBase
import UIKit

// MARK: - PostsUIKitViewController

final class PostsUIKitViewController: UITableViewController {

    // MARK: Lifecycle

    init(pocketBase: PocketBase) {
        self.pocketBase = pocketBase
        super.init(style: .plain)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var onSelectPost: ((Post) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellReuseID)
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        performFetch()
    }

    // MARK: Private

    private let pocketBase: PocketBase
    private var posts: [Post] = []
    private var isLoading = false
    private var errorMessage: String?
    private var fetchTask: Task<Void, Never>?

    private static let cellReuseID = "PostCell"

    private func performFetch() {
        fetchTask?.cancel()
        fetchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            self.isLoading = true
            self.errorMessage = nil
            self.tableView.reloadData()

            do {
                let response = try await self.pocketBase.getList(
                    collection: "posts",
                    model: Post.self,
                    sort: "-created"
                )
                self.posts = response.items
            } catch is CancellationError {
                return
            } catch {
                self.errorMessage = error.localizedDescription
            }

            self.isLoading = false
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        }
    }

    @objc private func handleRefresh() {
        performFetch()
    }
}

// MARK: - UITableViewDataSource

extension PostsUIKitViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading, posts.isEmpty { return 1 }
        if errorMessage != nil, posts.isEmpty { return 1 }
        return posts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellReuseID, for: indexPath)

        if isLoading, posts.isEmpty {
            cell.textLabel?.text = "Loading posts..."
            cell.detailTextLabel?.text = nil
            cell.selectionStyle = .none
            return cell
        }

        if let errorMessage, posts.isEmpty {
            cell.textLabel?.text = errorMessage
            cell.detailTextLabel?.text = "Tap to retry"
            cell.textLabel?.textColor = .systemRed
            cell.selectionStyle = .default
            return cell
        }

        let post = posts[indexPath.row]
        cell.textLabel?.textColor = .label
        cell.textLabel?.text = post.title
        cell.detailTextLabel?.text = post.created
        cell.selectionStyle = .default
        return cell
    }
}

// MARK: - UITableViewDelegate

extension PostsUIKitViewController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if errorMessage != nil, posts.isEmpty {
            performFetch()
            return
        }

        guard !posts.isEmpty, indexPath.row < posts.count else { return }
        onSelectPost?(posts[indexPath.row])
    }
}
