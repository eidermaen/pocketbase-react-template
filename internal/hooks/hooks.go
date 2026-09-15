package hooks

import "github.com/pocketbase/pocketbase/core"

// Register wires up PocketBase collection hooks. Add
// app.OnRecordCreate("collection").BindFunc(...) style hooks here as the
// schema grows.
func Register(app core.App) {}
