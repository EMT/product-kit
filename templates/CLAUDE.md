# Conventions

- shadcn/ui uses Base UI primitives, NOT Radix. Do not import from `radix-ui` or `@radix-ui/*`.
- Drawer component uses Base UI's native Drawer. Do not use Vaul.
- Dark mode only. Do not add theme toggles or light mode styles.
- Prettier: no semicolons, single quotes, trailing commas all, 2-space indent.
- App Router only. Do not create files in pages/.
- Use `@/` path alias for all imports from src/.
- Pre-commit hooks use Lefthook, not Husky.
- Environment variables are managed via Vercel. Run `pnpm run env:pull` to sync locally.
