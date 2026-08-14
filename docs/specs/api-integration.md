# Frontend API Integration

## Status

Approved

## Problem

The frontend (Milestone 2) runs entirely on in-memory mock data. Tasks,
projects, goals, focus sessions, and daily plans disappear on page refresh and
are shared across no devices. Meanwhile the backend (Milestone 1) already
exposes a complete, tested REST API for these domains. The two halves are not
connected, so the product cannot yet fulfill its core promise: a user captures
work on one device and trusts it everywhere.

## Goal

Replace every mock-backed feature store with real API calls against the
existing `/api/v1` backend, so that all user data is persisted in PostgreSQL
and shared across sessions and devices — without regressing the UI behaviors
(loading, error, empty states) already built.

## User Story

As a user, I want my tasks, projects, goals, plans, and focus sessions saved
to my account, so that my work survives refreshes and follows me across
devices.

## Behavior

- On login, the user sees their own previously saved data, not seed data.
- Creating, editing, completing, reopening, and deleting a task persists
  immediately and is visible after a page refresh.
- Creating, editing, archiving, and deleting projects and goals persists the
  same way. Deleting a project detaches its tasks (they stay, project-less);
  deleting a goal detaches its projects (they stay, goal-less).
- Selecting Today's Top 3, reordering it, and clearing it persist per date.
- Starting and stopping a focus session records it; the focus history and
  today's summary reflect real recorded sessions.
- When the access token expires mid-session, the app silently refreshes it
  using the refresh-token cookie and retries the failed request once. The
  user is not logged out and does not lose their place.
- If silent refresh fails (expired or revoked refresh token), the user is
  returned to the login screen.
- Network or server failures surface the existing error states with a Retry
  action; no raw backend errors are shown.
- The user can still review the UI without the backend (design-review mode).

## Rules

1. Identity and scoping stay server-side. The frontend never sends a userId;
   it sends only the Bearer access token (ADR-004).
2. The refresh token is never readable by JavaScript. It travels only in the
   HttpOnly cookie scoped to the auth endpoints (ADR-004). The frontend
   stores the access token in memory; the existing session persistence may
   keep it for page reloads, but the refresh cookie is the source of
   long-lived sessions.
3. Every feature store talks to the backend through its own typed API module
   (`features/{name}/api.ts`) built on the shared `apiClient`. Components
   never call fetch directly.
4. The structured error model (`code`, `message`, `details`, `traceId` per
   ADR-005) is the only error contract. Domain errors (e.g. `TOP3_FULL`,
   `INVALID_LIFECYCLE_TRANSITION`) must surface their `message` to the user.
5. Concurrent requests that all fail with 401 trigger exactly one refresh
   attempt; the rest wait for it and then retry.
6. A failed request is retried at most once after a successful refresh.
7. Existing UI states are preserved: loading skeletons, error states with
   retry, and empty states behave as they did with mocks.
8. Mock mode remains available per feature for design review, controlled by
   environment toggles. Real API is the default once a feature is
   integrated.
9. ISO-8601 handling follows ADR-006: timestamps are UTC instants, calendar
   dates are date-only strings; no client-side timezone conversion of
   server-provided instants beyond display formatting.
10. Beyond the scoped edit/delete surface added by the 2026-08-14 amendment
    (`PUT /tasks/{id}`, `PUT /projects/{id}`, `PUT /goals/{id}`,
    `DELETE /projects/{id}`, `DELETE /goals/{id}`), the integration must not
    change backend behavior, endpoint, or response shape. Any other unmet UI
    need is reported rather than worked around client-side (per AGENTS.md
    source of truth).

## Constraints

- Backend endpoints, DTOs, and status codes are fixed by Milestone 1,
  except the approved 2026-08-14 amendment which adds the edit/delete
  surface (Rule 10). The frontend adapts to the API, not the reverse.
- Edit semantics are full-replace PUT: the client sends the complete edited
  field set; an explicit `null` clears a nullable field (title is never
  cleared — an absent/blank title keeps the existing one).
