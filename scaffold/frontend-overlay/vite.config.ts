import { defineConfig } from "vite";
import { devtools } from "@tanstack/devtools-vite";
import { tanstackRouter } from "@tanstack/router-plugin/vite";
import viteReact from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

// https://vitejs.dev/config/
export default defineConfig({
	resolve: {
		tsconfigPaths: true
	},
	plugins: [
		devtools(),
		tailwindcss(),
		tanstackRouter({
			target: "react",
			autoCodeSplitting: true
		}),
		viteReact()
	],
	server: {
		proxy: {
			// PocketBase dev server. `make dev` runs it on :8090; `npm run dev`
			// runs Vite on :3000 and proxies API/admin-UI requests through.
			"/api": "http://localhost:8090",
			"/_": "http://localhost:8090"
		}
	}
});
