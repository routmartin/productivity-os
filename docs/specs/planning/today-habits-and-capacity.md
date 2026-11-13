# Today Habits, Inline Quick Capture, and Capacity Telemetry

## Status
Approved

## Problem

The Today workspace (`/today`) serves as the primary daily command center for Productivity OS users. While Milestones 1 and 2 re-established the dual-rail workspace layout, Top 3 focus execution, and active focus timer controls, three critical operational loops remain disconnected:

1. **Habit Tracking Disconnect**: Recurring daily routines (hydration, workouts, meditation, evening wind-down) defined in the Circadian Link-Map Daily Schedule (`scheduleStore`) are absent from the Today view. Users must leave Today and navigate to `/schedule` to check off daily habits. Because habits define chronological anchors and directly influence daily energy and the bedtime projection, omitting them from Today fractures the user's daily trajectory.
2. **High-Friction Task Capture**: When a thought or unplanned task occurs during the day, capturing it from Today requires either opening a modal dialog (`NewTaskDialog` via global shortcut `'c'`) or navigating to `/inbox` or `/tasks`. A modal overlay interrupts focus, blurs the screen, and creates cognitive friction for rapid, ephemeral captures.
3. **Missing Capacity & Bedtime Telemetry**: The backend calculates focus capacity hours and daily schedule overflow minutes, but Today provides no real-time visual capacity meter. Users cannot see whether their planned workload fits their available energy limit or whether delays are pushing back their target bedtime. Furthermore, the AI Briefing displays static task counts without dynamic telemetry regarding capacity buffers, over-allocation warnings, or sleep trajectory.

## Goal

Transform the Today workspace into an integrated, real-time command cockpit by:
1. Embedding scheduled habits directly within the Today timeline with 1-tap toggling, streak indicators, and instant bedtime projection recalculation.
2. Providing a fast, low-friction inline capture bar directly in the Today workspace with shortcut `<kbd>c</kbd>` focusing, capturing tasks into Inbox without modal interruption.
3. Rendering a dynamic Capacity & Bedtime Telemetry gauge with contextual AI Briefing insights reflecting buffer remaining, over-capacity warnings, and bedtime trajectory.

## User Stories

- **US-1 (Habit Stacking & Execution)**: As a user reviewing my day on Today, I want to see my daily habits alongside scheduled work and toggle them with a single click, so that I keep my streaks alive and immediately see how my routines influence my bedtime.
- **US-2 (Inline Quick Capture)**: As a user working on Today, I want to press `c` to instantly focus an inline capture input and hit Enter to record a task, so that I can capture thoughts without modal popups interrupting my flow.
- **US-3 (Capacity & Energy Telemetry)**: As a user planning and executing my day, I want a visual capacity meter and bedtime trajectory on Today, so that I can avoid over-commitment and protect my circadian recovery.

---

## Behavior

### 1. Unified Schedule & Habit Timeline (`ScheduleTimeline.vue`)
- The timeline on Today displays both planned focus tasks and recurring habit nodes for the active calendar date.
- Habit entries display:
  - Habit title and scheduled or recommended time slot (e.g. `06:45`, `07:00`, `21:30`).
  - Habit icon (e.g. `Droplets`, `Dumbbell`, `BookOpen`).
  - Streak pill with flame icon and day count (e.g. `🔥 12d`).
  - Interactive 1-tap completion toggle button / checkbox.
- Toggling a habit immediately updates its local state (checked/strike-through, incremented/decremented streak count).
- Toggling invokes `scheduleStore.toggleHabit(habitId)` to persist to the backend (`POST /api/v1/schedule/habits/{id}/toggle`) and updates the schedule graph's `overflowMinutes` and `projectedBedtime`.
- If server persistence fails, the UI rolls back to the previous snapshot and displays a non-blocking toast/error indicator.

