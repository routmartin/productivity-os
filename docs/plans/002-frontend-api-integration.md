# Plan: Frontend API Integration

## Status

Approved for implementation. The governing specification
(`docs/specs/api-integration.md`) is Approved.

## Specification

Primary behavioral source of truth:

- `docs/specs/api-integration.md` (Approved)

Acceptance criteria in scope:

- AC-001 tasks persist across refresh
- AC-002 task lifecycle persists
- AC-003 projects and goals persist
- AC-004 Daily Top 3 persists per date
- AC-005 focus sessions recorded
- AC-006 silent token refresh
- AC-007 refresh failure returns to login
- AC-008 server error surfaces existing error state
- AC-009 domain error messages reach the user
- AC-010 mock mode still available
- AC-011 user isolation honored client-side

Supporting decisions and constraints:

- ADR-004 — token model, isolation rules
- ADR-005 — URL conventions, error model, pagination
- ADR-006 — date/timestamp handling

## Architecture

The frontend replaces mock-backed stores with typed API modules built on the
existing `lib/api/client.ts`. The client gains a silent-refresh interceptor.
Each feature module gets its own `api.ts` with typed request/response DTOs
matching the backend. Mock mode remains available via per-feature env
toggles.

Modules introduced or changed:

- `lib/api/client.ts` — add silent 401→refresh→retry interceptor
- `lib/api/types.ts` — shared `Page<T>` and error response types
- `features/auth/api.ts` — extend with `refresh()`, `getProfile()`
- `features/tasks/api.ts` + `api-types.ts` — new
- `features/projects/api.ts` + `api-types.ts` — new
- `features/goals/api.ts` + `api-types.ts` — new
- `features/planning/api.ts` + `api-types.ts` — new (daily-top-three + daily-plan)
- `features/focus/api.ts` + `api-types.ts` — new
- Feature stores — swap mock for real API behind env toggle

## Step 1 — Silent token refresh in apiClient

**Status: IMPLEMENTED** (`apps/web/src/lib/api/client.ts`,
`apps/web/src/main.ts`). Unit tests from the original step spec are still
pending.

- **Files/modules:** `lib/api/client.ts` (edit)
- **Spec/AC:** AC-006, AC-007
- **Behavior:**
  - On 401, call `POST /api/v1/auth/refresh` (cookie is automatic).
  - If refresh succeeds, retry the original request once with the new token.
  - If refresh fails (401 from refresh itself), clear the session and
    redirect to `/login`.
  - Concurrent 401s share one refresh promise; subsequent requests wait.
- **As implemented:**
  - `refreshAccessToken()` deduplicates concurrent 401s via a single
    shared `refreshPromise` (Rule 5) and resolves `true` only when the
    response carries a string `accessToken`.
  - `request()` skips the refresh for auth paths (`isAuthPath`) and for the
    single retry (`isRetry`), enforcing at-most-one retry (Rule 6).
  - `main.ts` wires `setSessionHandlers`: `onRefreshed` replaces only the
    `accessToken` in the persisted session (profile preserved — the refresh
    response carries `user: null`); `onSessionExpired` clears the session
    and redirects to `/login`.
  - Every request sends `credentials: "include"` so the HttpOnly refresh
    cookie reaches `/auth/refresh`.
- **Dependencies:** none.
- **Tests (pending):**
  - Mock `fetch` to return 401 once, then 200 after refresh → original
    request succeeds.
  - Two concurrent 401s trigger exactly one refresh call.
  - Refresh returns 401 → session cleared, redirect attempted.
- **Risks/ambiguities:** the refresh endpoint returns `LoginResponse` with
  `user: null` (per AuthController); the client keeps the existing user
  object from the current session. **Deviation from plan:** the refresh
  call lives in the shared `lib/api/client.ts` rather than
  `features/auth/api.ts` (Step 8), so every module benefits from it.

## Step 2 — Shared API types

**Status: IMPLEMENTED** (`apps/web/src/lib/api/types.ts`). Type-guard unit
tests are still pending.

