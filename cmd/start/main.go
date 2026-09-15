package main

import (
	"log"
	"os"
	"strings"

	"pbapp-template/internal/server"
	_ "pbapp-template/migrations"

	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/plugins/migratecmd"
)

func main() {
	app := pocketbase.New()

	// Automigrate only when running via `go run` (dev). Built binaries expect
	// migrations to already be applied via `migrate up`.
	cacheDir, _ := os.UserCacheDir()
	isGoRun := strings.HasPrefix(os.Args[0], os.TempDir()) || (cacheDir != "" && strings.HasPrefix(os.Args[0], cacheDir))

	migratecmd.MustRegister(app, app.RootCmd, migratecmd.Config{
		Automigrate: isGoRun,
	})

	server.RegisterRoutes(app, isGoRun)

	if err := app.Start(); err != nil {
		log.Fatal(err)
	}
}
