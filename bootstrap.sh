#!/usr/bin/env bash
set -euo pipefail

# product-kit bootstrap script
# Usage: ./bootstrap.sh <project-name>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}==>${NC} $1"; }
ok()    { echo -e "${GREEN}==>${NC} $1"; }
warn()  { echo -e "${YELLOW}==>${NC} $1"; }
fail()  { echo -e "${RED}==>${NC} $1"; exit 1; }

# --- Validate prerequisites ---
check_cmd() {
  command -v "$1" &>/dev/null || fail "$1 is required but not installed."
}

info "Checking prerequisites..."
check_cmd pnpm
check_cmd gh
check_cmd vercel
check_cmd node
check_cmd git
ok "All prerequisites found."

# --- Parse arguments ---
PROJECT_NAME="${1:-}"
if [ -z "$PROJECT_NAME" ]; then
  fail "Usage: ./bootstrap.sh <project-name>"
fi

if [ -d "$PROJECT_NAME" ]; then
  fail "Directory '$PROJECT_NAME' already exists."
fi

# --- Prompts ---
echo ""
read -rp "GitHub org (leave blank for personal account): " GITHUB_ORG

echo ""
info "Available Vercel teams:"
vercel team ls 2>/dev/null || true
echo ""
read -rp "Vercel team/scope slug (leave blank for personal): " VERCEL_TEAM

echo ""
echo "Data layer options:"
echo "  1) Convex (default)"
echo "  2) PlanetScale + Drizzle"
read -rp "Choose [1]: " DATA_LAYER_CHOICE
DATA_LAYER_CHOICE="${DATA_LAYER_CHOICE:-1}"

case "$DATA_LAYER_CHOICE" in
  1) DATA_LAYER="convex" ;;
  2) DATA_LAYER="planetscale" ;;
  *) DATA_LAYER="convex" ;;
esac

# Build GitHub repo name
if [ -n "$GITHUB_ORG" ]; then
  GITHUB_REPO="$GITHUB_ORG/$PROJECT_NAME"
else
  GITHUB_REPO="$PROJECT_NAME"
fi

# Build Vercel scope flag
VERCEL_SCOPE_FLAG=""
if [ -n "$VERCEL_TEAM" ]; then
  VERCEL_SCOPE_FLAG="--scope $VERCEL_TEAM"
fi

echo ""
info "Configuration:"
echo "  Project:    $PROJECT_NAME"
echo "  GitHub:     $GITHUB_REPO (private)"
echo "  Vercel:     ${VERCEL_TEAM:-personal account}"
echo "  Data layer: $DATA_LAYER"
echo ""
read -rp "Continue? [Y/n] " CONFIRM
CONFIRM="${CONFIRM:-Y}"
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# ===================================================================
# Step 1: Scaffold Next.js app
# ===================================================================
info "Scaffolding Next.js app..."
pnpm create next-app@latest "$PROJECT_NAME" \
  --use-pnpm \
  --ts \
  --tailwind \
  --eslint \
  --app \
  --src-dir \
  --turbopack \
  --import-alias "@/*"

cd "$PROJECT_NAME"
PROJECT_DIR="$(pwd)"

# ===================================================================
# Step 2: Initialize shadcn/ui
# ===================================================================
info "Initializing shadcn/ui with Base UI..."
pnpm dlx shadcn@latest init -d --base base

info "Adding baseline shadcn components..."
pnpm dlx shadcn@latest add button card

# ===================================================================
# Step 3: Install tooling
# ===================================================================
info "Installing Prettier, lint-staged, and Lefthook..."
pnpm add -D prettier prettier-plugin-tailwindcss lint-staged lefthook

# ===================================================================
# Step 4: Copy static templates
# ===================================================================
info "Copying template files..."
cp "$TEMPLATES_DIR/.prettierrc" .prettierrc
cp "$TEMPLATES_DIR/.node-version" .node-version
cp "$TEMPLATES_DIR/lefthook.yml" lefthook.yml
cp "$TEMPLATES_DIR/CLAUDE.md" CLAUDE.md

