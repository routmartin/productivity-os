# Daily Closeout Ritual ("Daily Rewind")

## Status

Draft

---

## Problem

Modern knowledge workers frequently finish their workday in an ambiguous, unclosed state:
1. **Unresolved Work Debt:** Tasks planned for the day remain incomplete in the workspace, leaving the user with mental residue and uncertainty about what was actually accomplished.
2. **Invisible Accomplishments:** Focus session hours, habit streaks, and completed tasks slip by without reflection or celebration, compounding burnout and planning optimism bias.
3. **Inbox Accumulation:** Quick captures logged throughout the day remain unorganized, creating morning friction when opening the app the next day.
4. **Circadian Bleed:** Without an explicit end-of-day shutdown ritual, work activities overflow into evening recovery hours, directly contributing to bedtime delays and morning fatigue.
5. **Decoupled Telemetry:** The Weekly Review (Spec 012) requires accurate daily completion and rollover telemetry; without intentional daily closeouts, end-of-week analytics must rely on incomplete historical approximations.

---

## Goal

Provide a calm, focused, and deliberate **Daily Closeout Ritual ("Daily Rewind")** that enables users to gracefully conclude their workday in under three minutes:
1. **Evening Trigger:** Automatically suggest the closeout ritual after 18:00 local wall-clock time (or allow manual invocation anytime from the Today workspace).
2. **Step 1 — Wins & Telemetry:** Celebrate today's accomplishments by surfacing checked-off tasks, total focus session time logged, Daily Top 3 achievement, and completed habits.
3. **Step 2 — Unfinished Tasks Sweep:** Provide frictionless 1-click triage for any tasks remaining in `PLANNED` or `IN_PROGRESS` (Roll over to tomorrow, Return to Inbox, or Cancel), plus a 1-click bulk rollover.
4. **Step 3 — Inbox Zero Sweep:** Quickly organize items captured into the Inbox today before shutting down.
5. **Milestone Persistence & Spec 012 Integration:** Record an immutable daily closeout record that feeds directly into the Weekly Review & Progress Analytics engine.

---

## User Stories

- **As a user**, I want an evening prompt on my Today workspace when my workday is winding down, so that I am reminded to close out my open loops.
- **As a user**, I want to see a clear summary of everything I completed and focused on today, so that I can feel a sense of closure and progress.
- **As a user**, I want to triage unfinished planned tasks with a single click per task, so that I don't start tomorrow with yesterday's stale baggage.
- **As a user**, I want to quickly sweep newly captured inbox items, so that my inbox remains clean and manageable.
- **As a user**, I want to complete the ritual with a calm, affirming sign-off, so that I can mentally disconnect from work and preserve my evening recovery.
- **As a user**, I want my daily closeouts to count toward my weekly review consistency metrics, so that my disciplined daily habits are reflected in my long-term progress.

---

## Core Domain Concepts

```text
User
 └── Daily Closeout (User-scoped, one per calendar date)
      ├── Calendar Date (LocalDate in user's IANA timezone)
      ├── Completed At (Instant UTC)
      ├── Summary Telemetry:
      │    ├── Completed Tasks Count
      │    ├── Total Focus Minutes
      │    ├── Top Three Completed (e.g. 2 of 3)
      │    ├── Habit Completions Count
      │    ├── Rolled Over Tasks Count
      │    ├── Returned to Inbox Tasks Count
      │    └── Cancelled Tasks Count
      ├── Notes (Optional evening reflection note)
      └── Downstream Consumer:
           └── Weekly Review & Progress Analytics (Spec 012)
```

---

## Behavior

### 1. Trigger Conditions & Discovery
- **Automatic Evening Banner:** When the user visits the Today workspace, an unobtrusive "Daily Closeout" card appears if:
  - The local wall-clock time in the user's configured IANA timezone is $\ge \text{18:00}$.
  - Today's daily plan contains one or more unfinished tasks (`PLANNED` or `IN_PROGRESS`), OR one or more items were captured into the Inbox today.
  - The daily closeout ritual has not already been completed for today's calendar date.
