# Task Management

## Status

Draft

## Problem

Users need a reliable way to capture and track actionable work. Other features —
daily planning, Daily Top 3, focus sessions, and progress — all depend on a clear
definition of what a task is, who owns it, and what state it is in. Without a
controlled task lifecycle, those features cannot reason about task state
consistently.

## Goal

Provide a predictable task model: every task is owned by exactly one user,
optionally belongs to one project, and moves through a controlled lifecycle from
capture to completion or cancellation.

## User Story

As a user, I want to capture tasks, organize them into projects, and move them
through a clear lifecycle, so that I can trust the state of my work.

## Behavior

- The user can create a task with a title. Description, project, priority,
  estimated duration, due date, and energy level are optional.
- A task without a project is an Inbox task.
- The user can move a task between Inbox and a project.
- The user can transition tasks through the lifecycle; invalid transitions are
  rejected.
- Completing a task records the completion time.
- Completed is final; cancelled tasks can be reopened and return to Planned.
- Cancelled tasks remain available for historical records.
- The user can delete a task. Deletion is a soft delete: the task is hidden from
  active work, and all of its history is preserved.
- The user can restore a deleted task. Restoring returns the task to the
  lifecycle state it had when it was deleted.
- AI features may suggest lifecycle changes but never apply them without explicit
  user action.

## Lifecycle

States:

- Inbox
- Planned
- In Progress
- Completed
- Cancelled

Allowed transitions:

- Inbox → Planned
- Planned → In Progress
- In Progress → Completed
- Inbox → Cancelled
- Planned → Cancelled
- In Progress → Cancelled
- Cancelled → Planned

Terminal state:

- Completed is final. No transitions out of Completed exist.

Any transition not listed above is invalid and must be rejected.

Deletion and restore:

Deletion is a soft delete and is not a lifecycle state. A Task in any lifecycle
state — including Completed and Cancelled — may be deleted. A deleted Task
retains its underlying lifecycle state and can later be restored to it.

## Rules

1. Every Task belongs to exactly one User. A Task cannot exist without an owning
   User.
2. A Task belongs to zero or one Project. A Task cannot belong to multiple
   Projects.
3. A Task without a Project is an Inbox task.
4. A Task may move from Inbox to a Project and from a Project back to Inbox.
5. A Task must have a title. All other attributes — description, project,
   priority, estimated duration, due date, and energy level — are optional.
6. A Task cannot belong to a Project owned by another User.
7. A User can only view and modify their own Tasks.
8. Lifecycle transitions are limited to the allowed set. Invalid transitions are
   rejected and the Task's state remains unchanged.
9. Completed is final. A Completed Task cannot be reopened or transitioned to any
   other state.
10. A Cancelled Task can be reopened. Reopening returns it to Planned, regardless
    of the state it was cancelled from.
11. When a Task is completed, the system records the completion time.
12. Cancelled Tasks are retained and remain available for historical records.
    Cancelling does not delete the Task.
13. A Task is considered active while it is in Inbox, Planned, or In Progress and
    has not been deleted. Completed, Cancelled, and deleted Tasks are not active.
14. AI must not silently change a Task's lifecycle state. An AI-suggested state
    change takes effect only after explicit user confirmation.
15. Task deletion is a soft delete. A deleted Task is hidden from active work,
    and all of its history is preserved.
16. A deleted Task can be restored. Restoring returns the Task to the lifecycle
    state it had when it was deleted.
17. If a Completed Task is deleted and restored, it remains Completed, and its
    completion time is unchanged.
18. A deleted Task is not considered active and is not considered incomplete,
    regardless of its underlying lifecycle state.
19. Lifecycle transitions apply only to non-deleted Tasks. A deleted Task must be
    restored before it can transition.

## Constraints

1. Tasks must be persisted durably. A task and its lifecycle state must survive
   across sessions.
2. Every task record must be scoped to exactly one owning User. No operation may
   cross user boundaries.
3. Completion time must be recorded as an absolute timestamp. Calendar-day
   attribution of a completion uses the user's configured timezone, consistent
   with the Daily Top 3 specification.

## Acceptance Criteria

### AC-001 — Creating a minimal task

