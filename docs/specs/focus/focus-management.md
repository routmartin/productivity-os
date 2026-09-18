# Focus Management

**Status:** Approved

## Purpose

Provide Focus Session recording that allows a Pomodoro-style timer app to track
when a user focuses on a task. The backend records sessions; the client app owns
all timer logic (Pomodoro intervals, breaks), pulls task data, and decides
whether to complete the task afterward.

A recorded session's duration must reflect the time the user was actually
focused. Paused time is not focus time and is excluded from the recorded
duration.

## User Story

As a user, I want to start a focus timer on a task, pause it when interrupted
without that time counting as focus, resume when I return, and have the session
recorded with the time I actually focused.

## Behavior

### Two modes

The backend supports two modes, client's choice:

- **Manual mode:** Start/stop a session without a preset timer. The client
  manages its own timer or no timer at all. `configuredDurationSeconds` is null.
- **Pomodoro mode:** The client sends a configured focus duration (seconds) when
  starting. The server stores it. The client uses this for countdown display.

Both modes record the same session data and support the same pause/resume
behavior; only the presence of a configured duration distinguishes them.

### Client app responsibility

The Pomodoro client:

- Pulls the user's top-priority tasks and Daily Top 3 from the API
- Lets the user select a task to focus on
- Runs the Pomodoro timer locally (work intervals, breaks)
- Calls the backend to start, pause, resume, and end focus sessions
- After a session ends, asks the user "is this task done?" and calls task
  completion API if yes

### Backend responsibility

The backend:

- Records Focus Sessions (start time, end time, task reference)
- Records pause/resume intervals for active sessions
- Derives and stores the active focus duration (wall-clock minus paused time)
- Enforces one active session per user
- Enforces task eligibility (must be IN_PROGRESS, not deleted)
- Provides task list and Top 3 data for the client to pull

### Starting a Focus Session

A user starts a session for an eligible task. The server records:

- The task being focused on
- The server-authoritative start time
- An optional configured focus duration (seconds) — allows the client to store
  the intended Pomodoro length per session

### Pausing and Resuming a Session

While a session is active, the client may pause and resume it any number of
times:

- **Pause** records the server-authoritative pause start.
- **Resume** records the server-authoritative pause end.
- A session has at most one open pause at a time.
- Paused time is never counted toward the session's focus duration.
- Pause/resume applies identically to manual and Pomodoro sessions.

### Active Session

A user may have at most one active Focus Session. Starting another while one is
active is rejected, and a paused session still counts as active. The active
session can be queried so the client knows what is in progress, including
whether it is currently paused and how much time has already been paused.

### Ending a Focus Session

Ending records the server-authoritative end time and closes any open pause at
that instant. Actual duration is the active focus time: elapsed wall-clock time
from start to end minus the total time spent paused, never negative. The client
is responsible for deciding whether to then call task completion.

### Task Independence

A Focus Session does not automatically complete the task. The client explicitly
calls the task completion endpoint when the user confirms.

## Rules

1. Every Focus Session belongs to exactly one authenticated User.
2. A Focus Session is associated with exactly one Task.
3. A user can have at most one active Focus Session at a time. A paused session
   is active for the purposes of this rule. *(amended)*
4. A Focus Session can only be started for a task in INBOX, PLANNED, or
   IN_PROGRESS state.
5. Session start, pause, resume, and end times use server-authoritative UTC
   instants. *(amended: previously "start and end" only)*
6. Ended Focus Sessions remain available as historical records.
7. When a task is deleted or cancelled while a session is active, the session
   auto-ends with the current server time and any open pause is closed at that
   instant. *(amended)*
8. A session may carry an optional configured focus duration (seconds) from the
   client to record the intended Pomodoro interval length.
9. A session records zero or more pause intervals; each interval has a start and
   (once resumed or ended) an end. *(new)*
10. A session has at most one open pause interval at a time. *(new)*
11. Pause is valid only for an active session that is currently running. *(new)*
12. Resume is valid only for an active session that is currently paused. *(new)*
13. A Focus Session's recorded duration is its active focus time: elapsed
    wall-clock time from start to end minus the total paused time, floored at
    zero. *(new)*
14. Ending a paused session is allowed and closes the open pause at the end
    instant. *(new)*
15. Pause state is persisted server-side and survives app termination; clients
    restore it from the API rather than from local memory. *(new)*

## Constraints

1. Persist timestamps as UTC instants per ADR-006.
2. All queries scoped to the authenticated user per ADR-004.
3. One-active-session invariant enforced at application layer.
4. `duration_seconds` on an ended session is the non-negative active focus
   duration; it remains null while the session is active (existing V13
   invariant `ended_at IS NULL OR duration_seconds IS NOT NULL`). *(amended)*
5. Recorded pause intervals are immutable once closed; corrections are out of
   scope. *(new)*

## Acceptance Criteria

### AC-001 — Start Focus Session

Given an eligible task owned by the user, when starting a session, a new active
session is created with server start time.

### AC-002 — One active session *(amended)*

Given a user with an active session — running or paused — when starting a
second session, the request is rejected.

### AC-003 — Ineligible task rejected

Starting a session for a task that is deleted, cancelled, or not owned is
rejected.

### AC-004 — End session *(amended)*

Given an active session, when ending it, a server-authoritative end time is
recorded and any open pause is closed at that instant.

### AC-005 — Duration derived *(amended)*

