import { defineConfig } from "vitest/config";
import viteReact from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

// Separate from vite.config.ts on purpose: keeps plain unit tests independent
// of any Storybook browser-test wiring that may also live in vite.config.ts.
// Run with `npm run test`.
export default defineConfig({
	resolve: {
		tsconfigPaths: true
	},
	plugins: [tailwindcss(), viteReact()],
	test: {
		environment: "jsdom",
		globals: true,
		setupFiles: ["./src/test-setup.ts"]
	}
});
