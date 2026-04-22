# Test-Server Migrations for CI Reproducibility — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the deleted binary test fixtures with hand-authored PocketBase Go migrations so CI boots a deterministic, schemaed, seeded test server every run.

**Architecture:** Register PocketBase's `migratecmd` plugin in `test-server/main.go` and anonymous-import a new `migrations` package. Two timestamped Go migration files declare the `users` config + `posts` collection, then seed the superuser and test user. CI wipes `test_pb_data/` before each boot via a new `start_test_server_fresh` Make target; local default stays stateful.

**Tech Stack:** Go 1.24, PocketBase v0.32.0 (`core`, `migrations`, `plugins/migratecmd`), Make, Swift Testing (integration tests already exist).

**Spec:** `docs/superpowers/specs/2026-04-22-ci-test-server-migrations-design.md`

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `test-server/main.go` | modify | Register `migratecmd` plugin; anon-import migrations package |
| `test-server/migrations/migrations.go` | create | Package doc comment; gives the package a permanent file so the anon import never resolves to an empty dir |
| `test-server/migrations/1777190401_init_schema.go` | create | `up`: configure `users` collection + create `posts` collection. `down`: best-effort teardown |
| `test-server/migrations/1777190402_seed_users.go` | create | `up`: insert superuser + test user. `down`: delete those records by email |
| `test-server/go.mod` / `go.sum` | modify | Updated by `go mod tidy` for the new `migratecmd` import |
| `Makefile` | modify | Add `start_test_server_fresh`; route `test_ci` through it |
| `CLAUDE.md` | modify | Document the fresh-start target and migration-authoring conventions |

The `1777190401` / `1777190402` values are unix-second timestamps (PocketBase reads filenames as `<unix-ts>_<description>.go` and sorts lexicographically). Pinning concrete values here avoids drift between the schema and seed files; the seed must come second.

---

## Task 1: Migrations package skeleton + main.go integration

Wire up `migratecmd` and create an empty migrations package. After this task the server will boot, find no migrations to apply, and behave exactly as before. This isolates "did the plugin wire-up work" from "did the migrations work."

**Files:**
- Modify: `test-server/main.go`
- Create: `test-server/migrations/migrations.go`
- Modify: `test-server/go.mod`, `test-server/go.sum` (via `go mod tidy`)

- [ ] **Step 1: Create the migrations package doc file**

Create `test-server/migrations/migrations.go`:

```go
// Package migrations holds hand-authored PocketBase migrations for the
// test server. Each migration lives in its own <unix-ts>_<description>.go
// file and registers itself via `migrations.Register` from a package
// init() function. The migratecmd plugin (registered in main.go) walks
// these in timestamp order during OnServe and applies any that haven't
// been recorded in the _migrations table.
//
// Never edit a migration after it has been applied to any environment.
// Write a new timestamped file instead.
package migrations
```

- [ ] **Step 2: Modify `test-server/main.go` to register migratecmd**

Replace the entire file with:

```go
// test server for pocketbase-swift-sdk
//
// admin email: admin@drewalth.com
// admin password: supersecret
//
// user email: user@drewalth.com
// user password: supersecret
//
// run with:
// go run . serve --dir="./test_pb_data"
//
// then open http://localhost:8090/ in your browser
package main

import (
	"log"
	"os"

	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
	"github.com/pocketbase/pocketbase/plugins/migratecmd"

	// Register migrations via package init() side effects.
	_ "testserver/migrations"
)

func main() {
	app := pocketbase.New()

	migratecmd.MustRegister(app, app.RootCmd, migratecmd.Config{
		// Hand-author all migrations. Disable auto-snapshotting so that
		// poking the admin UI locally never silently writes a JSON
		// migration into ./migrations.
		Automigrate: false,
	})

	app.OnServe().BindFunc(func(se *core.ServeEvent) error {
		// serves static files from the provided public dir (if exists)
		se.Router.GET("/{path...}", apis.Static(os.DirFS("./pb_public"), false))

		return se.Next()
	})

	if err := app.Start(); err != nil {
		log.Fatal(err)
	}
}
```

- [ ] **Step 3: Tidy go.mod**

Run:

```bash
cd test-server && go mod tidy
```

Expected: no errors. `migratecmd` is a sub-package of `github.com/pocketbase/pocketbase` (already in `go.mod`), so this should be a no-op or only adjust `go.sum`. If it tries to add a new top-level module, stop and investigate.

