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
		//    title (required text), author (optional relation -> users, cascade delete).
		//    All CRUD rules are public; tighten when tests carry auth tokens.
		posts := core.NewBaseCollection("posts")
		posts.Fields.Add(
			&core.TextField{
				Name:     "title",
				Required: true,
			},
			&core.RelationField{
				Name:          "author",
				Required:      false,
				CollectionId:  users.Id,
				CascadeDelete: true,
				MaxSelect:     1,
			},
			&core.AutodateField{
				Name:     "created",
				OnCreate: true,
				OnUpdate: false,
			},
			&core.AutodateField{
				Name:     "updated",
				OnCreate: true,
				OnUpdate: true,
			},
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

		if posts, err := app.FindCollectionByNameOrId("posts"); err == nil {
			if err := app.Delete(posts); err != nil {
				return err
			}
		}

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
