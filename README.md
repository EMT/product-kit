# product-kit

Bootstrap a new project in minutes. One script gets you from zero to a deployed Next.js app with auth, data persistence, and a canvas ready for agents to build on.

## What you get

- Private GitHub repo
- Vercel project with first production deployment
- WorkOS AuthKit (functional immediately, no account required)
- Data layer (Convex or PlanetScale + Drizzle)
- shadcn/ui with Base UI primitives
- Prettier, ESLint, Lefthook pre-commit hooks
- AI agent skills pre-installed

## Prerequisites

- [pnpm](https://pnpm.io/)
- [GitHub CLI](https://cli.github.com/) (`gh`) — authenticated
- [Vercel CLI](https://vercel.com/docs/cli) (`vercel`) — authenticated
- Node.js 22+

## Usage

```bash
./bootstrap.sh my-project-name
```

The script prompts for:

1. **GitHub org** — leave blank for personal account
2. **Vercel team** — leave blank for personal account
3. **Data layer** — Convex (default) or PlanetScale + Drizzle

Everything else is automated. When the script finishes, your app is deployed to Vercel with working auth. The only remaining step is setting up your data layer.

## What the script does

1. Scaffolds a Next.js app (App Router, `src/` directory, Turbopack)
2. Initializes shadcn/ui with Base UI
3. Installs Prettier, lint-staged, Lefthook
4. Configures TypeScript (strict, `verbatimModuleSyntax`)
5. Installs WorkOS AuthKit (creates unclaimed environment — no sign-up needed)
6. Scaffolds data layer (Convex schema or Drizzle config + PlanetScale client)
7. Creates hello world pages (landing page with sign-in, protected dashboard)
8. Installs agent skills (react-best-practices, web-design-guidelines, composition-patterns, shadcn/ui)
9. Commits, pushes to GitHub, deploys to Vercel

## After bootstrap

```bash
cd my-project-name

# Set up data layer
npx convex dev              # if Convex
npx convex ai-files install

# Or for PlanetScale:
# Create a database, add DATABASE_URL to Vercel, then:
pnpm run env:pull
pnpm run db:push

# Start developing
pnpm dev
```

When ready for production, claim your WorkOS environment at [workos.com](https://workos.com).

## Stack details

See [docs/spec.md](docs/spec.md) for the full specification and decision log.
