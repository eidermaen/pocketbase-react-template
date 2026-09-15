#!/usr/bin/env bash
# Scaffolds a new PocketBase + React project from this template.
#
#   curl -fsSL https://github.com/<GH_OWNER>/pocketbase-react-template/raw/main/setup.sh | bash
#
# See README.md for details and flags.
set -euo pipefail

# --- config -------------------------------------------------------------
TEMPLATE_OWNER="<GH_OWNER>" # TODO: set once the template repo is pushed to GitHub
TEMPLATE_REPO="pocketbase-react-template"
TEMPLATE_REF="main"
TANSTACK_CLI_VERSION="0.71.0"

# Pinned dependency versions (kept exact, not floating, for reproducibility).
POCKETBASE_JS_VERSION="0.28.1"
ZOD_VERSION="4.6.5"
VITEST_VERSION="5.0.1"
TESTING_LIBRARY_REACT_VERSION="16.3.3"
JEST_DOM_VERSION="7.0.1"
JSDOM_VERSION="30.0.1"
CVA_VERSION="0.7.1"
LUCIDE_REACT_VERSION="1.46.0"
RADIX_UI_VERSION="1.6.7"
CN_VERSION="0.3.0"
TW_ANIMATE_CSS_VERSION="1.4.0"
NEXT_THEMES_VERSION="0.4.6"
SONNER_VERSION="2.0.8"
TANSTACK_QUERY_VERSION="5.102.8"

# --- defaults -------------------------------------------------------------
WITH_ZOD=true
WITH_VITEST=true
WITH_STORYBOOK=false
PROJECT_NAME=""
TARGET_DIR="$(pwd)"
FORCE=false
NONINTERACTIVE=false

print_help() {
	cat <<EOF
Usage: setup.sh [options]

  --with-zod / --no-zod            include Zod (default: on)
  --with-vitest / --no-vitest      include Vitest unit testing (default: on)
  --with-storybook / --no-storybook include Storybook (default: off)
  --name <name>                    project name (default: target dir name)
  --dir <path>                     target directory (default: current dir)
  -f, --force                      allow running in a non-empty directory
  -y, --yes                        non-interactive, accept defaults/flags
  -h, --help                       show this help
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	--with-zod) WITH_ZOD=true ;;
	--no-zod) WITH_ZOD=false ;;
	--with-vitest) WITH_VITEST=true ;;
	--no-vitest) WITH_VITEST=false ;;
	--with-storybook) WITH_STORYBOOK=true ;;
	--no-storybook) WITH_STORYBOOK=false ;;
	--name)
		PROJECT_NAME="$2"
		shift
		;;
	--dir)
		TARGET_DIR="$2"
		shift
		;;
	-f | --force) FORCE=true ;;
	-y | --yes) NONINTERACTIVE=true ;;
	-h | --help)
		print_help
		exit 0
		;;
	*)
		echo "Unknown flag: $1" >&2
		print_help >&2
		exit 1
		;;
	esac
	shift
done

# --- interactivity: stdin is the curl pipe, so prompt via /dev/tty --------
INTERACTIVE=false
if [[ "$NONINTERACTIVE" != true ]] && [[ -t 1 ]] && [[ -r /dev/tty ]]; then
	INTERACTIVE=true
fi

ask_yn() {
	local prompt="$1" default="$2" reply
	if [[ "$INTERACTIVE" != true ]]; then
		echo "$default"
		return
	fi
	local hint="y/N"
	[[ "$default" == "true" ]] && hint="Y/n"
	read -r -p "$prompt [$hint] " reply </dev/tty || true
	if [[ -z "$reply" ]]; then
		echo "$default"
	elif [[ "$reply" =~ ^[Yy] ]]; then
		echo "true"
	else
		echo "false"
	fi
}

if [[ "$INTERACTIVE" == true && -z "$PROJECT_NAME" ]]; then
	read -r -p "Project name [$(basename "$TARGET_DIR")]: " PROJECT_NAME </dev/tty || true
fi
PROJECT_NAME="${PROJECT_NAME:-$(basename "$TARGET_DIR")}"

if [[ "$INTERACTIVE" == true ]]; then
	WITH_ZOD=$(ask_yn "Include Zod (schema validation)?" "$WITH_ZOD")
	WITH_VITEST=$(ask_yn "Include Vitest (unit testing)?" "$WITH_VITEST")
	WITH_STORYBOOK=$(ask_yn "Include Storybook?" "$WITH_STORYBOOK")
fi

# Sanitize into a valid Go module name / npm package name (lowercase,
# alphanumeric + hyphens).
GO_MODULE_NAME="$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed 's/-\+/-/g; s/^-//; s/-$//')"
if [[ -z "$GO_MODULE_NAME" ]]; then
	echo "error: could not derive a valid project name from '$PROJECT_NAME'" >&2
	exit 1
fi

echo "==> Scaffolding '$PROJECT_NAME' in $TARGET_DIR"
echo "    zod=$WITH_ZOD vitest=$WITH_VITEST storybook=$WITH_STORYBOOK"

# --- safety: refuse a non-empty target dir unless forced -------------------
mkdir -p "$TARGET_DIR"
if [[ -n "$(ls -A "$TARGET_DIR" 2>/dev/null)" && "$FORCE" != true ]]; then
	echo "error: $TARGET_DIR is not empty. Re-run with --force to proceed anyway." >&2
	exit 1
fi

# --- fetch the template into a scratch dir ---------------------------------
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> Downloading template..."
curl -fsSL "https://codeload.github.com/${TEMPLATE_OWNER}/${TEMPLATE_REPO}/tar.gz/refs/heads/${TEMPLATE_REF}" |
	tar -xz -C "$TMP" --strip-components=1

