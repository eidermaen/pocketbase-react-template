# Maintaining this template

This template depends on three moving upstream targets: the pinned
`@tanstack/cli` version, the PocketBase Go module + JS SDK versions, and the
Go/Node toolchain versions. None of these are set to float — bumping any of
them is a deliberate, tested action, not an automatic one.

## Versions to keep in sync

All pinned in `setup.sh` (dependency versions) and `mise.toml` /
`scaffold/frontend-overlay/mise.toml` (toolchains):

- Go toolchain (must satisfy whatever `go.mod`'s `go` directive in this repo
  requires — check after bumping the PocketBase Go module).
- Node toolchain (must satisfy every dependency's `engines` field — `jsdom`
  in particular has bitten this before; run `npm install` and check for
  `EBADENGINE` warnings after bumping).
- `TANSTACK_CLI_VERSION` in `setup.sh`.
- PocketBase Go module version in `go.mod`.
- Every `npm install <pkg>@<version>` in `setup.sh`.

## When bumping a version, re-verify the whole flow by hand

Don't trust that a version bump "should" work — this template has hit real,
non-obvious breakage before (a router-only mode that silently ignores
`--add-ons`, a batched `shadcn add` that skips installing some transitive
dependencies, a Storybook addon requiring an incompatible Vitest major). Re-run
`setup.sh` locally against a scratch directory for all 8 combinations of
`--with-zod` / `--with-vitest` / `--with-storybook`, and for each generated
project:

1. `go build ./...` and `go vet ./...`
2. `cd frontend && npx tsc --noEmit`
3. `npm run build`
4. `npm run lint`
5. If Vitest selected: `npm run test`
6. If Storybook selected: `npm run build-storybook`
7. Build and run the Docker image; hit `/api/health` and confirm the SPA
   loads and falls back correctly for a client-side route (e.g. `/dashboard`).

## CI

`.github/workflows/ci.yml` automates the 8-combination check above (build +
typecheck only, not a full browser test) on every push. Keep it in sync if
the verification steps above change.

## Known upstream quirks (as of the versions pinned today)

- `tanstack create --router-only` ignores `--add-ons` entirely. shadcn,
  TanStack Query, and Storybook are wired up by hand in
  `scaffold/frontend-overlay/` and in `setup.sh` instead of via CLI add-ons.
- `npx shadcn@latest add <multiple components in one call>` does not
  reliably add all transitive npm dependencies (seen: `class-variance-authority`,
  `lucide-react`, `tw-animate-css` silently missing from `package.json`).
  `setup.sh` installs these explicitly with pinned versions rather than
  trusting the CLI's install step.
- `npx shadcn@latest init` is unstable/buggy for Vite projects when combined
  with its newer registry "preset" system (`-p nova` etc.) — it can try to
  write to Next.js-shaped paths (`app/globals.css`) that don't exist in a
  Vite project. This template avoids `init` entirely: `components.json` and
  the shadcn CSS theme variables are hand-authored in the overlay, and only
  `shadcn add <component>` is used at setup time.
- `npx storybook@latest init` may merge its `addon-vitest` browser-testing
  wiring into *either* `vite.config.ts` or an existing `vitest.config.ts`,
  whichever it finds. `setup.sh` doesn't try to patch around this — it strips
  the addon from `package.json`/`.storybook/main.ts` and unconditionally
  restores both config files from the overlay afterward.
- PocketBase's Go framework already exposes `GET /api/health` itself —
  don't add a custom handler for it, `RegisterRoutes` will panic on a route
  conflict at startup.
