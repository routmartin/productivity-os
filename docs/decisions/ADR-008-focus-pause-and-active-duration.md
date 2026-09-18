# ADR-008: Focus Session Pause/Resume and Active-Duration Accounting

## Status

Accepted

## Context

The approved Focus Management specification (`docs/specs/focus/focus-management.md`)
defines the backend as a session recorder and makes no pause concept available:
a session has `started_at` and `ended_at`, and duration is derived from those
two instants. The current implementation follows this literally
(`FocusSessionService.kt`):

```kotlin
entity.durationSeconds = entity.endedAt!!.epochSecond - entity.startedAt.epochSecond
```

Both clients, however, expose a Pause/Resume control:

- iOS: `FocusSessionViewModel.pauseFocus()/resumeFocus()` update a local,
  timestamp-based timer and never call the API.
- Web: `features/focus/store.ts` sets a local `paused` state and stops its timer.

Because paused time is never communicated to the server, the recorded
`duration_seconds` is wall-clock time from start to end, **including every
paused span**. Consequences observed:

- A 25-minute session paused for 20 minutes is recorded as ~45 minutes.
- The iOS completion screen (which shows active elapsed time, pauses excluded)
  disagrees with the value later returned by `GET /focus` history.
- The value that feeds any future analytics ("real focus time", learning from
  behavior) is inflated and not trustworthy.
- Restoring a session after app termination resumes it as **running** even if
  it was paused, and the wall-clock drift persists.

The product goal is that a recorded Focus Session duration equals the time the
user was actually focused, in both manual and Pomodoro modes, and that this
remains correct across backgrounding, force-quit, and multiple devices.

This is an architectural change: it adds lifecycle transitions to a backend
record, a new persisted child entity, and it changes the meaning of
`duration_seconds`. Per ADR-001 and `AGENTS.md`, it requires an approved spec
amendment and an ADR before implementation.

## Decision Drivers

- **Accuracy**: recorded duration must equal active focus time, excluding all
  paused intervals.
- **Server authority**: start/end/pause/resume instants come from the server
  clock via the injectable `Clock` (ADR-006). Client clocks are not trusted.
- **Survivability**: pause state must survive app backgrounding, force-quit,
  and cross-device use — so it cannot live only in client memory.
- **Auditability**: the product intends to learn from focus behavior; the pause
  pattern itself is useful data, not just its total.
- **Consistency**: iOS and Web must share one model; the same session must read
  identically from `GET /focus/active` and `GET /focus`.
- **Both modes**: manual and Pomodoro sessions behave identically here.
- **Reversibility and safety**: never silently drop or reinterpret existing
  ended sessions; existing rows and their durations remain valid.
- **Simplicity for V1**: no real-time push, no idle detection, no scheduler.

## Options

### Where active duration is computed

- **Option A — Client-supplied duration on `end`.** Accept an optional
  `durationSeconds` in the end request and persist it.
- **Option B — Server pause/resume with an accumulated counter.** Add
  `accumulated_paused_seconds`; derive active duration from start/end/paused.
- **Option C — Server pause/resume with a pause-interval table.** Persist each
  pause as `(session_id, started_at, ended_at)`; derive active duration from
  start, end, and the union of pause intervals.

### Pause state representation while active

- **Option A — Flag only** (`is_paused` boolean, no timestamp).
- **Option B — Open-pause timestamp** (`paused_at` on the session, null when
  running).
- **Option C — Open-pause row** in the pause table (`ended_at IS NULL`).

## Decision

1. **Adopt Option C**: persist pauses as interval rows in a new
   `focus_session_pauses` table. Active duration is:
   `(ended_at - started_at) - Σ(pause intervals)`, floored at 0 seconds.
2. **The open pause is the row with `ended_at IS NULL`**, so there is at most
   one open pause per session (enforced by a partial unique index).
3. **Add `POST /api/v1/focus/{id}/pause` and `POST /api/v1/focus/{id}/resume`.**
   Both return the updated `FocusSessionResponse`. Both are valid only while the
   session is active (`ended_at IS NULL`). Pause requires the session to be
   running; resume requires it to be paused. Invalid transitions are rejected
   with `409 CONFLICT` (via `require`, matching existing behavior).
4. **`duration_seconds` keeps its V13 role and invariant**, but its meaning is
   narrowed to **active focus seconds** (pauses excluded). It stays `null` while
   the session is active and non-null once ended. The existing
   `focus_sessions_duration_when_ended_chk` constraint is preserved.
5. **`FocusSessionResponse` gains pause-state fields** so clients can render and
   restore paused sessions without trusting their own clock:
   - `isPaused: Boolean` — active session currently paused.
   - `pausedAt: Instant?` — open pause start, null when running or ended.
   - `accumulatedPausedSeconds: Long` — total of **closed** pause intervals
     (excludes the currently open pause).
   `durationSeconds` remains the final active duration for ended sessions.
6. **Ending a paused session is allowed** and closes the open pause at the end
   instant.
7. **Auto-end (task deleted or cancelled) closes any open pause** at the
   auto-end instant and persists active duration.
8. **Paused sessions remain active indefinitely; no inactivity auto-end in V1.**
   One-active-session (Rule 3) counts a paused session as active. Stale-pause
   reaping is a future enhancement, not part of this change.