Given a user,
when the user creates a task with only a title,
then the task exists, belongs to that user, has no project, and is in the Inbox
state.

### AC-002 — Creating a task with optional attributes

Given a user,
when the user creates a task with a description, priority, estimated duration,
due date, and energy level,
then the task is created with those attributes stored.

### AC-003 — Tasks always have an owner

Given any task creation,
when the task is created,
then it is associated with exactly one user, and creating a task without an
owning user is rejected.

### AC-004 — Assigning an Inbox task to a project

Given an Inbox task and a project owned by the same user,
when the user assigns the task to the project,
then the task belongs to that project and is no longer an Inbox task.

### AC-005 — Moving a task back to Inbox

Given a task that belongs to a project,
when the user removes the task from the project,
then the task becomes an Inbox task and the task itself still exists.

### AC-006 — Cross-user project assignment rejected

Given a task owned by user A and a project owned by user B,
when user A attempts to assign the task to user B's project,
then the assignment is rejected and the task's project membership is unchanged.

### AC-007 — Users cannot view other users' tasks

Given a task owned by user A,
when user B attempts to view it,
then access is denied.

### AC-008 — Users cannot modify other users' tasks

Given a task owned by user A,
when user B attempts to modify it,
then the modification is rejected and the task is unchanged.

### AC-009 — Inbox to Planned

Given a task in Inbox,
when the user plans the task,
then the task transitions to Planned.

### AC-010 — Planned to In Progress

Given a task in Planned,
when the user starts the task,
then the task transitions to In Progress.

### AC-011 — In Progress to Completed

Given a task in In Progress,
when the user completes the task,
then the task transitions to Completed.

### AC-012 — Completion time is recorded

Given a task,
when the task transitions to Completed,
then a completion timestamp is recorded for the task.

### AC-013 — Inbox to Cancelled

Given a task in Inbox,
when the user cancels the task,
then the task transitions to Cancelled.

### AC-014 — Planned to Cancelled

Given a task in Planned,
when the user cancels the task,
then the task transitions to Cancelled.

### AC-015 — In Progress to Cancelled

Given a task in In Progress,
when the user cancels the task,
then the task transitions to Cancelled.

### AC-016 — Reopening a cancelled task

Given a task in Cancelled,
when the user reopens the task,
then the task transitions to Planned.

### AC-017 — Completed is final

Given a task in Completed,
when any lifecycle transition is attempted (including reopening or cancelling),
then the transition is rejected, the task remains Completed, and its completion
timestamp is unchanged.

### AC-018 — Invalid transition rejected (skipping states)

Given a task in Inbox,
when the user attempts to mark the task Completed directly,
then the transition is rejected and the task remains in Inbox.

### AC-019 — Invalid transition rejected (backwards transition)

Given a task in In Progress,
when the user attempts to return the task to Inbox,
then the transition is rejected and the task remains In Progress.

### AC-020 — Cancelled tasks remain available

Given a task in Cancelled,
when the user views their task records,
then the cancelled task is still available and is marked cancelled.

### AC-021 — Active state definition

Given tasks in Completed or Cancelled states,
when the user's active tasks are queried,
then those tasks are not included.

### AC-022 — AI cannot silently change lifecycle state

Given an AI-generated suggestion to change a task's lifecycle state,
when no explicit user confirmation occurs,
then the task's lifecycle state is unchanged.

### AC-023 — User-confirmed AI suggestion applies

Given an AI-generated suggestion to change a task's lifecycle state,
when the user explicitly confirms the suggestion,
then the transition is applied if it is a valid transition, and rejected
otherwise.

### AC-024 — Tasks persist across sessions

Given a task in any state,
when the user ends the session and starts a new one,
then the task, its attributes, and its lifecycle state are unchanged.

### AC-025 — Deletion hides a task from active work

Given an active task,
when the user deletes the task,
then the task no longer appears in active task views and queries, and the task is
not permanently removed.

### AC-026 — Deletion preserves history

Given a task that has historical records (such as a past Top 3 selection or a
completion record),
when the task is deleted,
then those historical records remain available.

### AC-027 — Restoring returns the previous lifecycle state

