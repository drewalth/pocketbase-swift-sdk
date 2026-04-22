# Test-Server Migrations for CI Reproducibility

**Status:** Approved
**Date:** 2026-04-22
**Author:** drewalth (with Claude)

## Problem

CI on `main` has been red since commit `d8355a4` (2025-11-06, "chore: misc fixes + clean up"), which deleted `test-server/test_pb_data/*.db` from the repo and added them to `.gitignore`. Without those fixture databases, the test PocketBase instance boots empty: no `users` collection settings (sign-up disabled by default), no custom `posts` collection, no superuser. Every integration test that touches a collection 404s.

The original intent (per `TODOS.md`: "Stop tracking test-server database files in git but do not remove them from the project") was to stop tracking *changes* to those files, not to remove them entirely. The fix overshot.

## Goals

1. Get CI green on `main` again.
2. Keep binary database fixtures out of git permanently.
3. Make the test server's schema and seed data reviewable as code.
4. Make CI runs fully deterministic (same starting state every time), addressing the back-to-back test flakiness flagged in `TODOS.md`.

## Non-goals

- Tightening the existing tests' assertions (e.g. making `expand_basic_functionality` actually verify expansion). Tracked separately.
- Adding API auth to the existing CRUD tests. The current tests hit public collection rules; changing that is a test-rewrite, not a CI fix.
- Reconstructing the full original schema (categories, tags, etc.). We only need what current tests require.
- Migrating to a different test framework or test-host strategy.

## Approach

PocketBase ships a Go migration system (`migratecmd` plugin + `migrations.AppMigrations`) that auto-applies pending migrations during `OnServe`. We use it. Migrations live alongside the test server in `test-server/migrations/`, are written by hand in Go, and are exercised end-to-end by the existing test suite on every CI run.

CI starts from a clean `test_pb_data/` every run; local dev defaults to stateful (preserves admin UI / inspector state) with an opt-in fresh-start target.

## Architecture

```
test-server/
├── go.mod
├── go.sum
├── main.go                              # registers migratecmd, anon-imports migrations pkg
├── migrations/
│   ├── <ts1>_init_schema.go             # users config + posts collection
│   └── <ts2>_seed_users.go              # superuser + test user records
└── test_pb_data/                        # gitignored; regenerated from migrations
```

