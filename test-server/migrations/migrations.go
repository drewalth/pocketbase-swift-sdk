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