# Error pages
cp "$TEMPLATES_DIR/error.tsx" src/app/error.tsx
cp "$TEMPLATES_DIR/not-found.tsx" src/app/not-found.tsx

# Env pull script
mkdir -p scripts
cp "$TEMPLATES_DIR/env-pull.sh" scripts/env-pull.sh
chmod +x scripts/env-pull.sh

# ===================================================================
# Step 5: Configure TypeScript
# ===================================================================
info "Configuring TypeScript..."
# Add verbatimModuleSyntax to tsconfig.json
node -e "
const fs = require('fs');
const tsconfig = JSON.parse(fs.readFileSync('tsconfig.json', 'utf8'));
tsconfig.compilerOptions.verbatimModuleSyntax = true;
fs.writeFileSync('tsconfig.json', JSON.stringify(tsconfig, null, 2) + '\n');
"

# ===================================================================
# Step 6: Configure package.json
# ===================================================================
info "Configuring package.json..."
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.engines = { node: '>=22' };
pkg.scripts['env:pull'] = 'vercel env pull .env.local --yes';
pkg['lint-staged'] = { '*.{js,jsx,ts,tsx,css,json,md}': ['prettier --write'] };
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"

# ===================================================================
# Step 7: Initialize Lefthook
# ===================================================================
info "Initializing Lefthook..."
pnpm exec lefthook install

# ===================================================================
# Step 8: Install data layer dependencies
# ===================================================================
if [ "$DATA_LAYER" = "convex" ]; then
  info "Installing Convex..."
  pnpm add convex

  mkdir -p convex
  cp "$TEMPLATES_DIR/convex/schema.ts" convex/schema.ts
  cp "$TEMPLATES_DIR/convex/queries.ts" convex/queries.ts

  # Add convex scripts to package.json
  node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.scripts['convex:dev'] = 'convex dev';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"
else
  info "Installing PlanetScale + Drizzle..."
  pnpm add @planetscale/database drizzle-orm
  pnpm add -D drizzle-kit dotenv-cli

  cp "$TEMPLATES_DIR/drizzle/drizzle.config.ts" drizzle.config.ts
  mkdir -p src/db
  cp "$TEMPLATES_DIR/drizzle/db-index.ts" src/db/index.ts
  cp "$TEMPLATES_DIR/drizzle/db-schema.ts" src/db/schema.ts

  # Add drizzle scripts to package.json
  node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.scripts['db:push'] = 'dotenv -e .env.local -- drizzle-kit push';
pkg.scripts['db:studio'] = 'dotenv -e .env.local -- drizzle-kit studio';
pkg.scripts['db:generate'] = 'dotenv -e .env.local -- drizzle-kit generate';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"
fi

# ===================================================================
# Step 9: Install WorkOS AuthKit
# ===================================================================
info "Installing WorkOS AuthKit..."
npx workos@latest install

info "Running WorkOS doctor..."
npx workos@latest doctor || warn "workos doctor reported issues (may be expected for unclaimed environment)"

# ===================================================================
# Step 10: Copy hello world pages
# ===================================================================
info "Setting up hello world pages..."

# Landing page with project name
sed "s/__PROJECT_NAME__/$PROJECT_NAME/g" "$TEMPLATES_DIR/page.tsx" > src/app/page.tsx

# Dashboard
mkdir -p src/app/dashboard
cp "$TEMPLATES_DIR/dashboard-page.tsx" src/app/dashboard/page.tsx

# ===================================================================
# Step 11: Install agent skills
# ===================================================================
info "Installing agent skills..."
pnpm dlx skills add react-best-practices 2>/dev/null || warn "Failed to install react-best-practices skill"
pnpm dlx skills add web-design-guidelines 2>/dev/null || warn "Failed to install web-design-guidelines skill"
pnpm dlx skills add composition-patterns 2>/dev/null || warn "Failed to install composition-patterns skill"
pnpm dlx skills add shadcn/ui 2>/dev/null || warn "Failed to install shadcn/ui skill"