- [ ] **Step 4: Verify the test server still builds and boots**

Run:

```bash
cd test-server && go build ./...
```

Expected: exit 0, no output.

Then boot it against a throwaway dir to confirm no runtime panics:

```bash
cd test-server && rm -rf /tmp/pb_skeleton_check
go run . serve --dir=/tmp/pb_skeleton_check --http=127.0.0.1:8091 > /tmp/pb_skeleton.log 2>&1 &
SERVER_PID=$!
sleep 5
kill $SERVER_PID 2>/dev/null
wait $SERVER_PID 2>/dev/null
cat /tmp/pb_skeleton.log
rm -rf /tmp/pb_skeleton_check
```

Expected: log contains a "Server started" line on `127.0.0.1:8091`. No panics, no stack traces.

- [ ] **Step 5: Commit**

```bash
git add test-server/main.go test-server/migrations/migrations.go test-server/go.mod test-server/go.sum
git commit -m "$(cat <<'EOF'
feat(test-server): register migratecmd plugin

Wire up PocketBase's migratecmd with Automigrate disabled and create
an empty migrations package. No schema changes yet — sets up the
scaffolding for the schema + seed migrations to follow.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: `init_schema` migration — users config + posts collection

Add the migration that configures the built-in `users` collection (add `name` field, ensure public sign-up) and creates the `posts` collection used by the expand and realtime tests.

**Files:**
- Create: `test-server/migrations/1777190401_init_schema.go`

- [ ] **Step 1: Write the migration file**

Create `test-server/migrations/1777190401_init_schema.go`:

```go
package migrations

import (
	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
)

func init() {
	m.Register(func(app core.App) error {
		publicRule := ""

		// 1) Configure the built-in `users` auth collection:
		//    - add an optional `name` text field (idempotent)
		//    - open sign-up by setting CreateRule to "" (public)
		users, err := app.FindCollectionByNameOrId("users")
		if err != nil {
			return err
		}

		if users.Fields.GetByName("name") == nil {
			users.Fields.Add(&core.TextField{
				Name:     "name",
				Required: false,
			})
		}

		users.CreateRule = &publicRule

		if err := app.Save(users); err != nil {
			return err
		}

		// 2) Create the `posts` collection.
		//    title (required text), author (required relation -> users, cascade delete).
		//    All CRUD rules are public; tighten when tests carry auth tokens.
		posts := core.NewBaseCollection("posts")
		posts.Fields.Add(
			&core.TextField{
				Name:     "title",
				Required: true,
			},
			&core.RelationField{
				Name:          "author",
				Required:      true,
				CollectionId:  users.Id,
				CascadeDelete: true,
				MaxSelect:     1,
			},
			// PocketBase auto-adds `id`, `created`, `updated` to base collections.
		)

		// TODO: tighten these once integration tests carry auth tokens.
		posts.ListRule = &publicRule
		posts.ViewRule = &publicRule
		posts.CreateRule = &publicRule
		posts.UpdateRule = &publicRule
		posts.DeleteRule = &publicRule

		return app.Save(posts)
	}, func(app core.App) error {
		// down: best-effort cleanup. Canonical recovery path is
		// `make start_test_server_fresh`, not `migrate down`.

		// Delete posts collection if present.
		if posts, err := app.FindCollectionByNameOrId("posts"); err == nil {
			if err := app.Delete(posts); err != nil {
				return err
			}
		}

		// Remove the `name` field from users if present. Leave CreateRule
		// alone — we did not snapshot the prior value, and the PocketBase
		// default for the built-in users collection is also "" so this is
		// unlikely to matter in practice.
		users, err := app.FindCollectionByNameOrId("users")
		if err != nil {
			return err
		}
		if users.Fields.GetByName("name") != nil {
			users.Fields.RemoveByName("name")
			if err := app.Save(users); err != nil {
				return err
			}
		}

		return nil
	})
}
```

Collection rule fields (`CreateRule`, `ListRule`, etc.) are `*string` in PocketBase v0.32. If `go build` reports a type mismatch on the rule assignments, the API likely changed — swap `&publicRule` for `types.Pointer("")` (importing `github.com/pocketbase/pocketbase/tools/types`) and try again.

- [ ] **Step 2: Verify it compiles**

Run:

```bash
cd test-server && go build ./...
```

Expected: exit 0.

- [ ] **Step 3: Boot a fresh server and confirm the migration applies**

Run:

```bash
cd test-server && rm -rf /tmp/pb_init_check
go run . serve --dir=/tmp/pb_init_check --http=127.0.0.1:8091 > /tmp/pb_init.log 2>&1 &
SERVER_PID=$!
sleep 6
kill $SERVER_PID 2>/dev/null
wait $SERVER_PID 2>/dev/null
grep -E "init_schema|migration|Applied" /tmp/pb_init.log || cat /tmp/pb_init.log
```

Expected: log mentions `1777190401_init_schema` being applied (exact wording varies by PocketBase version — the load-bearing check is "no error stack traces"). If the log shows an error referencing the migration, fix the migration and re-run.

- [ ] **Step 4: Inspect the resulting schema directly in SQLite**

Run:

```bash
sqlite3 /tmp/pb_init_check/data.db "SELECT name FROM _collections ORDER BY name;"
```

Expected: output includes `posts`, `users`, `_superusers` (and PocketBase's other built-ins like `_authOrigins`, `_externalAuths`, `_mfas`, `_otps`). If `posts` is missing, the migration didn't run — recheck the log from step 3.

Clean up:

```bash
rm -rf /tmp/pb_init_check /tmp/pb_init.log
```

- [ ] **Step 5: Commit**

```bash
git add test-server/migrations/1777190401_init_schema.go
git commit -m "$(cat <<'EOF'
feat(test-server): add init_schema migration

