# product-kit

A template repository and bootstrap script for spinning up new projects in minutes. The goal is to bring idea-to-first-deployment down from hours to minutes, producing a "hello world" canvas that agents and developers can immediately build on.

## What it produces

For each new project, the bootstrap process creates:

- A GitHub repository (private)
- A Vercel project with a first deployment
- Auth (WorkOS AuthKit)
- Data persistence (Convex or PlanetScale + Drizzle)
- A hello world app with sign-in and a protected dashboard

## Output format

A GitHub template repository with a `bootstrap.sh` script. The script automates everything that doesn't require browser-based OAuth, then prints a checklist for the interactive steps.

---

## Stack

### Core

| Layer | Choice | Notes |
|-------|--------|-------|
| Framework | Next.js (always latest) | App Router only, `src/` directory, Turbopack dev server |
| Auth | WorkOS AuthKit | Installed via `npx workos@latest install` |
| Data (default) | Convex | Real-time backend-as-a-service |
| Data (alternative) | PlanetScale + Drizzle ORM | Traditional relational DB, chosen at bootstrap time |
| Hosting | Vercel | Linked and deployed during bootstrap |

### Frontend

| Layer | Choice | Notes |
|-------|--------|-------|
| Styling | Tailwind CSS | Ships with `create-next-app` |
| Components | shadcn/ui | Initialized with `--base base-ui` (not Radix) |
| Drawer | Base UI native Drawer | Not the shadcn Vaul-based drawer |
| Dark mode | Dark only | `className="dark"` on `<html>`, no toggle |
| Fonts | Next.js defaults | Geist Sans + Geist Mono |

### Tooling

| Tool | Choice | Notes |
|------|--------|-------|
| Package manager | pnpm | |
| Formatting | Prettier | No semicolons, single quotes, 2-space indent, trailing commas `all`, `prettier-plugin-tailwindcss` |
| Linting | ESLint | Next.js default config |
| Pre-commit | Lefthook + lint-staged | Runs Prettier on staged files |
| TypeScript | Strict mode | `verbatimModuleSyntax` enabled, `@/` path alias only |
| Node.js | `.node-version` = `24` | `engines` in `package.json` set to `>=22`. Vercel default is 24.x |

### AI agent support

