# Daily Top 3

## Status

Proposed

## Problem

Users may have many tasks available on a given day, making it difficult to identify
what deserves their primary attention.

## Goal

Help the user identify up to three most important actions for the day.

## User Story

As a user, I want to identify my most important actions today (up to three), so that
I know what deserves my attention.

## Behavior

- The user can select up to three eligible tasks as the Top 3 for a given date.
- The Top 3 is an ordered list: position 1 is the highest priority, position 3 the
  lowest. When no position is specified, a new selection takes the next available
  position.
- The user can add, reorder, and remove selections for today and future dates.
  Past dates are view-only.
- The system displays the Top 3 on the daily dashboard for the viewed date.
  Visual placement and prominence are design concerns and are not specified here.
- Top 3 tasks remain visible while the user works through the day.
- Selections are persisted server-side, associated with the user and the date, and
  are synchronized across the user's devices by the backend.

## Rules

1. A user may have zero to three Top 3 tasks per calendar day.
2. The Top 3 is ordered: positions 1–3 represent priority, with position 1
   highest.
3. When no position is specified, a newly selected task is placed in the next
   available position (the lowest unoccupied position).
4. A task cannot appear more than once in the same day's Top 3. The same task may
   appear in the Top 3 of different dates.
5. Only eligible tasks may be newly selected. A task is eligible when it is active
   and incomplete, has not been deleted, and does not belong to an archived
   project. (Active, incomplete, and deleted are defined by the Task Management
   specification.)
6. When a Top 3 task is completed, it remains in that day's Top 3 at its position,
   is marked completed, and continues to occupy its slot. Completed is a terminal
   lifecycle state: a completed task remains completed and cannot be reopened
   (per the Task Management specification).
7. Unfinished Top 3 tasks do not automatically carry over to the next day. Each
   day's Top 3 is selected explicitly.
8. Removing a task from the Top 3 does not delete the task. Remaining tasks shift
   upward to fill the freed position (for example, removing the task at position 1
   moves positions 2 and 3 up to positions 1 and 2).
9. The Top 3 for today and future dates can be edited (add, reorder, remove). The
   Top 3 for past dates is view-only.
10. If a selected task is deleted, it is immediately removed from the active Top 3
    (today and future dates) and remaining tasks shift upward to fill the freed
    position. Its historical selection is preserved and becomes visible once that
    date is viewed as history: the deleted task is displayed as "Deleted task" at
    its original position. Restoring a deleted task does not re-add it to any
    Top 3; a restored task can be newly selected again while it is eligible.
11. If a selected task belongs to an archived project, the task remains visible in
    that day's existing Top 3.
12. There is no separate Top 3 history feature. Viewing previous dates is the
    history.
13. When a selection is rejected because the Top 3 is full, the user receives
    clear feedback that the Top 3 is full.
14. When a task cannot be selected because it is ineligible, the user receives
    clear feedback explaining why.
15. When viewing a past date, each task's completion state is frozen as it was at
    the end of that calendar day. Completing the task on a later date does not
    change the historical view.

## Constraints

1. A calendar day is 00:00:00–23:59:59 in the user's configured timezone. All date
   attribution for selections uses this definition. If the user later changes
   their configured timezone, existing Top 3 records remain associated with their
   original calendar date.
2. Top 3 selections must be persisted server-side and associated with the user and
   the date.
3. The backend must support multi-device synchronization of Top 3 selections.
   Concurrent edits to the same date's Top 3 are resolved with last-write-wins
   based on server receipt time.

## Known Limitations

- Last-write-wins uses server receipt time: an edit made on an offline device can
  overwrite a newer edit from another device when it reconnects. Accepted for now;
  revisit if conflict handling becomes a priority.

## Acceptance Criteria

### AC-001 — Selecting an eligible task

Given the user has an eligible task that is not in today's Top 3,
when the user selects that task for today's Top 3,
then the task appears in today's Top 3 at the specified position.

### AC-002 — Fourth selection prevented

Given today's Top 3 already contains three tasks,
when the user attempts to add another task for today,
then the task is not added, today's Top 3 is unchanged, and the user receives
clear feedback that the Top 3 is full.

### AC-003 — Completed task remains visible

Given a task is in today's Top 3,
when the user completes that task,
then the task remains in today's Top 3 at its position and is marked completed.

### AC-004 — Completed tasks occupy their slot

Given today's Top 3 contains three tasks and all of them are completed,
when the user attempts to add another task for today,
then the task is not added, today's Top 3 is unchanged, and the user receives
clear feedback that the Top 3 is full.

### AC-005 — Viewing another date

Given a Top 3 selection was saved for a date other than today,
when the user views the dashboard for that date,
then the Top 3 saved for that date is displayed.

### AC-006 — Ordering

Given today's Top 3 contains tasks in positions 1–3,
when the user moves a task to a different position,
then today's Top 3 reflects the new order, with position 1 as the highest priority.

### AC-007 — No duplicates within a day

Given a task is already in today's Top 3,
when the user attempts to select the same task for today again,
then the task is not added a second time.

### AC-008 — Completed tasks cannot be newly selected

Given a task is completed,
when the user attempts to select it for a date's Top 3,
then the task is not added and the user receives clear feedback explaining why the
task cannot be selected.

### AC-009 — Archived-project tasks cannot be newly selected

Given a task belongs to an archived project and is not already in that date's
Top 3,
when the user attempts to select it for that date,
then the task is not added and the user receives clear feedback explaining why the
task cannot be selected.

### AC-010 — Archived-project task remains in existing Top 3

Given a task is in a date's Top 3,
when the project it belongs to is archived,
then the task remains visible in that date's Top 3.

### AC-012 — Removing a task frees its slot without deleting it

