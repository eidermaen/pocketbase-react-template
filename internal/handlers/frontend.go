package handlers

import (
	"io/fs"
	"os"
	"strings"

	"pbapp-template/frontend"

	"github.com/pocketbase/pocketbase/core"
)

// RegisterFrontendRoutes serves the built React SPA, falling back to
// index.html for client-side routes. In dev (isGoRun) it reads frontend/dist
// from disk so rebuilds are picked up without recompiling the Go binary; in
// production it serves the dist directory embedded into the binary.
func RegisterFrontendRoutes(se *core.ServeEvent, isGoRun bool) {
	var fileSystem fs.FS
	if isGoRun {
		fileSystem = os.DirFS("frontend/dist")
	} else {
		fileSystem = frontend.DistDirFS
	}

	se.Router.GET("/{path...}", func(e *core.RequestEvent) error {
		path := e.Request.URL.Path

		if strings.HasPrefix(path, "/api/") || strings.HasPrefix(path, "/_/") {
			return e.Next()
		}

		if file, err := fileSystem.Open(strings.TrimPrefix(path, "/")); err == nil {
			file.Close()
			return e.FileFS(fileSystem, strings.TrimPrefix(path, "/"))
		}

		return e.FileFS(fileSystem, "index.html")
	})
}