Given an ended session with pause intervals, when its duration is read, it
equals `(ended_at - started_at) - total paused time`, floored at zero. A session
with no pauses has duration equal to the wall-clock elapsed time.

### AC-006 — Historical records

Ended sessions remain queryable as historical data.

### AC-007 — Auto-end on task delete/cancel *(amended)*

When a task with an active session is deleted or cancelled, the session
auto-ends; if it was paused, the open pause is closed at the auto-end instant
and the active duration is persisted.

### AC-008 — Cross-user isolation *(amended)*

A user cannot view, modify, pause, resume, or end another user's session, and
cannot read another user's pause intervals.

### AC-009 — No implicit completion

Ending a session does not change the task lifecycle.

### AC-010 — Configured duration stored

The client's configured focus duration (seconds) is stored with the session.

### AC-011 — Pause active session *(new)*

Given an active, running session, when the user pauses it, a pause interval is
opened with the server pause time, and the session reports itself as paused.

### AC-012 — Resume paused session *(new)*

Given an active, paused session, when the user resumes it, the open pause
interval is closed with the server resume time, and the session reports itself
as running.

### AC-013 — Pause rejected when not running *(new)*

Given a session that is ended, or active but already paused, when pause is
requested, the request is rejected with a conflict.

### AC-014 — Resume rejected when not paused *(new)*

Given a session that is ended, or active but running, when resume is requested,
the request is rejected with a conflict.

### AC-015 — Active session exposes pause state *(new)*

Given an active session, the active-session response reports whether it is
paused, the open pause start (when paused), and the accumulated paused seconds
of already-closed intervals.

### AC-016 — Multiple pauses accumulate *(new)*

Given an active session paused and resumed several times, the accumulated paused
seconds equal the sum of all closed intervals, and the final duration excludes
all of them.

### AC-017 — End while paused *(new)*

Given an active, paused session, when it is ended, the open pause is closed at
the end instant and the recorded duration excludes the paused span.

## Edge Cases

- **Pause then task deleted/cancelled:** session auto-ends; open pause closes at
  the auto-end instant (AC-007).
- **End while paused:** allowed; open pause closes at end (AC-017).
- **Resume without a matching open pause:** rejected (AC-014).
- **Zero-length pause:** a pause and immediate resume records an interval with
  `ended_at >= started_at`; contributes zero (or negligible) paused time.
- **Repeated pause without resume:** second pause rejected (AC-013).
- **Legacy rows:** ended sessions created before this change keep their stored
  wall-clock `duration_seconds`; no backfill is performed.
- **Session paused indefinitely:** remains active and blocks starting a new
  session until resumed or ended (Open Question 1).
- **Client clock skew:** irrelevant; the client restores pause state from server
  fields and the server owns all instants.

## API Endpoints

| Method | Path                        | Purpose                                        |
| ------ | --------------------------- | ---------------------------------------------- |
| GET    | /api/v1/focus/active        | Get current active session (or 404)            |
| POST   | /api/v1/focus               | Start a session                                |
| POST   | /api/v1/focus/{id}/pause    | Pause the active session *(new)*               |
| POST   | /api/v1/focus/{id}/resume   | Resume the active session *(new)*              |
| POST   | /api/v1/focus/{id}/end      | End the active session                         |
| GET    | /api/v1/focus?page=&size=   | List historical sessions                       |

`FocusSessionResponse` is extended additively with `isPaused: Boolean`,
`pausedAt: Instant?`, and `accumulatedPausedSeconds: Long`. `durationSeconds`
is the active focus duration for ended sessions.

## Out of Scope

- Automatic idle detection or automatic pausing.
- Automatic ending of long-stale paused sessions (see Open Question 1).
- Pause reasons, notes, or categorization.
- Editing or correcting historical sessions or pause intervals.
- Real-time delivery of pause/resume to other devices (still REST polling).
- Pomodoro timer logic, break tracking, and automatic task completion (client
  responsibility).
- Mobile push notifications.

## Dependencies

- User Management
- Task Management
- Daily Top 3 (client pulls priority data)
- ADR-003, ADR-004, ADR-005, ADR-006
- ADR-008 (Focus Session Pause/Resume and Active-Duration Accounting)

## Open Questions

1. Should a session paused for a very long time be reaped automatically? Proposed
   for V1: no — do not silently close user sessions; revisit with usage data.
2. Should the active-session response also return a server-computed
   `activeFocusSeconds` so clients need no clock math on restore? Proposed for
   V1: no — clients derive it; revisit if drift is observed.
3. Should pause intervals be exposed as a sub-resource (for example
   `GET /focus/{id}/pauses`), or only their aggregate? Proposed for V1:
   aggregate only, plus persisted intervals available to analytics.

## Change History

- Initial version: server-as-recorder model; backend records sessions, client
  owns timer logic. Four endpoints, 8 rules, 10 ACs. Duration derived from
  `started_at`/`ended_at`.
- **Approved amendment:** server-side pause/resume with a pause
  interval table and active-duration accounting (ADR-008). Amended AC-002,
  AC-004, AC-005, AC-007, AC-008; added Rules 9–15, Constraint 4, and AC-011
  through AC-017; added `POST /focus/{id}/pause` and
  `POST /focus/{id}/resume`; extended `FocusSessionResponse` with `isPaused`,
  `pausedAt`, `accumulatedPausedSeconds`. Applies to both manual and Pomodoro
  modes. Approved by the human.