# --- copy backend + root files (everything except scaffold/ and setup.sh) --
(cd "$TMP" && tar -cf - --exclude=scaffold --exclude=setup.sh .) | (cd "$TARGET_DIR" && tar -xf -)

# --- rewrite the Go module placeholder everywhere it's used -----------------
perl -pi -e "s/^module pbapp-template/module ${GO_MODULE_NAME}/" "$TARGET_DIR/go.mod"
find "$TARGET_DIR" -name '*.go' -print0 | xargs -0 perl -pi -e "s/pbapp-template/${GO_MODULE_NAME}/g"

# --- generate the frontend via the pinned TanStack CLI ----------------------
echo "==> Generating frontend (this can take a minute)..."
mkdir -p "$TARGET_DIR/frontend"
npx --yes "@tanstack/cli@${TANSTACK_CLI_VERSION}" create "$GO_MODULE_NAME" \
	--framework react --router-only \
	--toolchain eslint --package-manager npm \
	--no-git --no-intent --yes \
	--target-dir "$TARGET_DIR/frontend"

# --- layer the PocketBase/auth overlay on top -------------------------------
cp -R "$TMP/scaffold/frontend-overlay/." "$TARGET_DIR/frontend/"

if [[ "$WITH_ZOD" == true ]]; then
	mv "$TARGET_DIR/frontend/src/routes/login.tsx.with-zod" "$TARGET_DIR/frontend/src/routes/login.tsx"
	rm -f "$TARGET_DIR/frontend/src/routes/login.tsx.no-zod"
else
	mv "$TARGET_DIR/frontend/src/routes/login.tsx.no-zod" "$TARGET_DIR/frontend/src/routes/login.tsx"
	rm -f "$TARGET_DIR/frontend/src/routes/login.tsx.with-zod"
fi

cd "$TARGET_DIR/frontend"

echo "==> Installing PocketBase SDK + TanStack Query..."
npm install \
	"pocketbase@${POCKETBASE_JS_VERSION}" \
	"@tanstack/react-query@${TANSTACK_QUERY_VERSION}"

if [[ "$WITH_ZOD" == true ]]; then
	npm install "zod@${ZOD_VERSION}"
fi

# --- shadcn/ui: components.json is hand-authored in the overlay; fetch
# component source non-interactively. Their own dependency install step is
# unreliable when adding multiple components at once, so pin + install the
# known transitive deps explicitly instead of trusting it.
echo "==> Adding shadcn/ui components..."
npx --yes shadcn@latest add button input label card sonner -y --cwd .
npm install \
	"class-variance-authority@${CVA_VERSION}" \
	"lucide-react@${LUCIDE_REACT_VERSION}" \
	"radix-ui@${RADIX_UI_VERSION}" \
	"cn@${CN_VERSION}" \
	"tw-animate-css@${TW_ANIMATE_CSS_VERSION}" \
	"next-themes@${NEXT_THEMES_VERSION}" \
	"sonner@${SONNER_VERSION}"

if [[ "$WITH_VITEST" == true ]]; then
	echo "==> Setting up Vitest..."
	cp -R "$TMP/scaffold/optional/vitest/." "$TARGET_DIR/frontend/"
	npm install -D \
		"vitest@${VITEST_VERSION}" \
		"@testing-library/react@${TESTING_LIBRARY_REACT_VERSION}" \
		"@testing-library/jest-dom@${JEST_DOM_VERSION}" \
		"jsdom@${JSDOM_VERSION}"
	npm pkg set scripts.test="vitest run --config vitest.config.ts"
fi

if [[ "$WITH_STORYBOOK" == true ]]; then
	echo "==> Setting up Storybook..."
	npx --yes storybook@latest init --yes || true
	rm -rf "$TARGET_DIR/frontend/src/stories"
	# Storybook's addon-vitest currently requires Vitest ^4, which conflicts
	# with the pinned Vitest 5.x above. Drop its browser-testing integration
	# (heavy Playwright dependency, and redundant with the --with-vitest
	# option) and restore our own config files, since its installer may have
	# merged into whichever of vite.config.ts / vitest.config.ts exists.
	npm pkg delete \
		"devDependencies.@storybook/addon-vitest" \
		"devDependencies.@vitest/browser-playwright" \
		"devDependencies.@vitest/coverage-v8" \
		devDependencies.playwright \
		2>/dev/null || true
	perl -0pi -e 's/\s*"\@storybook\/addon-vitest",\n//' "$TARGET_DIR/frontend/.storybook/main.ts" 2>/dev/null || true
	cp "$TMP/scaffold/frontend-overlay/vite.config.ts" "$TARGET_DIR/frontend/vite.config.ts"
	if [[ "$WITH_VITEST" == true ]]; then
		cp "$TMP/scaffold/optional/vitest/vitest.config.ts" "$TARGET_DIR/frontend/vitest.config.ts"
	fi
	npm install
fi

npm pkg set name="$GO_MODULE_NAME"

echo "==> Regenerating route tree..."
npm run generate-routes

# --- fresh git history -------------------------------------------------
cd "$TARGET_DIR"
git init -q -b main
git add -A
git commit -q -m "Initial commit from pocketbase-react-template"

cat <<EOF

✔ Project ready at $TARGET_DIR

Next steps:
  cd $TARGET_DIR
  mise install
  cd frontend && npm install && cd ..
  make dev              # PocketBase on :8090
  cd frontend && npm run dev   # (new terminal) Vite on :3000

Push to GitHub:
  gh repo create <you>/<repo> --private --source=. --push
  # or: git remote add origin <url> && git push -u origin main
EOF
