# Productivity OS — Web (`apps/web`)

Vue 3 + TypeScript + Vite frontend (ADR-002). Dark-first "Calm Command
Center" design.

## Run

```bash
pnpm install
pnpm dev        # http://localhost:5173
```

Sign in with any email and a password of 8+ characters (mock auth).

## Scripts

- `pnpm dev` — Vite dev server (proxies `/api` to `localhost:8080`)
- `pnpm build` — typecheck + production build
- `pnpm typecheck` — vue-tsc
- `pnpm lint` — ESLint (flat config)
- `pnpm preview` — serve the production build

## Structure

```
src/
  app/        router, layouts (shell, sidebar, context panel), panel store
  features/   auth, tasks, planning, focus, ai — each owns its
              types / mock / store / components
  components/ ui (primitives), shared (states: empty, error, skeleton)
  lib/        api client (ADR-005), auth session, utils (date, duration)
  pages/      route-level pages (Login, Today, ComingSoon)
  styles/     design tokens + base styles
```

## Notes

- Mock auth by default; set `VITE_USE_MOCK_AUTH=false` to call the real
  `POST /api/v1/auth/login` (run the backend + `docker compose up -d`).
- Today states can be previewed via `?preview=loading|error|empty`.