9. **Both manual and Pomodoro modes support pause/resume with identical
   semantics.**
10. **Server authority**: all pause/resume/end instants are recorded from the
    injectable `Clock` (ADR-006); no client timestamps are accepted.
11. **Ownership** is checked through the session's `user_id` (ADR-004); the
    pause table has no independent user scope.

## Reasoning

- **Correct across lifecycle events (Option C over A/B).** Because pause
  intervals are persisted server-side, a force-quit, a device switch, or a
  network drop cannot lose the pause. Option A loses the pause whenever the
  client does not survive to `end`, and it makes a client value authoritative
  over a server record, violating ADR-006.
- **Auditable and analytics-ready (Option C over B).** The pause pattern
  (frequency, timing, duration) is exactly the kind of behavioral signal the
  product wants to measure. A single counter discards it irreversibly; interval
  rows keep it and let the counter be derived.
- **Multi-pause correctness.** Interval rows handle any number of pauses with no
  drift and no double counting; a single counter requires care to start/stop
  exactly once per transition.
- **Backward compatibility.** Existing ended rows keep their stored
  `duration_seconds` and are untouched; only new sessions and sessions that gain
  pauses use the new math. No backfill is required (pauses cannot be
  reconstructed retroactively, and must not be invented).
- **Consistency.** One representation serves `active`, `end`, and `list`; iOS,
  Web, and the macOS companion read the same fields.

## Storage Model

New migration `V14__focus_session_pauses.sql`:

```sql
CREATE TABLE focus_session_pauses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES focus_sessions(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,
    CONSTRAINT focus_session_pauses_interval_chk
        CHECK (ended_at IS NULL OR ended_at >= started_at)
);

CREATE UNIQUE INDEX idx_fsp_session_open
    ON focus_session_pauses (session_id)
    WHERE ended_at IS NULL;

CREATE INDEX idx_fsp_session_id ON focus_session_pauses (session_id);
```

`focus_sessions` is unchanged except for the narrowed meaning of
`duration_seconds`; the V13 constraint and column remain.

## API Changes (verified against `FocusController` / DTOs)

| Method | Path                       | Change |
| ------ | -------------------------- | ------ |
| POST   | `/api/v1/focus/{id}/pause` | New. Pauses an active running session. |
| POST   | `/api/v1/focus/{id}/resume`| New. Resumes an active paused session. |
| GET    | `/api/v1/focus/active`     | Response adds `isPaused`, `pausedAt`, `accumulatedPausedSeconds`. |
| POST   | `/api/v1/focus/{id}/end`   | Now computes active duration; closes an open pause. |
| GET    | `/api/v1/focus?page=&size=`| `durationSeconds` is now active focus time. |

No change to `StartFocusRequest`. `FocusSessionResponse` is extended additively,
so existing clients keep working.

## Consequences

### Positive

- Recorded duration equals real focus time, in both modes, across devices and
  relaunches.
- iOS completion and server history now agree.
- Pause behavior becomes first-class data for future analytics.
- Server remains the single source of truth for all instants.

### Negative

- New table, endpoints, DTO fields, and client wiring in iOS and Web.
- More moving parts in `end` and auto-end (must close an open pause reliably).
- A paused session blocks starting another (Rule 3) until the user resumes or
  ends it; acceptable for V1, tracked as an Open Question below.
- Historical sessions keep wall-clock durations (not backfilled); history is
  therefore mixed until new sessions accumulate.

## Rejected Alternatives

- **Client-supplied duration on `end` (Option A):** loses the pause on app
  termination and makes the client authoritative for a server record; conflicts
  with ADR-006.
- **Accumulated counter only (Option B):** discards the pause pattern, is more
  error-prone across multiple pauses, and offers no audit trail.
- **`is_paused` boolean only (sub-option A):** cannot compute duration or
  restore an open pause without also storing its start.
- **Auto-end stale paused sessions in V1:** adds a scheduler and silently closes
  user sessions; deferred pending product input.
- **Backfilling existing rows:** pause history was never captured and cannot be
  reconstructed; inventing it would corrupt historical truth.

## Open Questions

- Should paused sessions be reaped automatically (for example, auto-end a
  session paused for more than N hours)? Proposed: no in V1; revisit with usage
  data.
- Should `GET /focus/active` also return server-computed
  `activeFocusSeconds` to remove client clock math on restore? Proposed: keep
  deriving on the client for V1; revisit if drift is observed.
- Should pause reasons or notes be captured? Proposed: out of scope.
- Should the pause table also be user-scoped explicitly for query convenience?
  Proposed: no; it is reached through the owned session (ADR-004).

## Related Specifications and ADRs

- `docs/specs/focus/focus-management.md` (amended by this ADR)
- `docs/decisions/ADR-001-sdd-workflow.md`
- `docs/decisions/ADR-003-database-persistence.md`
- `docs/decisions/ADR-004-authentication-user-isolation.md`
- `docs/decisions/ADR-005-api-architecture.md`
- `docs/decisions/ADR-006-time-and-timezone.md`
- `docs/specs/focus/macos-focus-companion.md` (no Pause concept today)