- **Manual Launch Button:** An explicit "Start Daily Closeout" button is accessible on the Today workspace hero/toolbar at any time, allowing early closeout (e.g., on half-days) or re-opening.
- **Dismissibility & Snooze:** The evening banner can be dismissed with "Not now" (snoozing for 60 minutes) or collapsed without blocking workspace navigation.

### 2. Three-Step Closure Wizard

The ritual opens in a focused, distraction-free modal dialog or overlay ("Calm Command Center" aesthetic):

#### Step 1: Wins & Telemetry (Celebrate Accomplishments)
- Displays all tasks completed today (`completedAt` falling on today's calendar date in user's timezone) with checked green indicators.
- Summarizes deep work: total focus session minutes logged today from `focus_sessions` (e.g., "3h 45m deep focus").
- Displays Daily Top 3 results (e.g. "2 of 3 Top Priorities achieved").
- Displays habit completion badges from the daily schedule (e.g. "Morning Sunlight, 45m Walk, Hydration").
- Provides a calm, positive affirmation acknowledging effort.
- Action: "Next: Review Unfinished Work →".

#### Step 2: Unfinished Tasks Sweep (Resolve Remaining Planned Tasks)
- Displays all tasks scheduled in today's daily plan (`calendar_date = today`) that are still in `PLANNED` or `IN_PROGRESS` state.
- Each row presents three unambiguous 1-click triage actions:
  1. **Roll over to tomorrow:** Adds the task to tomorrow's daily plan (`calendar_date = today + 1`) via `POST /api/v1/daily-plan/{tomorrow}`, carries over the rollover chain, and marks today's plan entry as rolled over.
  2. **Return to Inbox:** Demotes the task from `PLANNED` or `IN_PROGRESS` back to `INBOX` via `POST /api/v1/tasks/{id}/demote`, removing it from today's plan.
  3. **Cancel:** Cancels the task via `POST /api/v1/tasks/{id}/cancellation` with an optional note ("Decided not to do").
- **Bulk Shortcut:** A primary button **"Roll All Remaining to Tomorrow"** allows sweeping all remaining unfinished tasks in a single click.
- When all unfinished planned tasks are triaged, the wizard automatically enables progression to Step 3.

#### Step 3: Inbox Zero Sweep (Triage Today's Captures)
- Surfaces tasks captured into `INBOX` on today's date (`createdAt` falls on today's calendar date).
- If the inbox has zero items captured today, displays a tranquil empty state: *"Inbox is clean — nothing captured today needs organizing."*
- If items exist, presents rapid disposition choices:
  - **Plan for Tomorrow:** Adds to tomorrow's daily plan and transitions task from `INBOX` to `PLANNED`.
  - **Assign Project:** Quick dropdown to connect to an existing active project.
  - **Leave in Inbox:** Keeps task in inbox for later processing without penalty.
  - **Delete / Cancel:** Discards tasks that are no longer relevant.
- Action: **"Complete Closeout"**.

### 3. Closure Confirmation & Sign-Off
- Displays a soothing completion screen:
  - *"Today is complete. Rest well."*
  - Shows final summary chips: `[5 Completed] [3h Focus] [2 Rolled Over] [Inbox Clean]`.
  - Automatically records the `DailyCloseout` record via `POST /api/v1/daily-closeout/{date}`.
  - Button: *"Finish & Return to Today"*.

### 4. Integration with Weekly Review (Spec 012)
- Each completed `DailyCloseout` writes an immutable operational record for that date.
- The Weekly Review Aggregator reads these records to compute:
  - **Daily Closeout Consistency:** Percentage of active days in the week where a closeout ritual was completed (e.g. `6/7 days (86%)`).
  - **Rollover Velocity:** Exact count of tasks rolled over vs completed on their original planned day.
  - **Shutdown Time Tracking:** Correlation between daily closeout completion timestamps and evening bedtime overflow (ADR-006).