Given today's Top 3 contains tasks at positions 1–3,
when the user removes the task at position 1,
then the task no longer appears in today's Top 3, the task itself still exists,
and the remaining tasks shift upward to positions 1 and 2.

### AC-013 — No automatic carry-over

Given a task was in yesterday's Top 3 and is still incomplete,
when the user views today's Top 3,
then the task is not present unless it was explicitly selected for today.

### AC-014 — Future dates are editable

Given the user is viewing a future date,
when the user selects an eligible task for that date's Top 3,
then the task is added to that date's Top 3.

### AC-015 — Past dates are view-only

Given the user is viewing a past date,
when the user attempts to add, remove, or reorder tasks in that date's Top 3,
then the modification is rejected and the saved Top 3 is unchanged.

### AC-016 — Deleted task removed from active Top 3

Given a task is in the Top 3 of today or a future date,
when the task is deleted,
then it is immediately removed from that active Top 3 and remaining tasks shift
upward to fill the freed position.

### AC-017 — Deleted task preserved in historical view

Given a task was selected in the Top 3 for date D,
when the task is deleted and the user views date D's history,
then the historical selection is preserved and the task is displayed as "Deleted
task" at its original position.

### AC-018 — Selections persist across sessions

Given the user has selected a Top 3 for today,
when the user ends the session and starts a new one,
then today's Top 3 is unchanged.

### AC-019 — Multi-device synchronization

Given the user has selected a Top 3 on one device,
when the user opens the daily dashboard on another device,
then the same Top 3 is displayed.

### AC-020 — No tasks exist

Given no tasks exist,
when the user views today's dashboard,
then the Top 3 is displayed as empty and no error occurs.

### AC-021 — Fewer than three tasks exist

Given fewer than three eligible tasks exist,
when the user selects all of them for today,
then today's Top 3 contains fewer than three tasks and this is a valid state.

### AC-022 — Default position

Given today's Top 3 has positions available,
when the user selects an eligible task without specifying a position,
then the task is placed in the next available (lowest unoccupied) position.

### AC-023 — Timezone change preserves date association

Given a Top 3 selection was saved for a calendar date,
when the user changes their configured timezone,
then the saved Top 3 remains associated with its original calendar date.

### AC-024 — Sync conflicts resolve with last-write-wins

Given the same date's Top 3 is edited on two devices,
when both edits are synchronized,
then the edit most recently received by the server wins.

### AC-025 — Historical completion state is frozen (completed later)

Given a task in date D's Top 3 was incomplete at the end of date D,
when the task is completed on a later date and the user views date D,
then the task is displayed as incomplete on date D.

### AC-027 — Restoring a deleted task does not re-add it

Given a task was removed from today's active Top 3 because it was deleted,
when the task is restored,
then the task does not reappear in today's Top 3.

## Edge Cases

- No tasks exist: the dashboard shows an empty Top 3 without error (AC-020).
- Fewer than three eligible tasks exist: the user may select fewer than three;
  this is a valid state (AC-021).
- A task is deleted after being selected: it is immediately removed from the
  active Top 3 and remaining tasks shift upward (AC-016); its historical
  selection is preserved and shown as "Deleted task" at its original position
  once that date is viewed as history (AC-017). Restoring the task later does
  not re-add it to any Top 3 (AC-027).
- A task belongs to an archived project: it remains visible in an existing Top 3
  (AC-010) but cannot be newly selected (AC-009).

## Out of Scope

- AI-generated Top 3 recommendations.
- Automatic priority calculation.
- Calendar integration.
- A separate Top 3 history feature (viewing past dates is the history).
- Visual placement and prominence of the Top 3 display (design concern).

## Dependencies

- Task management specification (`docs/specs/tasks/task-management.md`): source
  of truth for the task lifecycle. It defines "active", "incomplete", and
  "deleted" (its Rules 13–19), makes Completed a terminal state (its Rule 9,
  AC-017), and defines the soft-delete and restore behavior this specification
  relies on (its Rules 15–18).
- Daily planning specification: defines the "daily dashboard".
- Project management specification: defines "archived project" behavior.

These dependencies are acknowledged and do not block this specification from
being Proposed.

## Open Questions

None.

## Change History

- Initial draft created as EXP-001.
- Applied Decision Sheet: defined eligibility, calendar-day semantics, slot
  semantics, ordering, editability by date, deleted/archived task behavior,
  reopen behavior, persistence, and multi-device sync. Added Constraints section,
  resolved edge cases, and added acceptance criteria for every rule.
- Applied final decisions: deleted tasks leave the active Top 3 immediately but
  render as "Deleted task" at their original position in historical view; timezone
  changes do not move existing records; sync conflicts use last-write-wins;
  default position is the next available position; full-Top-3 rejections and
  ineligible selections produce clear user-facing feedback; visual prominence
  deferred to design.
- Resolved remaining product decisions: removal and deletion shift remaining tasks
  upward; historical views freeze completion state at the end of the calendar day;
  same-day deletions become visible once the date is viewed as history; confirmed
  "next available position" means the lowest unoccupied position; last-write-wins
  uses server receipt time (documented as a known limitation); cross-spec terms
  remain non-blocking dependencies. Status changed to Proposed.
- Cross-spec reconciliation with Task Management (lifecycle source of truth):
  removed reopening of completed tasks — Completed is terminal. Deleted Rule 7
  (reopen) and AC-011/AC-026; renumbered Rules 8–16 to 7–15; Rule 6 now states
  completed tasks remain completed; Rule 15 no longer references reopening.
  Eligibility explicitly excludes deleted tasks (Rule 5). Restoring a deleted
  task does not re-add it to any Top 3 (Rule 10, new AC-027). Dependencies now
  name Task Management and Project management explicitly. Status remains
  Proposed.
