# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Swift SDK for [PocketBase](https://pocketbase.io/) (v0.37.3). SPM library exposing a `PocketBase` product, targeting iOS 17+ / macOS 14+ with Swift 6.1 tools. Depends on Alamofire (HTTP) and Recouse/EventSource (SSE for realtime).

## Commands

All workflow is driven by the `Makefile`:

- `make setup` — installs Homebrew, `swiftlint`, `swiftformat`, and Go deps for the test server.
- `make pretty` — runs `swiftformat . --config airbnb.swiftformat` then `swiftlint --fix --format`.
- `make lint` — `swiftlint . --config .swiftlint.yml` (CI-enforced).
- `make start_test_server` — runs the local PocketBase test instance from `./test-server` on `http://127.0.0.1:8090`. Stateful: keeps any existing `./test-server/test_pb_data` and applies any new migrations on next boot.
- `make start_test_server_fresh` — `rm -rf ./test-server/test_pb_data` then `make start_test_server`. Use after pulling new migrations or to reset accumulated state. Seeded accounts after a fresh boot: admin `admin@drewalth.com`/`supersecret`, user `user@drewalth.com`/`supersecret`.
- `make test_ci` — boots the test server in the background, sleeps 10s, then runs `swift test`. All tests are integration tests that hit a live server — **you must have the test server running** (or use this target) or tests will hang/fail on network calls.
- `make preflight` — `lint` + `swift build` + `test_ci`. This is exactly what CI runs (`.github/workflows/*.yaml`) and what you should run before pushing.

Single-test run: `swift test --filter <SuiteName>/<testName>` (e.g. `swift test --filter Authentication/authentication_user_flow`). The test server must be running.

## Test-server schema and migrations

The test server's schema and seed data live in `test-server/migrations/` as hand-authored Go files (`<unix-ts>_<description>.go`). The `migratecmd` plugin (registered in `test-server/main.go` with `Automigrate: false`) walks them in timestamp order during `OnServe` and applies any that haven't been recorded in the `_migrations` table.

To change the schema or seed data, write a **new** timestamped migration file. Never edit a migration that has already been applied — CI starts from an empty data dir on every run, so a forward-only migration history is what determines the schema CI sees. Already-applied migrations are skipped on warm-start; if a local dev environment ends up with stale state, run `make start_test_server_fresh` to reset.

## Architecture

Public entry point is the `PocketBase` class in `Sources/pocketbase-swift-sdk/pb.swift`. It holds a `baseURL`, an internal `HttpClient` (Alamofire `Session` wrapper), and a shared `SecureStorage`.

Two parallel APIs for CRUD exist and must be kept in sync when changing request shapes:

1. **Untyped on `PocketBase`** — `pb.getOne/getList/create/update/delete(collection:model:...)`. Caller passes the model type each call.
2. **Typed `Collection<T>`** — obtained via `pb.collection("name")`. Binds the generic once; thin wrapper around the same endpoints. Also exposes `realtime(...)` for that specific collection.

Both paths build URLs through a private `buildURL` method that appends `expand` query items, then delegate to `HttpClient`. **`buildURL` is duplicated** — `PocketBase` and `Collection` each have their own private copy (in the same file). If you add a new query parameter or fix a URL bug, update **both**.

Exception: `getList` on both classes constructs URLs inline with `URLComponents` rather than calling `buildURL`, because it needs multiple query items (`page`, `perPage`, `expand`, `filter`). Keep this inconsistency in mind when touching URL construction.

### Model protocols (`model.swift`, `pb.swift`)