### 2. Inline Quick Capture on Today (`QuickCapture.vue` & `TodayPage.vue`)
- An inline quick capture input bar is rendered directly within the Today main workspace (adjacent to Recent Activity).
- Displays a visual shortcut badge `<kbd class="kbd tnum">c</kbd>` and clear placeholder text: `"Capture a task or thought... (Press Enter to save)"`.
- When an authenticated user is on the Today page and presses `'c'` (without `Cmd`, `Ctrl`, or `Alt`), keyboard focus immediately jumps directly into this inline input field, bypassing the global modal `NewTaskDialog`.
- Pressing `Enter` with valid trimmed text:
  - Dispatches `tasksStore.addTask({ title, status: 'INBOX' })`.
  - Clears the inline input immediately.
  - Appends the new task to the Recent Activity list with `kind: 'created'`.
- Pressing `Escape` while focused clears or blurs the input.
- Submissions with empty or whitespace-only strings are rejected.

### 3. Capacity & Bedtime Energy Telemetry (`CapacityTelemetryCard.vue` & `AiBriefing.vue`)
- A dedicated telemetry card is mounted in the right context rail of Today, presenting:
  - **Focus Capacity Gauge**: Visual ratio bar comparing planned focus minutes (`todayStore.plan.plannedMinutes`) against daily focus capacity (`todayStore.plan.focusCapacityMinutes`, e.g. "4.5h / 6.0h planned").
  - **Buffer / Over-Capacity State**:
    - *Under capacity / Balanced*: Displays remaining focus buffer (e.g. "+1.5h buffer remaining") in neutral/accent tone.
    - *Over capacity*: Displays warning badge (e.g. "Over capacity by 45m") in warning/danger tone when planned minutes exceed capacity limit.
  - **Bedtime Trajectory**:
    - Displays target bedtime (e.g. `22:30`) and projected bedtime (`projectedBedtime`).
    - When `scheduleStore.overflowMinutes > 0`, highlights bedtime delay (e.g. `⚠️ Bedtime shifts by +30m to 23:00`).
    - When `overflowMinutes === 0`, displays `✓ On track for 22:30 bedtime`.
  - **Habit Completion Ratio**: Shows completed vs total habits for the day (e.g. `3 of 5 habits completed`).
- **AI Briefing Telemetry Synthesis**:
  - The `AiBriefing.vue` subline synthesizes capacity and bedtime telemetry into clear guidance:
    - Normal: `"You have 1.5h buffer remaining today. 3 of 5 habits completed."`
    - Over capacity: `"Schedule is over capacity by 45m. Bedtime projected to slip to 23:15."`
  - The CTA button dynamically adapts: `"Plan My Day"`, `"Review Schedule"`, or `"Adjust Capacity"`.

---

## Rules

1. **Rule 1 — Single Source of Truth for Schedule Habits**: Habits displayed on Today must originate from `scheduleStore.graph.nodes` (where `type === 'habit'`) to prevent state divergence between `/today` and `/schedule`.
2. **Rule 2 — Optimistic Habit Toggling with Safe Rollback**: Toggling a habit must immediately update local UI state (completed status, streak increment/decrement) and recalculate bedtime projection before awaiting server confirmation. If the network request fails, state must revert to its exact prior snapshot.
3. **Rule 3 — Shortcut Delegation on Today**: When the user is active on the `/today` route and presses `'c'` outside an interactive form target, the shortcut MUST focus the inline Quick Capture input rather than opening the global `NewTaskDialog` modal.
4. **Rule 4 — Non-Blocking Task Capture**: Creating an inline task on Today must never trigger full-page reloads, route changes, or blocking overlays. Captured items default to `status: 'INBOX'`.
5. **Rule 5 — Invariant Bedtime Projection**: When `overflowMinutes > 0`, the telemetry gauge and briefing must clearly communicate the projected bedtime delay. The system must not silently truncate or drop overflow minutes.
6. **Rule 6 — Endpoint Contract Conformance**: All habit and schedule operations must conform strictly to verified backend endpoints in `ScheduleController.kt` (`GET /api/v1/schedule/{date}`, `POST /api/v1/schedule/habits/{id}/toggle`) and `DailyPlanController.kt` (`GET /api/v1/daily-plan/{date}/capacity`).