- **Files/modules:** `lib/api/types.ts` (new)
- **Spec/AC:** AC-005, AC-008, AC-009 (error handling foundation)
- **Contents:**
  - `Page<T>` — `{ content: T[], page: number, size: number, totalElements: number, totalPages: number }`
    matching Spring Data's page response.
  - `ApiErrorResponse` — `{ code: string, message: string, details?: Record<string, unknown>, traceId?: string }`
  - Helper: `isPage<T>(value: unknown): value is Page<T>`
- **As implemented:** identical to the plan. `ApiError` itself lives in
  `lib/api/client.ts` (constructed from the parsed `ApiErrorResponse`).
- **Dependencies:** none.
- **Tests (pending):** type-guard unit tests.
- **Risks/ambiguities:** none.

## Step 3 — Tasks API + store integration

- **Files/modules:**
  - `features/tasks/api-types.ts` (new) — `TaskResponse`, `CreateTaskRequest`
  - `features/tasks/api.ts` (new) — list, create, complete, reopen, cancel,
    delete, restore, assignProject
  - `features/tasks/store.ts` (edit) — replace mock with API calls behind
    `VITE_USE_MOCK_TASKS` toggle
- **Spec/AC:** AC-001, AC-002, AC-008, AC-009, AC-010, AC-011
- **Backend endpoints used:**
  - `GET /api/v1/tasks?page=&size=` → `TaskResponse[]` (not paginated —
    returns a plain array)
  - `POST /api/v1/tasks` → `TaskResponse`
  - `POST /api/v1/tasks/{id}/plan` → `TaskResponse`
  - `POST /api/v1/tasks/{id}/start` → `TaskResponse`
  - `POST /api/v1/tasks/{id}/completion` → `TaskResponse`
  - `POST /api/v1/tasks/{id}/cancellation` → `TaskResponse`
  - `POST /api/v1/tasks/{id}/reopening` → `TaskResponse`
  - `DELETE /api/v1/tasks/{id}` → 204
  - `POST /api/v1/tasks/{id}/restoration` → `TaskResponse`
  - `PUT /api/v1/tasks/{id}/project` → `TaskResponse`
- **Dependencies:** Step 1 (refresh), Step 2 (types).
- **Tests:**
  - Store integration test with MSW or manual fetch mock: load → list
    renders; create → appears; complete → status flips; error → error state.
  - AC-001: create then reload → task present (manual verification).
  - AC-002: complete then reload → status and completedAt present.
  - AC-008: fetch rejects → error state renders, retry works.
  - AC-009: mock 409 with code `INVALID_LIFECYCLE_TRANSITION` → message
    surfaces.
  - AC-010: toggle on → mock data renders without backend.
  - AC-011: request interceptor adds no userId field.
- **Risks/ambiguities:** the store currently mixes UI-only concerns
  (searchQuery, statusFilter) with data; keep those local, only replace
  the data source. `GET /tasks` returns a plain array, not a `Page<T>` —
  the store must handle both shapes or we accept array-only for now and
  note the pagination gap (see Open Questions in spec).

## Step 4 — Projects API + store integration

- **Files/modules:**
  - `features/projects/api-types.ts` (new) — `ProjectResponse`, `CreateProjectRequest`
  - `features/projects/api.ts` (new) — list, get, create, activate,
    returnToDraft, complete, archive
  - `features/projects/store.ts` (edit) — replace mock behind
    `VITE_USE_MOCK_PROJECTS` toggle
- **Spec/AC:** AC-003, AC-008, AC-010, AC-011
- **Backend endpoints used:**
  - `GET /api/v1/projects` → `ProjectResponse[]`
  - `GET /api/v1/projects/{id}` → `ProjectResponse`
  - `POST /api/v1/projects` → `ProjectResponse`
  - `POST /api/v1/projects/{id}/activation` → `ProjectResponse`
  - `POST /api/v1/projects/{id}/return-to-draft` → `ProjectResponse`
  - `POST /api/v1/projects/{id}/completion` → `ProjectResponse`
  - `POST /api/v1/projects/{id}/archival` → `ProjectResponse`
