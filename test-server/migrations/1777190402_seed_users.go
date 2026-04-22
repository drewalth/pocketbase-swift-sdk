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