---

## Rules

1. **User Isolation:** All daily closeout data and task mutations are strictly isolated to the authenticated user (`CurrentUser.id()`). No cross-user access is permitted.
2. **Timezone Authority:** Calendar date resolution ("today", "tomorrow", and 18:00 cutoff) uses the user's configured IANA timezone via `UserTimezoneService` per ADR-006.
3. **Real API Mutations:** Every triage action in the sweep steps must invoke real server-persisted REST endpoints (`tasksApi.demote`, `tasksApi.cancel`, `dailyPlanApi.plan`). No client-only mock states in production mode.
4. **Rollover Limits:** Rolling over a task from today to tomorrow increments the task's rollover counter in the daily plan chain. If the task has reached the maximum rollover threshold (`MAX_ROLLOVERS = 3`), the user is prompted to reconsider or return the task to the Inbox.
5. **Idempotent Closeout:** Completing the daily closeout more than once for the same calendar date updates the existing `daily_closeouts` record rather than creating duplicate entries.
6. **Non-Destructive Invariant:** Returning an unfinished task to Inbox removes it from today's active daily plan but preserves historical task metadata, estimated duration, and project association.
7. **Quiet Defaults:** The closeout ritual never automatically cancels or deletes tasks without explicit user selection.

---

## Constraints