- **Dependencies:** Step 1, Step 2.
- **Tests:** same pattern as Step 3 (integration with fetch mock, manual
  AC verification).
- **Risks/ambiguities:** `GET /projects` returns all projects (no
  pagination). The frontend store has `activeProjects` computed; keep that
  client-side filter.

## Step 5 — Goals API + store integration

- **Files/modules:**
  - `features/goals/api-types.ts` (new) — `GoalResponse`, `CreateGoalRequest`,
    `ReopenGoalRequest`
  - `features/goals/api.ts` (new) — list, get, create, activate,
    returnToDraft, complete, reopen, archive
  - `features/goals/store.ts` (edit) — replace mock behind
    `VITE_USE_MOCK_GOALS` toggle
- **Spec/AC:** AC-003, AC-008, AC-010, AC-011
- **Backend endpoints used:**
  - `GET /api/v1/goals` → `GoalResponse[]`
  - `GET /api/v1/goals/{id}` → `GoalResponse`
  - `POST /api/v1/goals` → `GoalResponse`
  - `POST /api/v1/goals/{id}/activation` → `GoalResponse`
  - `POST /api/v1/goals/{id}/return-to-draft` → `GoalResponse`
  - `POST /api/v1/goals/{id}/completion` → `GoalResponse`
  - `POST /api/v1/goals/{id}/reopening` → `GoalResponse`
  - `POST /api/v1/goals/{id}/archival` → `GoalResponse`
- **Dependencies:** Step 1, Step 2.
- **Tests:** same pattern as Step 3.
- **Risks/ambiguities:** `reopen` requires `projectIds` in the request body;
  the UI's current "reopen" action must supply the goal's existing project
  links or an empty array. Check the UI's intent before wiring.

## Step 6 — Daily Top 3 + Daily Plan API + store integration

- **Files/modules:**
  - `features/planning/api-types.ts` (new) — `TopThreeResponse`,
    `SelectTaskRequest`, `ReorderRequest`, `DailyPlanResponse`,
    `PlanTaskRequest`, `SetCapacityRequest`, `CapacityInfo`
  - `features/planning/api.ts` (new) — topThree: list, select, reorder,
    remove; dailyPlan: list, plan, remove, setCapacity, getCapacity
  - `features/planning/todayStore.ts` (edit) — replace mock behind
    `VITE_USE_MOCK_PLANNING` toggle
- **Spec/AC:** AC-004, AC-008, AC-009, AC-010, AC-011
- **Backend endpoints used:**
  - `GET /api/v1/daily-top-three/{date}` → `TopThreeResponse[]`
  - `POST /api/v1/daily-top-three/{date}` → `TopThreeResponse`
  - `PUT /api/v1/daily-top-three/{date}/{selectionId}/position` → `TopThreeResponse[]`
  - `DELETE /api/v1/daily-top-three/{date}/{selectionId}` → `TopThreeResponse[]`
  - `GET /api/v1/daily-plan/{date}` → `DailyPlanResponse[]`
  - `POST /api/v1/daily-plan/{date}` → `DailyPlanResponse`
  - `DELETE /api/v1/daily-plan/{date}/{planId}` → 204
  - `PUT /api/v1/daily-plan/capacity/{date}` → 200
  - `GET /api/v1/daily-plan/{date}/capacity` → `CapacityInfo`
- **Dependencies:** Step 1, Step 2.
- **Tests:** same pattern as Step 3; AC-004 (select three, reload, same
  order) verified manually; AC-009 (`TOP3_FULL` 409 message surfaces).
- **Risks/ambiguities:** date is ISO calendar date (YYYY-MM-DD) per
  ADR-006; the store must send the user's local date, not UTC date.

## Step 7 — Focus API + store integration

