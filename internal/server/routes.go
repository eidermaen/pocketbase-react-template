package server

import (
	"pbapp-template/internal/handlers"
	"pbapp-template/internal/hooks"

	"github.com/pocketbase/pocketbase/core"
)

// RegisterRoutes wires up all API routes and PocketBase hooks. Add new route
// groups here as the project grows. PocketBase already exposes GET /api/health
// itself, used by the Docker healthcheck.
func RegisterRoutes(app core.App, isGoRun bool) {
	app.OnServe().BindFunc(func(se *core.ServeEvent) error {
		handlers.RegisterFrontendRoutes(se, isGoRun)

		return se.Next()
	})

	hooks.Register(app)
}