Configure built-in users collection with a name field and public
sign-up; create the posts collection (title + required author
relation) used by expand and realtime tests. CRUD rules on posts
are public for now and marked with a TODO to tighten once tests
authenticate.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: `seed_users` migration — superuser + test user

Insert the two records that CLAUDE.md and the auth tests rely on.

**Files:**
- Create: `test-server/migrations/1777190402_seed_users.go`

- [ ] **Step 1: Write the seed migration**

Create `test-server/migrations/1777190402_seed_users.go`:

```go
package migrations

import (
	"github.com/pocketbase/dbx"
	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
)

func init() {
	m.Register(func(app core.App) error {
		// 1) Seed the superuser.
		superusers, err := app.FindCollectionByNameOrId(core.CollectionNameSuperusers)
		if err != nil {
			return err
		}
		superuser := core.NewRecord(superusers)
		superuser.Set("email", "admin@drewalth.com")
		superuser.Set("password", "supersecret")
		if err := app.Save(superuser); err != nil {
			return err
		}

		// 2) Seed the test user.
		users, err := app.FindCollectionByNameOrId("users")
		if err != nil {
			return err
		}
		user := core.NewRecord(users)
		user.Set("email", "user@drewalth.com")
		user.Set("password", "supersecret")
		user.Set("name", "Test User")
		user.Set("verified", true)
		return app.Save(user)
	}, func(app core.App) error {
		// down: delete by email; no-op if not found.
		deleteByEmail := func(collectionName, email string) error {
			record, err := app.FindFirstRecordByFilter(
				collectionName,
				"email = {:email}",
				dbx.Params{"email": email},
			)
			if err != nil {
				// Treat "not found" as success.
				return nil
			}
			return app.Delete(record)
		}

		if err := deleteByEmail(core.CollectionNameSuperusers, "admin@drewalth.com"); err != nil {
			return err
		}
		return deleteByEmail("users", "user@drewalth.com")
	})
}
```

- [ ] **Step 2: Verify it compiles**

Run:

```bash
cd test-server && go build ./...
```

Expected: exit 0.

- [ ] **Step 3: Boot a fresh server and smoke-test the seeded user via the API**

Run:

```bash
cd test-server && rm -rf /tmp/pb_seed_check
go run . serve --dir=/tmp/pb_seed_check --http=127.0.0.1:8091 > /tmp/pb_seed.log 2>&1 &
SERVER_PID=$!
sleep 6

curl -s -X POST http://127.0.0.1:8091/api/collections/users/auth-with-password \
  -H "Content-Type: application/json" \
  -d '{"identity":"user@drewalth.com","password":"supersecret"}'
echo

kill $SERVER_PID 2>/dev/null
wait $SERVER_PID 2>/dev/null
grep -E "init_schema|seed_users|migration|Applied" /tmp/pb_seed.log
rm -rf /tmp/pb_seed_check /tmp/pb_seed.log
```