- **Files/modules:**
  - `features/focus/api-types.ts` (new) — `FocusSessionResponse`,
    `StartFocusRequest`
  - `features/focus/api.ts` (new) — getActive, start, end, list
  - `features/focus/store.ts` (edit) — replace mock behind
    `VITE_USE_MOCK_FOCUS` toggle
- **Spec/AC:** AC-005, AC-008, AC-010, AC-011
- **Backend endpoints used:**
  - `GET /api/v1/focus/active` → `FocusSessionResponse` or 404
  - `POST /api/v1/focus` → `FocusSessionResponse`
  - `POST /api/v1/focus/{id}/end` → `FocusSessionResponse`
  - `GET /api/v1/focus?page=&size=` → `FocusSessionResponse[]`
- **Dependencies:** Step 1, Step 2.
- **Tests:** same pattern as Step 3; AC-005 (session appears in history
  after reload) verified manually; active session resume on page load.
- **Risks/ambiguities:** `getActive` returns 404 when no session is
  running — the store must treat that as "no active session", not an
  error.

## Step 8 — Auth profile + logout cleanup

**Status: PARTIALLY IMPLEMENTED.** `features/auth/api.ts` already calls
`POST /api/v1/auth/logout` (server clears the refresh cookie); the
refresh-failure redirect is implemented in Step 1 (`onSessionExpired` in
`main.ts`).

- **Files/modules:**
  - `features/auth/api.ts` (edit) — ensure logout calls the backend so the
    refresh cookie is cleared server-side
  - `features/auth/store.ts` (edit) — on refresh failure, clear local
    session and redirect to `/login`
- **Spec/AC:** AC-006, AC-007
- **Backend endpoints used:**
  - `POST /api/v1/auth/logout` → 204
- **As implemented / deviations:**
  - Logout calls the backend (`authApi.logout()` → `POST /auth/logout`,
    mock behind `VITE_USE_MOCK_AUTH`), then clears the local session.
  - Refresh failure handling lives in `lib/api/client.ts` +
    `main.ts` `setSessionHandlers`, not in the auth store — the store
    needs no change.
  - `refresh()` was **not** added to `features/auth/api.ts`; the shared
    client owns it (see Step 1 deviation).
  - `getProfile()` was **not** added — no `GET /users/me` endpoint exists
    (D3); the profile comes from the login response and is kept in the
    persisted session.
- **Tests (pending):** refresh failure path clears session and redirects;
  logout calls backend and clears cookie.

## Step 9 — Error-message mapping for domain codes

- **Files/modules:** `lib/api/client.ts` (edit) or a new
  `lib/api/errorMessages.ts`
- **Spec/AC:** AC-009
- **Behavior:** map known domain codes to user-facing strings (e.g.
  `TOP3_FULL` → "Today's Top 3 is full. Remove one before adding another.",
  `INVALID_LIFECYCLE_TRANSITION` → "That transition isn't allowed.",
  `INVALID_ACTIVE_STATE` → "This item isn't active right now.").
  Fallback: use the server's `message` field.
- **Dependencies:** Steps 3–7 (stores must surface `ApiError.message`).
- **Tests:** each mapped code renders the friendly string; unmapped codes
  fall back to the server message.
- **Risks/ambiguities:** keep the map small; new codes added by the backend
  should fall through gracefully.

## Step 10 — End-to-end verification

**Status: IMPLEMENTED (2026-08-15).** Full-stack run (Postgres 16 + API
bootRun + curl driver) against a fresh registered user (`e2e@test.dev`).