---

## Constraints

- **C-1**: Desktop & responsive container compatibility — all new components must support container queries down to 640px workspace width without horizontal overflow or CLS.
- **C-2**: Timezone-correct ISO date formatting matching the user's configured profile timezone (ADR-006).
- **C-3**: Preview states support — components must honor `?preview=loading|error|empty` for deterministic visual review and testing.

---

## Acceptance Criteria

### AC-001 — Scheduled Habits Rendered in Today Timeline
Given an authenticated user on the Today page (`/today`) with scheduled daily habits,  
When the Today workspace finishes loading,  
Then `ScheduleTimeline.vue` displays habit entries alongside scheduled tasks, showing habit title, scheduled time, icon, and streak badge (e.g. `🔥 12d`).

### AC-002 — 1-Tap Habit Completion Toggle
Given a pending habit displayed in the Today timeline with a streak of 12 days,  
When the user clicks the habit completion toggle button,  
Then the habit is immediately marked as completed, its streak updates to `🔥 13d`, and `scheduleStore.toggleHabit` is called.

### AC-003 — 1-Tap Habit Unchecking
Given an already completed habit displayed in the Today timeline with a streak of 13 days,  
When the user clicks the habit toggle button again,  
Then the habit completion is cleared, its streak decrements back to `🔥 12d`, and the pending state is restored.

### AC-004 — Dynamic Bedtime Recalculation on Habit Toggle
Given a schedule where habit completion or delay affects the daily timeline,  
When a habit is toggled on Today,  
Then `scheduleStore.recalculateBedtime()` recalculates projected bedtime and overflow minutes, updating the bedtime telemetry display immediately.

### AC-005 — Optimistic Rollback on Server Error
Given a user toggling a habit on Today,  
When the backend API call `POST /api/v1/schedule/habits/{id}/toggle` fails with a network or server error,  
Then the habit completion state, streak count, and bedtime projection revert to their exact state prior to the toggle, and an error message is surfaced.

### AC-006 — Inline Quick Capture Presence & Hint
Given an authenticated user viewing the Today page,  
When the main workspace is rendered,  
Then an inline Quick Capture input is visible with placeholder `"Capture a task or thought... (Press Enter to save)"` and a `<kbd>c</kbd>` shortcut hint.

### AC-007 — Single-Key 'c' Shortcut Focuses Inline Capture
Given an authenticated user on `/today` with no active modal or input focus,  
When the user presses `'c'` on their keyboard,  
Then keyboard focus immediately moves into the inline Quick Capture input, and the global `NewTaskDialog` modal does NOT open.

### AC-008 — Successful Inline Task Capture
Given an active inline Quick Capture input on Today containing the text `"Prepare quarterly budget review"`,  
When the user presses `Enter` or clicks the Add button,  
Then a new task with title `"Prepare quarterly budget review"` is created with `status: 'INBOX'`, the input field is cleared, and the item appears in the Recent Activity feed as `"Created new task “Prepare quarterly budget review”"`.

### AC-009 — Whitespace-Only Capture Guard
Given an inline Quick Capture input containing only spaces or empty string,  
When the user presses `Enter` or attempts to submit,  
Then no task is created, no API call is made, and the submit button remains disabled.

### AC-010 — Capacity & Energy Telemetry Ratio Display
Given a daily plan with `plannedMinutes = 270` (4.5h) and `focusCapacityMinutes = 360` (6.0h),  
When viewing the Capacity Telemetry Card on Today,  
Then the gauge displays `"4.5h / 6.0h planned"`, a 75% filled visual ratio bar, and a remaining buffer indicator `"+1.5h buffer remaining"`.

### AC-011 — Over-Capacity Warning State
Given a daily plan where `plannedMinutes = 420` (7.0h) exceeds `focusCapacityMinutes = 360` (6.0h),  
When viewing the Capacity Telemetry Card on Today,  
Then the card displays a warning status with tone `tone-warning` or `tone-danger` and text `"Over capacity by 60m"`.

