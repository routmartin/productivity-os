# Plan: Focus Pause/Resume and Active-Duration Accounting

## Status

Approved for implementation

## Specification

Primary behavioral source of truth:

- `docs/specs/focus/focus-management.md` (Approved) — amendment per ADR-008.

Acceptance criteria in scope:

- AC-001, AC-002 (amended), AC-003, AC-004 (amended), AC-005 (amended),
  AC-006, AC-007 (amended), AC-008 (amended), AC-009, AC-010
- AC-011, AC-012, AC-013, AC-014, AC-015, AC-016, AC-017 (new)

Supporting decisions and constraints:

- `docs/decisions/ADR-008-focus-pause-and-active-duration.md` (Accepted)
- ADR-003 (persistence, migrations), ADR-004 (user isolation),
  ADR-005 (API conventions), ADR-006 (server-authoritative instants).

## Architecture

The backend remains the session recorder. Active duration becomes:

```text
duration = max(0, (ended_at - started_at) - Σ(pause intervals))
```

Pause intervals are rows in `focus_session_pauses`, at most one open
(`ended_at IS NULL`) per session. Clients own timer display; all pause/resume/end
instants are server-recorded via the injectable `Clock`.

## Step 1 — Migration and persistence

**Status:** IMPLEMENTED

- **Files/modules:**
  - `apps/api/src/main/resources/db/migration/V14__focus_session_pauses.sql`
  - `apps/api/src/main/kotlin/com/productivityos/focus/persistence/FocusSessionPauseEntity.kt`
  - `apps/api/src/main/kotlin/com/productivityos/focus/persistence/FocusSessionPauseRepository.kt`
- **Spec/AC:** Rules 9–10; AC-011, AC-012.
- **Behavior:** table with one-open-pause partial unique index; repository finds
  open pause by session and sums closed intervals.
- **Tests:** covered via service tests.

## Step 2 — Service transitions and duration math

**Status:** IMPLEMENTED

- **Files/modules:** `FocusSessionService.kt`, `focus/domain/FocusSession.kt`.
- **Spec/AC:** Rules 3, 5, 11–15; AC-002, AC-004, AC-005, AC-007, AC-011–AC-017.
- **Behavior:**
  - `pause(userId, id)`: require active + running; open a pause row.
  - `resume(userId, id)`: require active + paused; close the open row.
  - `end(userId, id)`: close any open pause at the end instant; persist
    `durationSeconds` = active seconds.
  - `getActive`/`list`: compute and expose pause state.
  - auto-end: close open pause before persisting duration.
- **Tests:** `FocusSessionServiceTest`.

## Step 3 — DTO and controller

**Status:** IMPLEMENTED

- **Files/modules:** `dto/FocusSessionResponse.kt`, `controller/FocusController.kt`.
- **Spec/AC:** AC-015; API Endpoints section.
- **Behavior:** add `isPaused`, `pausedAt`, `accumulatedPausedSeconds`;
  `POST /focus/{id}/pause` and `POST /focus/{id}/resume`.
- **Tests:** controller covered by service tests + `ApplicationContextTest`.

## Step 4 — iOS client wiring

**Status:** IMPLEMENTED

- **Files/modules:**
  - `ProductivityOS/Models/FocusSession.swift` (add pause fields).
  - `ProductivityOS/Core/Services/FocusService.swift` (`pause`, `resume`).
  - `ProductivityOS/Core/Networking/Endpoint.swift` (paths).
  - `ProductivityOS/Core/Networking/APIDTOs.swift` (endpoint builders).
  - `ProductivityOS/Features/Focus/FocusSessionViewModel.swift` (call API on
    pause/resume; restore paused state; Live Activity already reflects it).
- **Spec/AC:** AC-011, AC-012, AC-015; Rules 14–15.
- **Behavior:** pause/resume become server calls; on failure keep local state
  consistent and surface `syncErrorMessage`; restore maps `isPaused`.
- **Tests:** `FocusServiceTests` additions; build.

## Step 5 — Web

**Status:** deferred (Focus is unrouted/disabled in the web app)

## Tests

Traceability matrix:

| AC | Step | Status |
| -- | ---- | ------ |
| AC-002 | 2 | PASS (`start is rejected while a paused session is active`) |
| AC-005 | 2 | PASS (`end excludes every pause interval`) |
| AC-007 | 2 | PASS (`auto-end on task deletion closes an open pause`) |
| AC-008 | 2 | PASS (`pause is rejected for another user's session`) |
| AC-011 | 2, 4 | PASS (service + `testPauseRecordsServerPause`) |
| AC-012 | 2, 4 | PASS (service + `testResumeRecordsServerResume`) |
| AC-013 | 2 | PASS (`pause is rejected when already paused`) |
| AC-014 | 2 | PASS (`resume is rejected when not paused`) |
| AC-015 | 2, 3, 4 | PASS (`active session exposes pause state`, restore test) |
| AC-016 | 2 | PASS (`resume ... accumulates paused seconds`, `end excludes every ...`) |
| AC-017 | 2 | PASS (`end closes the open pause ...`) |
| AC-004 | 2 | PASS (covered by end tests) |

## Verification

Per AGENTS.md: run backend tests (`./gradlew :apps:api:test`), iOS
`swift test` + `xcodebuild`, review the diff, then the completion report.

Results:

- `./gradlew :apps:api:test --tests "…FocusSessionServiceTest"` — BUILD
  SUCCESSFUL (9 tests).
- `../gradlew :apps:api:test --tests "…ArchitectureTest"` — 9/10 pass; the one
  failure (`AuthController` → `QrAuthChallengeEntity`) is pre-existing and
  unrelated (file untouched).
- `swift test --filter FocusServiceTests` / `FocusViewModelSyncTests` — all 17
  pass.
- `xcodebuild … -scheme ProductivityOS` — BUILD SUCCEEDED (extension embedded).
- Migration `V14` was **not** applied against a real database: Docker is
  unavailable in this environment, so `ApplicationContextTest` (Testcontainers)
  could not run. Verify on a machine with Docker/Postgres before release.

## Pre-Implementation Decisions (resolved)

- **D1:** Pause applies to both manual and Pomodoro modes — resolved.
- **D2:** No inactivity auto-end in V1 — resolved.
- **D3:** Task delete/cancel while paused auto-ends and closes the open pause —
  resolved.
- **D4:** Store pause interval rows, not an accumulated counter — resolved.

## Out of Scope for This Plan

- Web Focus wiring (feature disabled).
- Stale-pause reaping, pause reasons, pause sub-resource endpoint.
- Backfilling historical sessions.

## Change History

- Plan created after ADR-008 (Accepted) and the focus-management amendment
  (Approved) for implementation.
- Implemented Steps 1–4 (backend + iOS). Step 5 (web) deferred because the web
  Focus feature is unrouted/disabled. Backend service tests and iOS focus tests
  pass; V14 migration not verified against a real DB (Docker unavailable).