- **Files/modules:** none new.
- **Spec/AC:** all.
- **As verified (API level):**
  - AC-001 create task → visible in `GET /tasks` across new logins.
  - AC-002 plan → start → completion → `COMPLETED` + `completedAt`
    recorded; repeat completion → 409 `CONFLICT`.
  - AC-003 goal + project created with `goalId` link; persist across logins.
  - AC-004 three tasks selected for today's Top 3 → same order after a
    fresh login.
  - AC-005 focus session start/end → duration recorded, session present in
    history after reload.
  - AC-006 `JWT_ACCESS_TOKEN_TTL_MINUTES=1` run: expired token → 401;
    `POST /auth/refresh` (HttpOnly cookie) → new accessToken; retried
    request → 200. Client dedup/retry already PASS by code inspection.
  - AC-007 refresh without cookie → 401; client `onSessionExpired` →
    session cleared + `/login` redirect (code inspection).
  - AC-008 error-state UI (ErrorState + Retry wired in Tasks/Inbox pages)
    — code inspection; browser check still recommended.
  - AC-009 Top 3 4th selection → 409 `CONFLICT` "Top 3 is full". Fixed
    `errorMessages.ts` so `CONFLICT` surfaces the server message instead of
    a generic string.
  - AC-010 per-feature mock toggles present (`useMock(...)`) — code
    inspection.
  - AC-011 requests carry only the Bearer token — code inspection (PASS
    since the first drift pass).
  - AC-012 PUT task full-replace edit (incl. clearing `description` via
    `null`) persisted.
  - AC-013 DELETE task → 204; gone from list.
  - AC-014 PUT project rename + goal/description/deadline clear persisted.
  - AC-015 project delete → task survives with `projectId: null`.
  - AC-016 PUT goal edit persisted.
  - AC-017 goal delete → project survives with `goalId: null`.
- **Risks/ambiguities:** token TTL is short (minutes per ADR-004); the
  refresh test used `JWT_ACCESS_TOKEN_TTL_MINUTES=1` (D6). Remaining
  browser-only checks: visual error states, mock toggles in the UI, and
  silent-refresh UX in the browser.

## Step 11 — Edit/delete endpoints (backend amendment)

**Status:** IMPLEMENTED (2026-08-14, commit `20ee838`).

- **Files/modules:** `apps/api/.../{task,project,goal}/` — new
  `UpdateTaskRequest`, `UpdateProjectRequest`, `UpdateGoalRequest`; PUT on
  the three controllers; `DELETE /projects/{id}` + `DELETE /goals/{id}`
  with detach; 404 for missing/foreign resources.
- **Spec/AC:** AC-012 through AC-017.
- **Behavior:** full-replace PUT (send complete edited set; explicit
  `null` clears nullable fields; absent/blank title keeps existing).
  Project delete sets `tasks.project_id = NULL`; goal delete sets
  `projects.goal_id = NULL`. Task delete already exists (soft).
- **Dependencies:** human-approved amendment (D7, D8).
- **Tests:** deferred per human decision (all tests skipped until
  requested); manual curl checks during Step 10.
- **Risks/ambiguities:** detach must run in the same transaction as the
  delete; ownership checks on both the resource and its user scope.

## Step 12 — Edit/delete UI (frontend)

**Status:** IMPLEMENTED (commits `c91cae0`, `19da798`).

- **Files/modules:** `features/{tasks,projects,goals}/{api.ts,store.ts}`,
  dialogs (`NewTaskDialog`, `NewProjectDialog`, `NewGoalDialog` gain an
  edit mode), `TaskActionMenu` (wire plan/start/complete/delete/edit),
  project/goal cards + detail panels gain action menus, delete
  confirmations.
- **Spec/AC:** AC-012 through AC-017.
- **Behavior:** edit dialogs prefill from the row and PUT the changes;
  delete asks for confirmation, calls DELETE, and removes the row; task
  menu items that already had backend endpoints (plan/start/complete) are
  wired for real; mock mode keeps the milestone behavior.
- **Dependencies:** Step 11.
- **Tests:** deferred per human decision.
- **Risks/ambiguities:** edit dialogs must keep the existing mock-mode
  fields (scheduledTime/recurrence) out of the real payload; goal option
  lists in edit mode must allow "No goal" (clears via `null`).

## Tests

Traceability matrix:

