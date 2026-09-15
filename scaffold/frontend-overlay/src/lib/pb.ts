import PocketBase from "pocketbase";

// Relative URL: in production the Go binary serves both the API and this
// SPA from the same origin. In dev, Vite's proxy (see vite.config.ts)
// forwards /api and /_ to the local PocketBase server.
export const pb = new PocketBase("/");

export function isUserLoggedIn(): boolean {
	return pb.authStore.isValid;
}