- `PBCollection` = `Decodable & Encodable & Sendable`. Every record model must conform.
- `PBBaseRecord` — requires `id`, `created`, `updated`.
- `PBIdentifiableCollection` = `PBBaseRecord & PBCollection`. Required for auth APIs (the server returns `record.id` which is stored).
- `PBListResponse<T>`, `AuthModel<T>`, `AuthRefreshResponse<T>` wrap server responses. `PBEmptyEntity` is used as the decoded body for 204-style endpoints (paired with Alamofire's `emptyResponseCodes: [200, 204, 205]` on POST).

### Auth + token storage

`auth.swift` extends `PocketBase` with password / refresh / reset / verify endpoints. On successful `authWithPassword`, the token and user id are persisted via `SecureStorage` (`pocketbase_user_token`, `pocketbase_user_id` Keychain service `io.pocketbase.swift.sdk`). `HttpClient`'s `RequestInterceptor.adapt` reads that token and attaches `Authorization` on every request (user token preferred, admin token as fallback). `signOut()` clears both.

**Admin auth gap**: `SecureStorage` has full admin token support (`storeAdminToken`, `adminToken`, `adminId`) and the interceptor falls back to the admin token, but there is no public `authWithPassword` for the admin collection. Admin token must be set manually via `secureStorage.storeAdminToken(...)` for now.

**Test-environment keychain shim**: `SecureStorage` detects `XCTestConfigurationFilePath` under `#if DEBUG` and transparently swaps Keychain for `UserDefaults` keys prefixed `test_`. This sidesteps missing keychain entitlements in SPM test hosts — do not "simplify" it away. When writing tests that assert auth state, they rely on this.

### Realtime (`realtime.swift`)

`Realtime<T>` wraps `EventSource` for SSE against `/api/realtime`. Flow: subscribe → receive `PB_CONNECT` event → decode `clientId` → POST `{clientId, subscriptions: ["<collection>/<record>"]}` back to `/api/realtime` to register. Subsequent events are decoded as `RealtimeEvent<T>` and delivered to `onEvent`. The post-back is done with raw `URLSession` (not `HttpClient`), so it does **not** include the auth header — keep that in mind if collection API rules require auth.

### Logging (`logging.swift`)

All classes use `os.Logger` with subsystem `com.drewalth.pocketbase-swift-sdk` and per-class categories (`PocketBase`, `HttpClient`, `Collection`, `RealTime`, `SecureStorage`). Filter logs in Console.app by this subsystem.

### `Collection<T>` creates its own `HttpClient`

Each `pb.collection("name")` call creates a new `Collection<T>` with its own `HttpClient` and thus its own Alamofire `Session`. This means each collection has a separate URL session and interceptor chain. Don't worry about reusing a single session — the current design intentionally isolates per-collection.

### Test organization

Tests live in `Tests/pocketbase-swift-sdkTests/` and are organized by feature file:
- `test-models.swift` — shared test record types (`TestUser`, `TestPost`, `Bookmark`, etc.)
- `authentication.swift`, `crud_operations.swift`, `fluent_api.swift`, `expand.swift`, `filters.swift`, `realtime.swift` — integration tests hitting the live test server
- `type_inference.swift` — compile-time type inference checks

All tests are integration tests requiring the test server. Add new test models to `test-models.swift`. The test server must be running (`make start_test_server` or `make start_test_server_fresh`).

### Query builders

- `ExpandQuery` / `ExpandBuilder` (`expand.swift`) — comma-joined `expand` param, supports nested paths like `"author.profile"`.
- `FiltersQuery` / `FilterBuilder` / `FilterOperator` (`filters.swift`) — conditions joined with `&&`. `FilterCondition.conditionString` auto-quotes values unless they look like numbers, booleans, `null`, or dates (regex match on `YYYY-MM-DD` / ISO-8601). If you add a new operator, also add builder convenience methods in both `FiltersQuery` and `FilterBuilder`.

### Example app

`example/PocketBaseExample/` is a SwiftUI iOS app consuming the SDK via a local SPM reference. It's not part of the package build or CI. Open with `cd example && xed .`. Useful as a manual smoke test against the running `test-server`.

## Conventions

- Swift 6 concurrency: all public generics require `Sendable`. Preserve this when adding APIs.
- Formatting is enforced via `airbnb.swiftformat` (note: `MARK: Lifecycle` / `MARK: Public` / `MARK: Internal` / `MARK: Private` section ordering is automated — don't fight the formatter).
- `.swiftlint.yml` allows identifiers ≥ 2 chars and line length up to 220 (error at 250).
- Commit messages follow Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `ci:`, `style:`). PR titles use the same prefixes.