`<ts1>` and `<ts2>` are unix-millisecond timestamps assigned at implementation time (PocketBase's required filename convention is `<ts>_<description>.go`). `<ts2>` must be greater than `<ts1>` so the seed migration runs after the schema migration.

### Schema (decided)

**`users`** (built-in PocketBase auth collection, modified):
- Add `name` (TextField, optional).
- `CreateRule = ""` so sign-up is publicly allowed (the auth flow test calls `pb.signUp` without prior auth).
- Other built-in defaults (email + password auth) preserved.

**`posts`** (new base collection):
- `title` — TextField, required.
- `author` — RelationField → `users`, single, required, cascade delete.
- All CRUD rules public (`""`). Existing tests do not authenticate before reading/writing posts. Marked with a `// TODO` comment to tighten when tests carry auth tokens.

### Seed (decided)

- Superuser: `admin@drewalth.com` / `supersecret`.
- Regular user: `user@drewalth.com` / `supersecret`, `name = "Test User"`, `verified = true`.

No sample posts are seeded. Tests create their own posts.

### Data lifecycle (decided)

- **CI:** always fresh. `make test_ci` calls `make start_test_server_fresh`, which `rm -rf ./test_pb_data` before booting.
- **Local default:** stateful. `make start_test_server` keeps existing `test_pb_data/`. New migrations apply on next boot; already-applied migrations are skipped.
- **Local reset:** `make start_test_server_fresh` available on demand.

This addresses the back-to-back test flakiness flagged in `TODOS.md` (P3) by removing accumulated state as a variable.

## Components

### `test-server/main.go` (modified)

Add anonymous import of the migrations package and register `migratecmd`:

```go
import (
    // ... existing ...
    "github.com/pocketbase/pocketbase/plugins/migratecmd"
    _ "testserver/migrations"
)

func main() {
    app := pocketbase.New()

    migratecmd.MustRegister(app, app.RootCmd, migratecmd.Config{
        Automigrate: false, // hand-author migrations only; no admin UI roundtrip
    })

    // ... existing OnServe + Start ...
}
```

**Why `Automigrate: false`:** prevents PocketBase from silently writing JSON snapshot migrations to `migrations/` whenever someone pokes the admin UI locally. All schema changes go through reviewed Go migrations.

### `test-server/migrations/1700000001_init_schema.go`

Single `init()` calling `m.Register(up, down)`.

**`up`:**
1. `app.FindCollectionByNameOrId("users")` → add `name` TextField (skip if already present, to stay idempotent in case the migration is re-applied after a partial failure) → set `CreateRule = ""` → `app.Save(collection)`.
2. `core.NewBaseCollection("posts")` → add `title` (TextField, required) and `author` (RelationField, single, required, cascade delete, target = `users` collection ID resolved at migration time) → set list/view/create/update/delete rules to `""` → `app.Save(collection)`.

**`down`:** best-effort cleanup; the canonical recovery path is `make start_test_server_fresh`, not running migrations down.
1. Find `posts` collection → `app.Delete(collection)` (no-op if missing).
2. Find `users` collection → remove `name` field if present → leave `CreateRule` as-is (we don't snapshot the prior value; in practice the PocketBase default is also `""` for the built-in `users` collection, so this is unlikely to matter) → `app.Save(collection)`.

### `test-server/migrations/1700000002_seed_users.go`

Single `init()` calling `m.Register(up, down)`.

**`up`:**
1. Find `_superusers` collection (`core.CollectionNameSuperusers`) → `core.NewRecord(collection)` → `Set("email", "admin@drewalth.com")`, `Set("password", "supersecret")` → `app.Save(record)`.
2. Find `users` collection → `core.NewRecord(collection)` → `Set("email", "user@drewalth.com")`, `Set("password", "supersecret")`, `Set("name", "Test User")`, `Set("verified", true)` → `app.Save(record)`.

**`down`:**
1. Find each record by email via `app.FindFirstRecordByFilter(collectionName, "email = {:email}", dbx.Params{"email": "..."})` → `app.Delete(record)` if found (no-op if already deleted).

### `Makefile` (modified)

```make
start_test_server_fresh:
    rm -rf ./test-server/test_pb_data
    $(MAKE) start_test_server

test_ci:
    $(MAKE) start_test_server_fresh & sleep 10 && xcrun swift package clean && xcrun swift test
```

`start_test_server` itself is unchanged — local default stays stateful.

Add `start_test_server_fresh` to `.PHONY`.

### `CLAUDE.md` (modified)

Update the **Commands** section:
- Mention `make start_test_server_fresh` and what it does.
- Add: schema and seed data live in `test-server/migrations/`. To change the schema, write a new timestamped migration file (`<unix-ms>_<description>.go`); never edit applied migrations. CI starts from an empty data dir every run, so any change must be expressible as a forward migration from an empty DB.

### `.github/workflows/main.yaml` & `pull-request.yaml`

No structural change. They already invoke `make preflight` → `make test_ci`, which after the Makefile change uses the fresh-start path. CI gets fixed transitively.

## Data flow

**Every CI boot:**
1. `make test_ci` → `start_test_server_fresh` → `rm -rf ./test_pb_data` → `go run . serve --dir=./test_pb_data &`
2. PocketBase boots, sees empty DB, `migratecmd` walks `migrations.AppMigrations` in timestamp order, applies each `up`. Result: configured `users` + `posts` collections, superuser, test user.
3. `sleep 10` (existing) → `swift test` runs against the deterministic, schemaed, seeded server.

**Local first run after pulling these changes:**
- If `test_pb_data/` doesn't exist (e.g. fresh clone): same flow as CI. Server creates an empty DB, migrations populate it.
- If `test_pb_data/` already exists from a prior `make start_test_server` run *before* these changes landed: PocketBase has no record of any migration ever running, so it'll attempt to apply both. The `users` modifications use `FindCollectionByNameOrId` and idempotent field-add checks, so they're safe. The `posts` collection creation will fail with a duplicate-name error if `posts` somehow already exists — in that case, the dev runs `make start_test_server_fresh` once.

## Verification

The existing test suite is the migration test. If `make test_ci` passes locally, the migrations are correct. No separate migration tests:
- The migrations are short, declarative, and have no logic worth unit-testing in isolation.
- They are exercised end-to-end on every CI run.
- A schema mistake will surface as a test failure within seconds.

**Pre-merge sanity check:**
1. `rm -rf test-server/test_pb_data && make test_ci` locally — confirms the cold-start path works.
2. `make test_ci` again without removing the data dir — confirms the warm-start path is a no-op (migrations don't re-run, tests pass).

## Failure modes & mitigations

| Failure | Mitigation |
|---|---|
| Migration `up` fails partway through, leaves data dir half-applied | CI: self-healing — next run wipes the dir. Local: `make start_test_server_fresh`. |
| Someone hand-edits an applied migration | PocketBase tracks applied migrations by filename in `_migrations` table. Editing the file silently changes future cold-starts but not warm-starts. Mitigation: convention documented in `CLAUDE.md` — never edit applied migrations, write a new one. |
| Local dev has stale `test_pb_data/` from before this change | First run after pulling may hit a duplicate-collection error if they happened to manually create `posts`. Recovery: one-time `make start_test_server_fresh`. |
| PocketBase upgrade changes the migration API | Migrations live in this repo and use a stable public API. If a future PocketBase release breaks the API, migrations need updating alongside the version bump (already part of the PocketBase-version-upgrade workflow). |

## Out of scope (follow-ups)

- Tighten `expand_*` tests to assert expansion structure now that there's a real `author` relation.
- Add seeded sample posts to give expand tests data to assert against.
- Add API auth to CRUD tests; tighten `posts` collection rules.
- Address `TODOS.md` P2 (PocketBase v0.37.3 upgrade) — separate work.

## Files touched

- `test-server/main.go` (modified)
- `test-server/migrations/<ts1>_init_schema.go` (new)
- `test-server/migrations/<ts2>_seed_users.go` (new)
- `test-server/go.mod` / `go.sum` (updated by `go mod tidy` for the migratecmd import — likely no-op since `migratecmd` is a sub-package of the existing `pocketbase` module)
- `Makefile` (modified)
- `CLAUDE.md` (modified)
