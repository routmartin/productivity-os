# Focus Management

**Status:** Proposed

## Purpose

Provide Focus Session recording that allows a Pomodoro-style timer app to track
when a user focuses on a task. The backend records sessions; the client app owns
all timer logic (Pomodoro intervals, breaks), pulls task data, and decides
whether to complete the task afterward.

## User Story

As a user, I want to start a focus timer on a task, have the session recorded,
and when the timer ends decide whether the task is done.

## Behavior

### Two modes

The backend supports two modes, client's choice:

- **Manual mode:** Start/stop a session without a preset timer. The client
  manages its own timer or no timer at all. `configuredDurationSeconds` is null.
- **Pomodoro mode:** The client sends a configured focus duration (seconds) when
  starting. The server stores it. The client uses this for countdown display.

Both modes record the same session data; only the presence of a configured
duration distinguishes them.

### Client app responsibility

The Pomodoro client:
- Pulls the user's top-priority tasks and Daily Top 3 from the API
- Lets the user select a task to focus on
- Runs the Pomodoro timer locally (work intervals, breaks)
- Calls the backend to start/end focus sessions
- After a session ends, asks the user "is this task done?" and calls task
  completion API if yes

### Backend responsibility

The backend:
- Records Focus Sessions (start time, end time, task reference)
- Enforces one active session per user
- Enforces task eligibility (must be IN_PROGRESS, not deleted)
- Provides task list and Top 3 data for the client to pull

### Starting a Focus Session

A user starts a session for an eligible task. The server records:
- The task being focused on
- The server-authoritative start time
- An optional configured focus duration (seconds) — allows the client to store
  the intended Pomodoro length per session

### Active Session

A user may have at most one active Focus Session. Starting another while one is
active is rejected. The active session can be queried so the client knows what
is in progress.

### Ending a Focus Session

Ending records the server-authoritative end time. Actual duration is derived
from start and end timestamps. The client is responsible for deciding whether
to then call task completion.

### Task Independence

A Focus Session does not automatically complete the task. The client explicitly
calls the task completion endpoint when the user confirms.

## Rules

1. Every Focus Session belongs to exactly one authenticated User.
2. A Focus Session is associated with exactly one Task.
3. A user can have at most one active Focus Session at a time.
4. A Focus Session can only be started for a task in IN_PROGRESS state.
5. Session start and end times use server-authoritative UTC instants.
6. Ended Focus Sessions remain available as historical records.
7. When a task is deleted or cancelled while a session is active, the session
   auto-ends with the current server time.
8. A session may carry an optional configured focus duration (seconds) from the
   client to record the intended Pomodoro interval length.

## Constraints

1. Persist timestamps as UTC instants per ADR-006.
2. All queries scoped to the authenticated user per ADR-004.
3. One-active-session invariant enforced at application layer.

## Acceptance Criteria

### AC-001 — Start Focus Session

Given an IN_PROGRESS task owned by the user, when starting a session, a new
active session is created with server start time.

### AC-002 — One active session

Starting a second session while one is active is rejected.

### AC-003 — Ineligible task rejected

Starting a session for a task not in IN_PROGRESS, deleted, or not owned is
rejected.

### AC-004 — End session

An active session can be ended. Records server-authoritative end time.

### AC-005 — Duration derived

Session duration is derived from start and end timestamps.

### AC-006 — Historical records

Ended sessions remain queryable as historical data.

### AC-007 — Auto-end on task delete/cancel

When a task with an active session is deleted or cancelled, the session
auto-ends.

### AC-008 — Cross-user isolation

A user cannot view, modify, or end another user's session.

### AC-009 — No implicit completion

Ending a session does not change the task lifecycle.

### AC-010 — Configured duration stored

The client's configured focus duration (seconds) is stored with the session.

## API Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | /api/v1/focus/active | Get current active session (or 404) |
| POST | /api/v1/focus | Start a session |
| POST | /api/v1/focus/{id}/end | End the active session |
| GET | /api/v1/focus?page=&size= | List historical sessions |

## Out of Scope

- Pomodoro timer logic (client responsibility).
- Break tracking (client responsibility).
- Automatic task completion (client calls existing task API).
- Pomodoro configuration (client stored).
- WebSocket/real-time sync (REST polling for V1).
- Mobile push notifications.

## Dependencies

- User Management
- Task Management
- Daily Top 3 (client pulls priority data)
- ADR-003, ADR-004, ADR-005, ADR-006

## Change History

- Revised to server-as-recorder model: backend records sessions, client owns
  timer logic. Removed pomodoro configuration, break tracking, auto-completion
  from backend scope. Simplified to 4 endpoints, 8 rules, 10 ACs.