- Delete semantics are hard delete with detach: deleting a project sets its
  tasks' `project_id` to NULL; deleting a goal sets its projects' `goal_id`
  to NULL. Task delete stays soft (`deletedAt`), per the existing endpoint.
- No new dependencies are required: the existing `fetch`-based `apiClient`
  is sufficient.
- Pagination follows ADR-005 (`page`, `size` with server-capped maximums).
  V1 UI loads the first page per collection; infinite scroll or full
  pagination UI is out of scope.
- Verified against the backend: V1 list endpoints (`GET /tasks`,
  `GET /focus`, `GET /daily-top-three/{date}`, `GET /daily-plan/{date}`,
  `GET /projects`, `GET /goals`) accept `page`/`size` but return **plain
  JSON arrays**, not a `Page<T>` envelope. The frontend accepts the array
  shape for V1; pagination metadata is not required client-side.
- Optimistic updates are allowed only where the UI already has an Undo
  pattern (task completion); all other writes wait for server confirmation.

## Acceptance Criteria

### AC-001 — Tasks persist across refresh

Given a logged-in user
When they create a task, then reload the page
Then the task appears in their list with the same data.

### AC-002 — Task lifecycle persists

Given a logged-in user with a planned task
When they complete the task and reload the page
Then the task shows as Completed with its completion time.

### AC-003 — Projects and goals persist

Given a logged-in user
When they create a project and a goal, then reload the page
Then both appear with their data.

### AC-004 — Daily Top 3 persists per date

Given a logged-in user
When they select three tasks for today, then reload the page
Then the same three tasks appear in the same order.

### AC-005 — Focus sessions are recorded

Given a logged-in user who completed a focus session
When they reload the page
Then the session appears in their focus history and today's summary
includes its duration.

### AC-006 — Silent token refresh

Given a logged-in user whose access token has expired but whose refresh
token is valid
When they perform any action that calls the API
Then the request succeeds after a transparent refresh, with no login
screen and no lost action.

### AC-007 — Refresh failure returns to login

Given a logged-in user whose refresh token is expired or revoked
When they perform any action that calls the API
Then they are redirected to the login screen.

### AC-008 — Server error surfaces existing error state

Given the backend is unreachable or returns 500
When a feature store loads
Then the existing error state renders with a working Retry action.

### AC-009 — Domain error messages reach the user

Given a user who already has three tasks in Today's Top 3
When they attempt to select a fourth
Then the UI shows the server's message (e.g. the `TOP3_FULL` message), not
a generic failure.

### AC-010 — Mock mode still available

Given the `VITE_USE_MOCK_{FEATURE}` toggle is enabled
When the app runs without the backend
Then the corresponding feature renders its mock data as before.

### AC-011 — User isolation honored client-side

Given any API call made by the frontend
When the request is inspected
Then it contains no userId in path, query, or body — only the Bearer token.

### AC-012 — Task edit persists

Given a logged-in user with a task
When they edit its title, priority, or due date and reload the page
Then the task shows the updated values.

### AC-013 — Task delete persists

Given a logged-in user with a task
When they delete it and reload the page
Then the task no longer appears in any list.

### AC-014 — Project edit persists

Given a logged-in user with a project
When they rename it or change its goal or deadline and reload the page
Then the project shows the updated values.

### AC-015 — Project delete detaches its tasks

Given a logged-in user with a project that has tasks
When they delete the project and reload the page
Then the project is gone and its tasks remain with no project.

### AC-016 — Goal edit persists

Given a logged-in user with a goal
When they edit its title, description, or deadline and reload the page
Then the goal shows the updated values.

### AC-017 — Goal delete detaches its projects

Given a logged-in user with a goal that has projects
When they delete the goal and reload the page
Then the goal is gone and its projects remain with no goal.

## Edge Cases

- Page reload during an active focus session: the backend exposes the
  in-progress session via `GET /api/v1/focus/active`, so the timer resumes
  from the server-recorded start time.
- Two tabs open: mutations in one tab are not live-synced to the other in
  V1; a refresh shows the latest server state.
- Clock skew between client and server: date bucketing (today) follows the
  user's stored timezone per ADR-006.