1. **Duration:** The entire closeout flow must be lightweight and completable in under 3 minutes of focused interaction.
2. **Keyboard Navigation:** The sweep lists must support full keyboard shortcuts (e.g., `r` for rollover, `i` for return to inbox, `c` for cancel, `Enter` to confirm).
3. **Resilience:** If network communication fails during a sweep action, the UI displays clear inline feedback without discarding the user's triage decisions.
4. **Historical Immutability:** Once a calendar date has passed into the past (before today's local date), its closeout record becomes read-only.

---

## Acceptance Criteria

### AC-001 — Evening closeout prompt triggers after 18:00 local time

Given an authenticated user whose local wall-clock time is 18:00 or later,
and today's daily plan contains at least one incomplete task,
and today's closeout ritual has not been completed,
when the user views the Today workspace,
then an evening closeout prompt banner is displayed inviting the user to start the Daily Closeout.

### AC-002 — Manual closeout trigger available anytime

Given an authenticated user on the Today workspace,
when the user clicks the "Daily Closeout" button prior to 18:00,
then the Daily Closeout dialog opens with Step 1 active.

### AC-003 — Step 1 presents objective daily wins and telemetry

Given a user who completed 3 tasks and logged 120 minutes of focus sessions today,
when Step 1 of the Daily Closeout is rendered,
then it displays the 3 completed tasks with checkmarks, indicates 2 hours of focus time,
and displays Daily Top 3 completion status.

### AC-004 — Step 2 surfaces all unfinished planned tasks

Given today's daily plan contains 2 tasks in PLANNED state and 1 task in IN_PROGRESS state,
when the user advances to Step 2,
then all 3 unfinished tasks are presented with individual triage options (Roll over, Inbox, Cancel).

### AC-005 — 1-click rollover to tomorrow

Given an unfinished task in Step 2,
when the user clicks "Roll over to tomorrow",
then the task is added to tomorrow's daily plan, today's plan entry is updated with a rollover remark,
and the task row shows a confirmed rolled-over indicator.

### AC-006 — 1-click return to Inbox

Given an unfinished task in Step 2 in PLANNED or IN_PROGRESS state,
when the user clicks "Return to Inbox",
then the task transitions to INBOX state via the task demotion API and is removed from today's active daily plan.

### AC-007 — 1-click task cancellation

Given an unfinished task in Step 2,
when the user clicks "Cancel",
then the task transitions to CANCELLED state via the task cancellation API and is removed from future active plans.

### AC-008 — Bulk rollover of all unfinished tasks

Given 4 unfinished tasks in Step 2,
when the user clicks "Roll All Remaining to Tomorrow",
then all 4 tasks are scheduled into tomorrow's daily plan in sequence and Step 2 marks all tasks resolved.

### AC-009 — Step 3 quick triage for today's inbox items

Given 2 tasks were captured into the Inbox today,
when the user advances to Step 3,
then both tasks are displayed with quick actions: "Plan for tomorrow", "Assign project", "Keep in inbox", and "Delete".

### AC-010 — Completing closeout persists DailyCloseout milestone

Given all 3 steps of the Daily Closeout are completed,
when the user clicks "Complete Closeout",
then a POST request is sent to `/api/v1/daily-closeout/{date}`, the closeout record is persisted in the database,
and the Today workspace displays a "Daily Closeout Completed" badge.

### AC-011 — Daily closeout feeds Weekly Review telemetry (Spec 012)

Given a user who completed Daily Closeouts on 5 days during an ISO week,
when the Weekly Review for that week is computed via `GET /api/v1/reviews/current`,
then the weekly review metrics include `dailyCloseoutsCompletedCount = 5` and a closeout consistency rate of `71.4%`.

---

## Edge Cases

1. **User has zero planned tasks and zero inbox captures:** The closeout displays Step 1 celebrating any ad-hoc focus sessions or habits, then provides a fast 1-click "Mark day as closed" button.
2. **Rollover limit reached:** If a task in Step 2 has already been rolled over 3 consecutive times (`MAX_ROLLOVERS = 3`), the "Roll over to tomorrow" option is disabled with a hint: *"Rolled over 3 times. Move to Inbox or Cancel to prevent task stagnation."*
3. **Network interruption during sweep:** Triage mutations are executed sequentially; if one fails, the error message appears on that specific row while successful rows remain in their resolved state.
4. **Closeout performed past midnight:** If the user performs closeout at 01:00 AM, the UI prompts: *"Are you closing out yesterday (Nov 11) or today (Nov 12)?"*, resolving to yesterday's date by default.

---

## Out of Scope

- Automated AI execution of triage without user confirmation.
- Recurring task generation during closeout (handled by habit schedule engine).
- Audio narration or ambient background sounds during reflection.
- Cross-user closeout sharing or team leaderboards.

---

## Dependencies

- **Task Management Specification:** `docs/specs/tasks/task-management.md` (task lifecycle, uncompletion, demotion).
- **Tasks & Inbox UI Specification:** `docs/specs/ui/tasks-and-inbox-ui.md` (Undo toast, visual language).
- **Daily Planning Specification:** `docs/specs/planning/daily-planning.md` (daily plan dates, capacity, rollover mechanics).
- **Weekly Review & Progress Analytics Specification:** `docs/specs/progress/weekly-review-and-analytics.md` (Spec 012 consumer of closeout metrics).
- **ADR-003:** Database Persistence (PostgreSQL Flyway migration).
- **ADR-006:** Time and Timezone Handling (`UserTimezoneService`).

---

## Open Questions

- **D1:** Should the daily closeout banner appear strictly at 18:00, or should the trigger time be configurable in user settings (e.g. 17:00–22:00)? *(Recommendation: Default to 18:00 with user override in Settings in a future milestone).*
- **D2:** Should incomplete habits from the daily schedule be offered for triage in Step 2 alongside tasks? *(Recommendation: Focus Step 2 strictly on tasks; display habit check-offs informational in Step 1 to keep closeout under 3 minutes).*

---

## Change History

- Initial Draft created for Option 2: Two-Tier Rewind Engine & Rituals. Defines evening trigger, 3-step closure flow (Wins, Unfinished Sweep, Inbox Zero), 1-click triage actions, and integration into Spec 012 Weekly Review.
