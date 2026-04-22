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