Expected: the curl response is JSON containing `"token":"..."` and a `"record"` with `"email":"user@drewalth.com"`. The grep at the end should show both migration filenames appearing in the log (in order: `1777190401_init_schema` then `1777190402_seed_users`).

If you get HTTP 400 with `"Failed to authenticate"`, the seed didn't apply — check the log output for migration errors. If you get a `Missing or invalid collection context` style error, the `users` collection wasn't configured by Task 2's migration — investigate that first.

- [ ] **Step 5: Commit**

```bash
git add test-server/migrations/1777190402_seed_users.go
git commit -m "$(cat <<'EOF'
feat(test-server): seed superuser and test user

Insert admin@drewalth.com / supersecret as superuser and
user@drewalth.com / supersecret (name=Test User, verified=true)
as a regular user. Matches the credentials documented in CLAUDE.md.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Makefile — fresh-start target + CI rewire

Add `start_test_server_fresh` (wipes `test_pb_data/` then boots) and route `test_ci` through it. Keeps the local default (`start_test_server`) stateful.

**Files:**
- Modify: `Makefile`

- [ ] **Step 1: Edit the Makefile**

Modify the existing `test_ci` target and add `start_test_server_fresh`. The full target section should read:

```make
preflight:
	$(MAKE) lint
	xcrun swift package clean
	xcrun swift build
	$(MAKE) test_ci
	@echo "All checks passed"

test_ci:
	$(MAKE) start_test_server_fresh & sleep 10 && xcrun swift package clean && xcrun swift test

start_test_server:
	cd ./test-server && go run . serve --dir="./test_pb_data"

start_test_server_fresh:
	rm -rf ./test-server/test_pb_data
	$(MAKE) start_test_server
```

Update the `.PHONY` line to include the new target. The full `.PHONY` line should read:

```make
.PHONY: pretty lint preflight start_test_server start_test_server_fresh test_ci setup install_swiftlint install_swiftformat install_go_dependencies install_homebrew install_go
```

(Note: `test_ci` was missing from `.PHONY` before — fixing that here too.)

- [ ] **Step 2: Verify the Makefile parses**

Run:

```bash
make -n start_test_server_fresh
```

Expected: prints `rm -rf ./test-server/test_pb_data` and the recursive make invocation. No `*** missing separator` errors (those mean tabs got converted to spaces — fix by re-indenting recipe lines with hard tabs).

Also dry-run `test_ci`:

```bash
make -n test_ci
```

Expected: shows the `start_test_server_fresh & sleep 10 && ...` pipeline.

- [ ] **Step 3: Commit**

```bash
git add Makefile
git commit -m "$(cat <<'EOF'
fix(ci): wipe test_pb_data before each CI run

Add start_test_server_fresh which removes ./test-server/test_pb_data
before booting, and route test_ci through it. Local default
(start_test_server) stays stateful so the admin UI and
already-applied migrations persist between dev runs.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: CLAUDE.md — document the new flow

Update the Commands section so future contributors (and Claude) discover the fresh-start target and the migration-authoring rules.

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Edit CLAUDE.md**

In the `## Commands` section, replace the line:

```
- `make start_test_server` — runs the local PocketBase test instance from `./test-server` on `http://127.0.0.1:8090` with fixture data in `./test-server/test_pb_data`. Seeded accounts: admin `admin@drewalth.com`/`supersecret`, user `user@drewalth.com`/`supersecret`.
```

with:

```
- `make start_test_server` — runs the local PocketBase test instance from `./test-server` on `http://127.0.0.1:8090`. Stateful: keeps any existing `./test-server/test_pb_data` and applies any new migrations on next boot.
- `make start_test_server_fresh` — `rm -rf ./test-server/test_pb_data` then `make start_test_server`. Use after pulling new migrations or to reset accumulated state. Seeded accounts after a fresh boot: admin `admin@drewalth.com`/`supersecret`, user `user@drewalth.com`/`supersecret`.
```

Then add a new section directly after the `## Commands` section (before `## Architecture`):

```markdown
## Test-server schema and migrations

The test server's schema and seed data live in `test-server/migrations/` as hand-authored Go files (`<unix-ts>_<description>.go`). The `migratecmd` plugin (registered in `test-server/main.go` with `Automigrate: false`) walks them in timestamp order during `OnServe` and applies any that haven't been recorded in the `_migrations` table.

To change the schema or seed data, write a **new** timestamped migration file. Never edit a migration that has already been applied — CI starts from an empty data dir on every run, so a forward-only migration history is what determines the schema CI sees. Already-applied migrations are skipped on warm-start; if a local dev environment ends up with stale state, run `make start_test_server_fresh` to reset.
```