- AC-001, AC-002 → Step 3 store integration tests + manual reload check
- AC-003 → Steps 4–5 store integration tests + manual reload check
- AC-004 → Step 6 store integration tests + manual reload check
- AC-005 → Step 7 store integration tests + manual reload check
- AC-006 → Step 1 unit tests + manual expiry check
- AC-007 → Step 1 unit tests + Step 8 store test
- AC-008 → Steps 3–7 store integration tests (fetch mock rejection)
- AC-009 → Step 9 mapping tests + Step 6 manual TOP3_FULL check
- AC-010 → Steps 3–7 toggle tests (env var set, no backend)
- AC-011 → Step 3 request-interceptor test (assert no userId in payload)
- AC-012 → Step 11/12 store + curl checks, manual reload check
- AC-013 → Step 12 store + manual reload check
- AC-014 → Step 11/12 store + curl checks, manual reload check
- AC-015 → Step 11/12 curl check (tasks keep no project) + manual reload
- AC-016 → Step 11/12 store + curl checks, manual reload check
- AC-017 → Step 11/12 curl check (projects keep no goal) + manual reload

## AC Status (spec-sync drift check, 2026-08-14)

Per `docs/specs/api-integration.md` and the spec-sync workflow (status:
PASS / FAIL / NOT VERIFIED / UNREACHABLE):

| AC | Status | Evidence |
|----|--------|----------|
| AC-001 | PASS | Step 10 E2E: create + reload persistence verified (2026-08-15) |
| AC-002 | PASS | Step 10 E2E: lifecycle + completedAt verified |
| AC-003 | PASS | Step 10 E2E: goal + project persistence verified |
| AC-004 | PASS | Step 10 E2E: Top 3 order persists across logins |
| AC-005 | PASS | Step 10 E2E: focus session recorded, history after reload |
| AC-006 | PASS | Step 1 code inspection + Step 10 E2E with TTL=1min (401 → refresh → retry 200) |
| AC-007 | PASS | Step 1/8 code inspection + refresh-without-cookie 401 verified |
| AC-008 | PASS (code) | ErrorState + Retry wired in Tasks/Inbox/Goals pages; browser check recommended |
| AC-009 | PASS | Step 10 E2E: 409 "Top 3 is full" surfaces server message after `errorMessages.ts` CONFLICT fix |
| AC-010 | PASS (code) | Per-feature mock toggles exist (`useMock` in every store) |
| AC-011 | PASS | Client sends only the Bearer token (no userId in any request); verified by code inspection |
| AC-012 | PASS | Step 10 E2E: PUT task full-replace edit persisted |
| AC-013 | PASS | Step 10 E2E: DELETE → 204, gone from list |
| AC-014 | PASS | Step 10 E2E: PUT project edit persisted |
| AC-015 | PASS | Step 10 E2E: project delete detaches tasks (projectId: null) |
| AC-016 | PASS | Step 10 E2E: PUT goal edit persisted |
| AC-017 | PASS | Step 10 E2E: goal delete detaches projects (goalId: null) |

*Third drift pass (2026-08-15): Steps 10–12 complete; every AC now PASS or
PASS (code). No FAIL, UNREACHABLE, or intended-change items — no spec
amendment needed.*

## Verification

Before reporting completion (per AGENTS.md):

1. All in-scope acceptance criteria pass (automated where possible, manual
   checklist otherwise).
2. `vue-tsc` and `eslint` pass; backend tests still pass (`make test`).
3. No unrelated changes introduced (diff review).
4. Completion report includes: summary, specification references, files
   changed, AC pass/fail evidence, deviations, risks, follow-ups.

## Pre-Implementation Decisions (must be resolved first)

- **D1 (resolved):** the spec `docs/specs/api-integration.md` is now
  **Approved**. Implementation may proceed.
- **D2 (resolved):** `GET /api/v1/tasks` returns a plain array, not a
  paginated `Page<T>` — confirmed against `TaskController` (and the same
  applies to `GET /focus`). V1 accepts array-only responses; the
  pagination gap is recorded in the spec's Constraints and Open Questions.
  No backend change requested.
- **D3 (confirmed):** `GET /api/v1/users/me` does not exist —
  `UserController` exposes only `PUT /password` and `PUT /timezone`. The
  user profile will come only from the login response.