### AC-012 — Bedtime Trajectory Telemetry
Given a schedule with `targetBedtime = "22:30"` and `overflowMinutes = 45`,  
When viewing the Capacity Telemetry Card on Today,  
Then the card displays `"Bedtime shifts by +45m to 23:15"` with a warning badge.

### AC-013 — Dynamic AI Briefing Synthesis
Given updated capacity and bedtime telemetry with `overflowMinutes = 45`,  
When the AI Briefing computes its dynamic insight,  
Then the briefing subline reflects the schedule overflow/bedtime slip warning and updates its CTA to `"Review Schedule"`.

### AC-014 — Deterministic Preview States
Given the Today page loaded with query parameter `?preview=empty`,  
When the components render,  
Then the schedule timeline renders an empty schedule state, the capacity telemetry reflects zero planned minutes with default 6h capacity, and Quick Capture remains ready for input.

---

## Edge Cases

1. **User with No Habits Defined**: Timeline renders scheduled tasks without error; habit completion ratio in telemetry card shows `"No daily habits scheduled"`.
2. **Habit with 0 Streak**: Toggling completed moves streak to 1; unchecking returns streak to 0 (cannot drop below 0).
3. **Rapid Toggling / Debounce**: User rapidly clicking habit toggle button does not trigger duplicate concurrent requests; state updates optimistically and syncs cleanly.
4. **Offline / Network Disconnection**: If the user captures an inline task or toggles a habit while offline, the action is handled gracefully according to the repository's mock/offline mode fallback.
5. **Global 'c' on Non-Today Pages**: When on `/tasks`, `/inbox`, `/projects`, etc., pressing `'c'` continues to open the global `NewTaskDialog` modal as specified in `task-creation-shortcut.md`.

---

## Out of Scope

- Creating or editing new habit definitions on Today (habit creation and schedule structural editing remain on `/schedule`).
- Reordering habits or changing habit time slots from Today (performed on `/schedule`).
- Full calendar sync (Google/Outlook calendar bi-directional sync is addressed in a separate calendar integration spec).

---

## Dependencies

- `docs/specs/planning/daily-schedule-linkmap.md` (circadian graph model, habit nodes, bedtime calculation)
- `docs/specs/ui/task-creation-shortcut.md` (global 'c' shortcut rules and keyboard guards)
- `docs/specs/ui/productivity-os-visual-system.md` (Today dual-rail layout, card standards, visual tokens)
- `apps/api/src/main/kotlin/com/productivityos/schedule/controller/ScheduleController.kt` (`/api/v1/schedule`)
- `apps/api/src/main/kotlin/com/productivityos/dailyplan/controller/DailyPlanController.kt` (`/api/v1/daily-plan`)

---

## Open Questions

- **D1 (Shortcut Precedence on Today)**: When on Today, should pressing `'c'` focus the inline Quick Capture input exclusively?
  - *Current Decision (Proposed)*: Yes. Pressing `'c'` on `/today` focuses the inline capture input directly. Users who wish to open the full modal dialog with advanced metadata (project, goal, priority, due date) can use `Shift+C` or click the New Task button.
- **D2 (Timeline Integration Presentation)**: Should habits and tasks be merged into a single chronological timeline list, or separated into distinct sub-sections?
  - *Current Decision (Proposed)*: Unified chronological timeline inside `ScheduleTimeline.vue`, with distinct visual pill styling (`Habit` vs `Task`) and habit-specific 1-tap toggle controls.
- **D3 (Capacity Card Placement)**: Should Capacity & Bedtime Telemetry be a separate card in the right rail or combined with `DailySummaryCard.vue`?
  - *Current Decision (Proposed)*: Mounted as a dedicated `CapacityTelemetryCard.vue` in the right rail directly above `DailySummaryCard.vue`, ensuring high visibility while keeping `DailySummaryCard` focused on focus session metrics.

---

## Change History

- **2026-11-13**: Initial Proposed specification authored for Today Web Milestones 3 & 4 (Habit Stacking, Inline Quick Capture, and Capacity Telemetry).
