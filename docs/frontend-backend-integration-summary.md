# Frontend–Backend Integration — Summary

## Source Documents

| Doc | Role | Status |
|-----|------|--------|
| `docs/specs/api-integration.md` | Governing spec | Approved |
| `docs/plans/002-frontend-api-integration.md` | Implementation plan | Approved — fully implemented (Steps 1–12 done) |
| ADR-004 / 005 / 006, `architecture/system.md` | Supporting decisions | Auth, API conventions, time handling |

## What It Is

Connects the Vue 3 frontend (Milestone 2, mock-data only) to the existing
Spring Boot `/api/v1` REST backend so all data persists in PostgreSQL and syncs
across devices/sessions.

## Key Rules

- **Identity stays server-side** — requests carry only a Bearer token, never a
  userId (AC-011).
- **Auth model** — access token in memory; refresh token in HttpOnly cookie
  scoped to `/auth/*`. Silent refresh on 401: one deduplicated refresh call →
  retry once → redirect to login if refresh fails.
- **Architecture** — each feature gets `features/{name}/api.ts` typed API
  modules on the shared `apiClient`; components never call fetch directly. Mock
  mode kept via per-feature `VITE_USE_MOCK_*` toggles.
- **Error contract** — structured `{code, message, details, traceId}`
  (ADR-005); domain errors like `TOP3_FULL`, `INVALID_LIFECYCLE_TRANSITION`
  surface their server message to users.
- **API adapts to frontend, not reverse** — V1 list endpoints return plain JSON
  arrays (not `Page<T>`); pagination UI deferred.
- **Time** — UTC instants + date-only strings per ADR-006; local-date bucketing
  client-side for Top 3/daily plan.

## Edit/Delete Amendment (2026-08-14)

Only approved backend change: full-replace PUT (`null` clears nullable fields)
and hard-delete-with-detach for projects/goals (tasks stay soft-deleted).
Deleting a project nulls its tasks' `project_id`; deleting a goal nulls its
projects' `goal_id`.

## Status — All 17 ACs PASS

- AC-001–005: persistence verified E2E (tasks lifecycle, projects/goals,
  Top 3 per date, focus sessions with reload resume via `GET /focus/active`)
- AC-006–007: silent refresh verified with 1-min token TTL
- AC-008–011: error states, domain messages (`errorMessages.ts` CONFLICT fix),
  mock toggles, isolation
- AC-012–017: edit/delete UI wired through dialogs/menus

## Known Gaps / Out of Scope

- Unit tests from Steps 1–8 deferred by human decision
- Browser-only checks pending (visual error states, silent-refresh UX in browser)
- No real-time sync (WebSockets/SSE), no offline queue, no infinite scroll, no
  OAuth, no AI integration