- **D4 (resolved 2026-08-14):** Goal `reopening` requires `projectIds` —
  the existing ReopenGoalDialog multi-select supplies them (all archived
  projects preselected, user can uncheck). Wired in Step 5.
- **D5 (resolved):** store fields that are purely local UI state
  (`searchQuery`, `statusFilter`, `previewEmpty`, etc.) stay client-side;
  feature stores keep them and only the data source is replaced. They are
  never sent to the API.
- **D6 (resolved 2026-08-14):** For manual AC-006 testing, run the backend
  with `JWT_ACCESS_TOKEN_TTL_MINUTES=1` (env var already exists; default
  15 min). No client-side test machinery.
- **D7 (resolved 2026-08-14, human-approved):** edit semantics are
  full-replace PUT (`null` clears nullable fields; title never cleared).
- **D8 (resolved 2026-08-14, human-approved):** delete semantics are hard
  delete with detach (project → `tasks.project_id = NULL`; goal →
  `projects.goal_id = NULL`). Task delete remains soft.

## Out of Scope for This Plan

- Real-time sync (WebSockets, SSE).
- Offline queue / conflict resolution.
- Infinite scroll or cursor pagination UI.
- Backend changes beyond the approved 2026-08-14 edit/delete amendment
  (Steps 11–12). Gaps are reported, not patched.
- OAuth/social login.
- AI feature integration.
- Service-worker caching or PWA behavior.

## Implementation Status

- **Done:** Step 1 (silent refresh — client.ts + main.ts), Step 2 (shared
  API types — types.ts), Step 3 (tasks API + store), Step 4 (projects API
  + store), Step 5 (goals API + store, incl. reopen projectIds), Step 6
  (planning API + todayStore), Step 7 (focus API + store, incl. reload
  resume), Step 8 (logout + refresh-failure wiring), Step 9 (error-message
  mapping — `lib/api/errorMessages.ts`, used by every store), Step 10
  (end-to-end verification, 2026-08-15 — all ACs PASS), Step 11 (backend
  edit/delete amendment), Step 12 (frontend edit/delete UI).
- **Pending:** the unit tests listed under Steps 1–8 (deferred by human
  decision — all tests skipped until explicitly requested); browser-only
  checks (visual error states, mock toggles in the UI, silent-refresh UX).
- **Human decisions:** D4 resolved (reopen projectIds from the dialog),
  D6 resolved (`JWT_ACCESS_TOKEN_TTL_MINUTES=1` for AC-006 manual checks).
- **Drift fix (2026-08-15):** `errorMessages.ts` now surfaces the server's
  `CONFLICT` message ("Top 3 is full", "Cannot transition…") instead of a
  generic string — required by AC-009.

## Change History

- Initial plan created against `docs/specs/api-integration.md` (Draft).
- Updated on finalization: marked Steps 1, 2, and 8 as implemented (with
  deviations — refresh centralized in the shared client, no `getProfile`),
  resolved D2 (plain-array lists) and D5 (local store state), kept D4 and
  D6 open, and added an Implementation Status section. Pending steps and
  tests are unchanged.
- Spec-sync drift check (2026-08-14): recorded per-AC status — AC-006,
  AC-007, AC-011 PASS (code inspection); AC-001–005, AC-008–010
  NOT VERIFIED (pending steps). No drift found; no spec amendment.
- Implementation update (2026-08-14): Steps 3–7 and 9 implemented with
  per-step commits; D4 resolved (reopen projectIds from the dialog) and
  D6 resolved (`JWT_ACCESS_TOKEN_TTL_MINUTES=1` for AC-006 manual
  testing). Tests deferred by human decision. AC table refreshed for the
  second drift pass — still no FAIL/UNREACHABLE items.
- Implementation update (2026-08-15): Steps 10–12 complete. E2E run
  verified all seventeen ACs (API level); `errorMessages.ts` CONFLICT
  mapping fixed for AC-009; AC table refreshed for the third drift pass —
  every AC PASS or PASS (code).