| Item | Choice | Notes |
|------|--------|-------|
| CLAUDE.md | Minimal | Project-specific conventions only (Base UI not Radix, no Vaul, formatting rules, dark mode only) |
| Agent skills | Installed at bootstrap | See [Agent skills](#agent-skills) section |

---

## Bootstrap script

### Usage

```bash
./bootstrap.sh my-project-name
```

The script prompts for:

- **GitHub org** (leave blank for personal account)
- **Vercel team** (select from available teams)
- **Data layer** (Convex or PlanetScale + Drizzle)

### Automated steps

These run without user interaction:

1. **Scaffold Next.js app**
   - `pnpm create next-app@latest <name> --use-pnpm --ts --tailwind --eslint --app --src-dir --turbopack --import-alias "@/*"`
2. **Initialize shadcn/ui**
   - `pnpm dlx shadcn@latest init -d --base base-ui`
   - Replace the default drawer with Base UI's native Drawer component
3. **Configure Prettier**
   - Install `prettier`, `prettier-plugin-tailwindcss`, `lint-staged`
   - Write `.prettierrc` config
4. **Configure Lefthook**
   - Install `lefthook`
   - Write `lefthook.yml` with pre-commit hook running lint-staged
5. **Configure TypeScript**
   - Enable `verbatimModuleSyntax` in `tsconfig.json`
6. **Set Node.js version**
   - Write `.node-version` with `24`
   - Add `engines` field to `package.json`
7. **Create error page stubs**
   - `src/app/error.tsx`
   - `src/app/not-found.tsx`
8. **Install WorkOS AuthKit**
   - `npx workos@latest install`
   - WorkOS supports running without an account — it creates an unclaimed environment that works immediately. No browser-based sign-up required.
   - The CLI agent scaffolds auth middleware, callback routes, provider wrappers, and `.env.local` credentials automatically.
   - The CLI also configures redirect URIs, webhook endpoints, and other settings without requiring the WorkOS dashboard.
   - The unclaimed environment can be claimed later when the project is ready for production.
   - Run `workos doctor` post-install to verify configuration (redirect URIs, env vars, etc.).
9. **Seed WorkOS environment** (optional, if roles/permissions needed)
   - `workos seed --init` generates a YAML template defining permissions, roles, and organizations in dependency order.
   - `workos seed` applies the config idempotently (skips existing resources).
   - This step is skipped by default for hello-world bootstraps but the template is included for projects that need RBAC from day one.
10. **Create hello world pages**
    - Landing page with project name and "Sign in" button (functional via WorkOS)
    - Protected `/dashboard` route showing authenticated user's name/email
11. **Write CLAUDE.md**
    - Minimal conventions file
12. **Install agent skills**
    - See [Agent skills](#agent-skills) section
    - Includes WorkOS skills (installed via WorkOS CLI) for agent-assisted auth configuration
13. **Write env pull script**
    - `scripts/env-pull.sh` wrapping `vercel env pull .env.local --yes`
14. **Generate README**
    - Project name, stack summary, setup instructions
15. **Git init + first commit**
16. **Create GitHub repo**
    - `gh repo create <org>/<name> --private --source . --push`
17. **Link Vercel project + first deploy**
    - `vercel link` (with selected team)
    - `vercel --prod`
18. **Push env vars to Vercel** (non-secret defaults)
19. **Print interactive checklist** (see below)

### Interactive checklist

After the automated steps complete, the script prints:

```
Bootstrap complete. Auth is already working (WorkOS unclaimed environment).

Remaining steps:

1. Set up data layer:
   [If Convex]
   npx convex dev
   npx convex ai-files install

   [If PlanetScale]
   # Create a PlanetScale database, then:
   # Add DATABASE_URL to Vercel env vars
   vercel env pull .env.local --yes
   pnpm drizzle-kit push

2. Start development:
   pnpm dev

When ready for production:
- Claim your WorkOS environment at https://workos.com
```

---

## Data layer paths

### Convex (default)

The bootstrap script scaffolds:

- `convex/` directory with a sample schema and query
- Convex provider in `src/app/layout.tsx` (wrapped in conditional for initial deploy)
- `package.json` scripts for `convex dev`

User completes setup by running `npx convex dev` which handles login and project creation.

#### Agent support for Convex

After `npx convex dev` completes, install AI helper files:

```bash
npx convex ai-files install
```

This installs:
- `convex/_generated/ai/guidelines.md` — Convex-specific coding guidelines
- Managed sections in `AGENTS.md` and `CLAUDE.md`
- Agent skills via `npx skills`

Additional agent commands:
- `npx convex ai-files update` — update to latest AI files
- `npx convex ai-files status` — check what's installed and stale

For background/remote agents (Codex, Devin, etc.), use Agent Mode which limits permissions while still allowing codegen and testing:

```bash
CONVEX_AGENT_MODE=anonymous npx convex dev --once
```

The Convex MCP server can also be configured to give agents direct access to query and optimize the deployment.

### PlanetScale + Drizzle

The bootstrap script scaffolds:

- `src/db/` directory with Drizzle config, schema file, and client initialization
- `drizzle.config.ts` at project root
- `package.json` scripts using `dotenv-cli` for Drizzle Kit commands
- PlanetScale serverless driver (`@planetscale/database`) + Drizzle ORM

User completes setup by creating a PlanetScale database, adding `DATABASE_URL` to Vercel, pulling env vars, and running `pnpm drizzle-kit push`.

---

## Environment variables

Vercel is the source of truth for all environment variables. No `.env.example` file is committed.

### Workflow

- **Setting vars**: Add via Vercel dashboard or `vercel env add`
- **Local development**: Run `pnpm run env:pull` (alias for `vercel env pull .env.local --yes`)
- **CI/Production**: Vercel injects vars automatically

### Scripts

```json
{
  "scripts": {
    "env:pull": "vercel env pull .env.local --yes"
  }
}
```

### Notes

- `.env.local` is gitignored (Next.js default)
- Non-Next.js scripts (Drizzle Kit, seed scripts) need `dotenv-cli` to load `.env.local`
- OIDC tokens from `vercel env pull` expire after ~12 hours; re-pull at the start of each dev session if using Vercel AI Gateway or similar

---

## Hello world app

After bootstrap completes and the user finishes the interactive checklist:

### `/` — Landing page

- Styled with Tailwind + shadcn/ui
- Dark mode
- Project name displayed
- "Sign in" button linking to WorkOS AuthKit flow (functional immediately — uses unclaimed WorkOS environment)

### `/dashboard` — Protected route

- Requires authentication (WorkOS middleware)
- Displays authenticated user's name and email
- Works end-to-end at first deploy (no WorkOS account required initially)

### Error pages

- `src/app/error.tsx` — error boundary stub
- `src/app/not-found.tsx` — 404 page stub

---

## Agent skills

Installed at bootstrap time to give AI coding agents context about the project's conventions and best practices.

### Always installed

| Skill | Source | Install command |
|-------|--------|-----------------|
| react-best-practices | vercel-labs/agent-skills | `pnpm dlx skills add react-best-practices` |
| web-design-guidelines | vercel-labs/agent-skills | `pnpm dlx skills add web-design-guidelines` |
| composition-patterns | vercel-labs/agent-skills | `pnpm dlx skills add composition-patterns` |
| shadcn/ui | shadcn | `pnpm dlx skills add shadcn/ui` |
| WorkOS | WorkOS CLI | Installed automatically by WorkOS CLI during AuthKit setup |

### Installed conditionally

| Skill | Condition | Install method |
|-------|-----------|----------------|
| Convex AI files | Convex data layer selected | `npx convex ai-files install` (after `npx convex dev`) |

### WorkOS CLI tools available to agents

After AuthKit installation, agents can use the WorkOS CLI for ongoing configuration without the dashboard:

| Command | Purpose |
|---------|---------|
| `workos doctor` | Diagnose misconfigurations (redirect URIs, env vars, etc.) |
| `workos seed --init` | Generate YAML template for permissions, roles, organizations |
| `workos seed` | Apply YAML config idempotently |
| `workos seed --clean` | Remove seeded resources |
| Resource commands | Query roles, permissions, users, directories, audit logs |
| Redirect URI management | Set/update redirect URIs via CLI |
| Webhook management | Create and manage webhook endpoints via CLI |

---

## CLAUDE.md conventions

The template includes a minimal `CLAUDE.md` focused on project-specific conventions that agents can't learn from installed skills:

```markdown
# Conventions

- shadcn/ui uses Base UI primitives, NOT Radix. Do not import from `radix-ui` or `@radix-ui/*`.
- Drawer component uses Base UI's native Drawer. Do not use Vaul.
- Dark mode only. Do not add theme toggles or light mode styles.
- Prettier: no semicolons, single quotes, trailing commas all, 2-space indent.
- App Router only. Do not create files in pages/.
- Use `@/` path alias for all imports from src/.
- Pre-commit hooks use Lefthook, not Husky.
- Environment variables are managed via Vercel. Run `pnpm run env:pull` to sync locally.
```

---

## Project structure

```
<project-name>/
  .node-version
  .prettierrc
  lefthook.yml
  CLAUDE.md
  README.md
  package.json
  tsconfig.json
  next.config.ts
  scripts/
    env-pull.sh
  src/
    app/
      layout.tsx
      page.tsx
      error.tsx
      not-found.tsx
      dashboard/
        page.tsx
    components/
      ui/
        drawer.tsx          # Base UI Drawer (replaces shadcn default)
        ... (shadcn components)
    lib/
      utils.ts              # cn() utility from shadcn

  # If Convex:
  convex/
    schema.ts
    queries.ts

  # If PlanetScale + Drizzle:
  drizzle.config.ts
  src/
    db/
      index.ts              # Drizzle client
      schema.ts             # Drizzle schema
```

---

## GitHub repository

- **Visibility**: Private
- **Branch protection**: None (added per-project as needed)
- **License**: None
- **Org**: Prompted at bootstrap time (defaults to personal account)

---

## Vercel project

- **Team**: Prompted at bootstrap time
- **Framework**: Auto-detected (Next.js)
- **Node.js**: 24.x (via `engines` in `package.json`)
- **First deploy**: Triggered by bootstrap script (`vercel --prod`)
- **Env vars**: Pushed to Vercel during bootstrap, pulled locally via `pnpm run env:pull`

---

## Future considerations

- Automate Convex/PlanetScale provisioning (both require interactive login currently)
- Add more data layer options (Supabase, Neon, etc.)
- Monorepo variant with Turborepo
- CI/CD templates (GitHub Actions)
- Optional integrations (Sentry, analytics, email)