# ===================================================================
# Step 12: Run Prettier on all files
# ===================================================================
info "Formatting with Prettier..."
pnpm exec prettier --write . 2>/dev/null || true

# ===================================================================
# Step 13: Generate README
# ===================================================================
info "Generating README..."
if [ "$DATA_LAYER" = "convex" ]; then
  DATA_LAYER_DISPLAY="Convex"
  DATA_SETUP_INSTRUCTIONS="npx convex dev
npx convex ai-files install"
else
  DATA_LAYER_DISPLAY="PlanetScale + Drizzle"
  DATA_SETUP_INSTRUCTIONS="# Create a PlanetScale database, add DATABASE_URL to Vercel, then:
pnpm run env:pull
pnpm run db:push"
fi

cat > README.md << READMEEOF
# $PROJECT_NAME

Built with [product-kit](https://github.com/EMT/product-kit).

## Stack

- **Framework**: Next.js (App Router)
- **Auth**: WorkOS AuthKit
- **Data**: $DATA_LAYER_DISPLAY
- **Styling**: Tailwind CSS + shadcn/ui (Base UI)
- **Hosting**: Vercel

## Setup

\`\`\`bash
# Install dependencies
pnpm install

# Pull environment variables from Vercel
pnpm run env:pull

# Set up data layer
$DATA_SETUP_INSTRUCTIONS

# Start development
pnpm dev
\`\`\`

## Scripts

| Command | Description |
|---------|-------------|
| \`pnpm dev\` | Start development server |
| \`pnpm build\` | Build for production |
| \`pnpm run env:pull\` | Pull env vars from Vercel |
READMEEOF

if [ "$DATA_LAYER" = "convex" ]; then
  cat >> README.md << 'READMEEOF'
| `pnpm run convex:dev` | Start Convex development |
READMEEOF
else
  cat >> README.md << 'READMEEOF'
| `pnpm run db:push` | Push schema to PlanetScale |
| `pnpm run db:studio` | Open Drizzle Studio |
READMEEOF
fi

# ===================================================================
# Step 14: Git init + first commit
# ===================================================================
info "Initializing git repository..."
git init
git branch -m main
git add -A
git commit -m "Initial commit via product-kit

Scaffolded with: Next.js, WorkOS AuthKit, $DATA_LAYER_DISPLAY, shadcn/ui (Base UI), Tailwind CSS.
Deployed to Vercel."

# ===================================================================
# Step 15: Create GitHub repo + push
# ===================================================================
info "Creating GitHub repository..."
gh repo create "$GITHUB_REPO" --private --source . --push

# ===================================================================
# Step 16: Link Vercel + deploy
# ===================================================================
info "Linking Vercel project..."
vercel link --yes $VERCEL_SCOPE_FLAG

info "Deploying to Vercel..."
vercel --prod --yes $VERCEL_SCOPE_FLAG

# ===================================================================
# Done
# ===================================================================
echo ""
ok "Bootstrap complete!"
echo ""
echo "  GitHub:  https://github.com/$GITHUB_REPO"
echo "  Auth is already working (WorkOS unclaimed environment)."
echo ""
echo -e "${YELLOW}Remaining steps:${NC}"
echo ""

if [ "$DATA_LAYER" = "convex" ]; then
  echo "  1. Set up Convex:"
  echo "     cd $PROJECT_NAME"
  echo "     npx convex dev"
  echo "     npx convex ai-files install"
else
  echo "  1. Set up PlanetScale:"
  echo "     - Create a PlanetScale database"
  echo "     - Add DATABASE_URL to Vercel env vars"
  echo "     cd $PROJECT_NAME"
  echo "     pnpm run env:pull"
  echo "     pnpm run db:push"
fi

echo ""
echo "  2. Start development:"
echo "     pnpm dev"
echo ""
echo "  When ready for production:"
echo "  - Claim your WorkOS environment at https://workos.com"
echo ""