Given a task that was In Progress when it was deleted,
when the user restores the task,
then the task is In Progress and appears in active work again.

### AC-028 — A deleted Completed task restores as Completed

Given a Completed task,
when the task is deleted and then restored,
then the task remains Completed and its completion timestamp is unchanged.

### AC-029 — A deleted task is neither active nor incomplete

Given a deleted task in any lifecycle state,
when the user's active or incomplete tasks are queried,
then the deleted task is not included.

### AC-030 — A deleted task cannot transition

Given a deleted task,
when any lifecycle transition is attempted,
then the transition is rejected until the task is restored.

## Edge Cases

- Completing is only possible from In Progress. Attempting to complete a task
  from Inbox or Planned is rejected (AC-018).
- A task cancelled from In Progress reopens to Planned, not back to In Progress
  (Rule 10, AC-016).
- Reopening a completed task is impossible: Completed is final (Rule 9, AC-017).
- A cancelled task is never deleted and remains available for historical records
  (Rule 12, AC-020).
- A task can be deleted from any lifecycle state, including Completed and
  Cancelled. Deletion does not change the underlying lifecycle state (Rule 15).
- A deleted task is hidden from active work and is neither active nor incomplete
  (AC-025, AC-029), but its history is preserved (AC-026) — for example, Daily
  Top 3 historical views can still reference it.
- Restoring a deleted task returns it to the exact lifecycle state it had when
  deleted; a deleted Completed task remains Completed when restored (AC-027,
  AC-028).
- A deleted task cannot transition until it is restored (Rule 19, AC-030).
- The behavior of tasks when their owning project is archived or deleted is
  defined by the Project Management specification, not by this specification.

## Out of Scope

- Permanent (hard) deletion of tasks.
- Recurring tasks, subtasks, attachments, comments, and tags.
- Task sharing or collaboration between users.
- Automatic or AI-applied lifecycle changes without user confirmation.
- Project archival and deletion behavior (owned by the Project Management
  specification).
- Focus tracking and time measurement on tasks (owned by a future Focus Session
  specification).

## Dependencies

- Domain architecture: `docs/architecture/domain.md` (ownership, Inbox concept).
- Project Management specification (project ownership and archived-project
  behavior).
- Daily Planning specification (expected to define how tasks enter Planned and
  what Planned means for a given day).
- Daily Top 3 specification: consumes this lifecycle and the soft-delete
  behavior. Its eligibility rule requires tasks that are active and incomplete
  and not in an archived project (Rules 13 and 18), and its AC-016/AC-017 rely on
  the deletion and history-preservation rules defined here (Rules 15–18).

## Open Questions

- "Inbox" names both a lifecycle state and the project-less membership. Are these
  the same concept? What is the initial lifecycle state of a task created
  directly inside a project?
- Can a task move directly from one project to another, or must it pass through
  Inbox?
- What are the allowed value sets for priority and energy level, and the units
  for estimated duration?
- Are due dates interpreted in the user's configured timezone? May a due date be
  in the past?
- Are tasks expected to synchronize across devices, as Top 3 selections are?

## Change History

- Initial draft created from approved product decisions: single-user ownership,
  zero-or-one project membership with Inbox concept, controlled lifecycle with
  final Completed and reopenable Cancelled, recorded completion time, retained
  cancelled tasks, optional task attributes, cross-user protections, and the AI
  lifecycle constraint.
- Added explicit soft-delete behavior: deletion from any lifecycle state, hidden
  from active work, history preserved, restore to the previous lifecycle state,
  Completed tasks restore as Completed, deleted tasks are neither active nor
  incomplete, and no transitions while deleted. Added Rules 15–19 and
  AC-025–AC-030, resolved the deletion Open Question, and reaffirmed the Daily
  Top 3 reopen conflict.
- Cross-spec reconciliation complete: Daily Top 3 was revised to remove reopening
  of completed tasks, so the reopen conflict is resolved and the corresponding
  Open Question is closed. Confirmed: restoring a deleted task restores only its
  lifecycle state; it does not restore the task's previous Daily Top 3 selection
  (Daily Top 3 Rule 10, AC-027).