- Rapid repeated toggles of task completion: requests are serialized per
  task so the final state matches the last user action.
- Backend validation failure (400): field-level `details` are shown inline
  where the form supports it, otherwise as the top-level message.

## Out of Scope

- Real-time sync (WebSockets, SSE) between tabs or devices.
- Offline queue / conflict resolution for disconnected editing.
- Infinite scroll or cursor pagination UI.
- Backend changes beyond the approved 2026-08-14 edit/delete amendment
  (new endpoints, changed DTOs, new error codes). Gaps are reported to the
  human, not patched client-side.
- OAuth/social login (ADR-004 defers this).
- AI feature integration.
- Service-worker caching or PWA behavior.

## Dependencies

- `docs/decisions/ADR-004-authentication-user-isolation.md` — token model,
  isolation rules.
- `docs/decisions/ADR-005-api-architecture.md` — URL conventions, error
  model, pagination.
- `docs/decisions/ADR-006-time-and-timezone.md` — date/timestamp handling.
- Backend OpenAPI documentation at `/docs` (springdoc) as the endpoint
  contract reference.
- Existing frontend: `lib/api/client.ts`, `lib/auth/session.ts`, feature
  stores, and their loading/error/empty UI states.

## Open Questions

Resolved. V1 list endpoints return plain arrays (verified against the
controllers; see Constraints). The frontend loads them as-is; pagination UI
and `Page<T>` handling are deferred to a later milestone.

## Resolved During Drafting

Verified against the backend controllers while writing this spec:

- **Active focus session** — available: `GET /api/v1/focus/active` returns
  the in-progress session or 404 (`FocusController`). Timer resume after
  reload is possible.
- **Soft-deleted tasks in lists** — `GET /api/v1/tasks` calls
  `listActive`, which excludes deleted tasks (`TaskController`).
- **Task lifecycle endpoints** — plan/start/complete/cancel/reopen/
  delete/restore and `PUT /{id}/project` exist as explicit action
  endpoints per ADR-005 (`TaskController`).
- **Refresh response** — `POST /api/v1/auth/refresh` returns
  `LoginResponse` with `user: null` (`AuthController`); the client keeps
  the existing profile from the persisted session.

## Verified Against Implementation

Checked against `apps/web/src/lib/api/client.ts` and `main.ts` while
finalizing this spec:

- **Silent refresh (Rules 5–6, AC-006)** — a 401 on any non-auth path
  triggers exactly one shared `POST /auth/refresh` (`refreshPromise`
  deduplicates concurrent 401s); on success the original request is retried
  once; on failure `onSessionExpired` clears the session and redirects to
  `/login` (AC-007).
- **Auth paths excluded** — login 401 (bad credentials) and refresh 401
  (session over) never trigger a refresh loop (`isAuthPath`).
- **Cookie handling** — every request uses `credentials: "include"`; the
  HttpOnly refresh cookie is sent automatically on `/auth/refresh` (Rule 2).
- **Error contract (AC-008/AC-009)** — `ApiError` carries `status`, `code`,
  `message`, and `details` from the structured error body; network failures
  map to `NETWORK_ERROR` with a retryable message.
- **Profile after refresh** — the refreshed token replaces only
  `accessToken` in the persisted session; the user profile is preserved
  (matches the `user: null` refresh response above).

## Change History

- Initial Draft created for frontend–backend API integration planning.
- Approved after human review; implementation plan
  `docs/plans/002-frontend-api-integration.md` may proceed.
- Finalized against the implementation: resolved the pagination open
  question (plain-array list responses), documented the verified refresh
  flow and error contract, and recorded the `user: null` refresh response
  handling. No behavioral changes.
- Amended 2026-08-14 (human-approved): added the edit/delete surface —
  `PUT /tasks/{id}`, `PUT /projects/{id}`, `PUT /goals/{id}` (full-replace
  update), `DELETE /projects/{id}`, `DELETE /goals/{id}` (hard delete with
  detach of dependents). Added AC-012 through AC-017. Rule 10, Constraints,
  and Out of Scope updated to allow this scoped amendment only.