- [ ] **Step 2: Sanity-check the edit**

Run:

```bash
grep -n "start_test_server_fresh\|migrations" CLAUDE.md
```

Expected: at least three matches — the new bullet, the new section heading, and one or two references inside the section body.

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "$(cat <<'EOF'
docs: document test-server migrations and fresh-start target

Explain start_test_server_fresh, point at test-server/migrations/
for schema/seed changes, and lock in the never-edit-an-applied-
migration rule.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: End-to-end verification

The real test of the migrations is the existing Swift test suite. Run it cold-start (the CI path) and warm-start (the local path) to make sure both work.

**Files:** none modified.

- [ ] **Step 1: Make sure no leftover test server is running**

Run:

```bash
PIDS=$(lsof -ti tcp:8090); [ -n "$PIDS" ] && kill $PIDS; sleep 1
```

Expected: no output. (If it killed something, that's fine — there was a stray server.)

- [ ] **Step 2: Cold-start run — the CI path**

Run:

```bash
rm -rf test-server/test_pb_data && make test_ci
```

Expected: server log shows both migrations being applied, then `swift test` runs. All previously-passing tests still pass; the auth, expand, and realtime tests that were 404ing on `main` now pass against the seeded server.

If a test fails:
- **`Failed to authenticate` / 400 on sign-in:** the `users` collection's `CreateRule` isn't open or the seed user is missing. Re-check Task 2 step 1 and Task 3 step 1.
- **404 on `posts`:** the `posts` collection wasn't created. Check the migration log line and look at `test-server/test_pb_data/data.db` with `sqlite3` if needed.
- **`name` field unknown:** the field-add in Task 2 step 1 didn't run.

- [ ] **Step 3: Stop the server from step 2**

Run:

```bash
PIDS=$(lsof -ti tcp:8090); [ -n "$PIDS" ] && kill $PIDS; sleep 1
```

- [ ] **Step 4: Warm-start run — the local path**

Without removing `test_pb_data/`:

```bash
make test_ci
```

Expected: server boots, migration log lines either don't appear or say "no pending migrations" (PocketBase logs vary on this; the load-bearing check is the test result, not the log wording). All tests pass again. Total runtime should be roughly the same as the cold-start.

- [ ] **Step 5: Stop the server**

Run:

```bash
PIDS=$(lsof -ti tcp:8090); [ -n "$PIDS" ] && kill $PIDS; sleep 1
```

- [ ] **Step 6: Run preflight to mirror CI exactly**

Run:

```bash
make preflight
```

Expected: lint, build, and `test_ci` all succeed. Final line: `All checks passed`.

- [ ] **Step 7: Update TODOS.md (if it tracks the CI breakage or flakiness)**

Check whether `TODOS.md` still references the CI breakage or the back-to-back test flakiness:

```bash
grep -n -i "ci\|flak\|test_pb_data\|fixture" TODOS.md
```

If it mentions either, mark the relevant items as done (or remove them). Stage and commit any change:

```bash
git add TODOS.md
git commit -m "$(cat <<'EOF'
chore: mark CI fixture / flakiness items resolved

Test-server migrations replace the deleted .db fixtures and
deterministic CI fresh-start removes accumulated state as a
flakiness source.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

If `TODOS.md` doesn't mention these items, skip the commit.

- [ ] **Step 8: Final review**

Run:

```bash
git log --oneline main..HEAD
```

Expected: 4–6 commits — `feat(test-server): register migratecmd plugin`, `feat(test-server): add init_schema migration`, `feat(test-server): seed superuser and test user`, `fix(ci): wipe test_pb_data before each CI run`, `docs: document test-server migrations and fresh-start target`, optionally `chore: mark CI fixture / flakiness items resolved`. Plus the spec commit (`docs: spec for test-server migrations + CI fix`) which was already on the branch.

The branch is now ready for PR.

---

## Out of scope (tracked in spec)

- Tighten `expand_*` tests to assert expansion structure.
- Add seeded sample posts.
- Add API auth to CRUD tests; tighten `posts` collection rules.
- PocketBase v0.37.3 upgrade.
