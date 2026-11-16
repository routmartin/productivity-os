# iOS Tasks Time-Sticky UX & Filter UI Specification

## Status
Approved

## Problem
In the iOS application, the Tasks view (`apps/ios/ProductivityOS/Features/Tasks/TasksView.swift`) suffers from critical visual bugs and fails to satisfy the user's foundational mental model of temporal productivity:

1. **Broken Segmented Control**: The top temporal segment picker uses Apple's native `Picker(...).pickerStyle(.segmented)`. With 4 segments including task counts (e.g. `Today (2)`, `Upcoming (0)`, `Backlog (1)`, `All (3)`), native `UISegmentedControl` constrains each segment to 25% screen width, causing text clipping and elision (`Upcoming (...`) even on an iPhone 17 Pro.
2. **Missing Status Counts & Static Layout**: The secondary lifecycle status chips (`All`, `Active`, `Completed`, `Cancelled`) sit in a rigid, non-scrolling `HStack` without task counts, diverging from the web UI (`FilterChips.vue`) and leaving the user blind to the volume of tasks in each lifecycle state.
3. **Misleading Section Grouping (Overdue Clumped in Today)**: In `TasksView.swift`, tasks under the `Today` segment dump both overdue tasks (e.g. Due 2026-11-06 and 2026-09-02) and today's tasks under a single section header `"TODAY"`. There is no visual demarcation between tasks planned for today and tasks that have lapsed by days or months.
4. **Broken Completed Filter**: iOS `TasksViewModel.loadTasks()` queries only `taskService.listActiveTasks()` (which hits `GET /api/v1/tasks`). While `TaskController.kt` has a dedicated endpoint `GET /api/v1/tasks/completed`, iOS lacks client networking for it, causing selecting "Completed" to present an empty state even when completed tasks exist on the server.
5. **Absence of Time UI & "Time-Sticky" Support**:
   - The user is fundamentally "sticky with time": they require an immediate answer to **"What should I do right now at this time?"** and **"What time should I do this?"** whenever they glance at their phone.
   - Currently, `TaskRowView` completely ignores `estimatedDurationMinutes`, forcing the user to type durations directly into task titles (e.g. *"45 Minutes to focus on learning AI knowlage"*).
   - Overdue tasks show raw ISO dates (`2026-11-06`) next to an unlabelled placeholder (`• — •`), lacking relative urgency cues (e.g. *"8d overdue"*).
   - The screen lacks a temporal anchor card answering what is happening *now* and what is *up next* at the current clock time.

## Goal
Deliver a premier, time-anchored iOS task experience that:
- Fixes all filter and layout bugs with a custom fluid pill segment control and scrollable filter chips with reactive counts.
- Visually separates Overdue tasks from Today's tasks with clear urgency badging.
- Establishes the **"Time-Sticky" UX Paradigm** across the system: surfaces duration badges, relative overdue cues, and a prominent **"Now & Up Next" Time Anchor Card** on the Today tasks screen that lets the user know what to do right now at a glance and launch focus with 1 tap.
- Fetches and displays completed tasks correctly from the backend API.

---

## The "Time-Sticky" Mental Model & System-Wide UX Paradigm

```
┌─────────────────────────────────────────────────────────────┐
│                 TIME-STICKY MENTAL MODEL                    │
│                                                             │
│   "When I open my phone, I immediately know:                │
│    1. WHAT TIME IS IT?       -> Live Clock & Context        │
│    2. WHAT SHOULD I DO NOW?  -> Happening Now / Up Next     │
│    3. HOW LONG WILL IT TAKE? -> Explicit Duration Pill     │
│    4. WHAT IS OVERDUE?       -> Urgency-grouped Warning     │
│    5. WHEN CAN I FOCUS?      -> 1-Tap Focus Initiation"     │
└─────────────────────────────────────────────────────────────┘
```

The system recognizes time as the user's primary psychological anchor. Rather than viewing tasks as an abstract, static to-do list:
1. **Temporal Context First**: Work is always framed relative to the user's current clock time, active circadian phase, and available time budget.
2. **Explicit Duration Everywhere**: Every task row, card, and modal must surface estimated duration prominently (e.g. `⏱️ 45m`). Titles must never need to contain duration strings.
3. **Actionable Now-Anchor**: The top of the daily view must provide immediate situational awareness: if a focus session is running, show "Happening Now"; if free, show "Up Next" with scheduled time and 1-tap focus launch.

---

## User Stories

1. **As a time-conscious professional**, when I open the Tasks tab on my iPhone, I want to see the current time and the most important task I should be doing right now with its estimated duration, so that I can immediately focus without decision paralysis.
2. **As a user scanning my workload**, I want the segment tabs (`Today`, `Upcoming`, `Backlog`, `All`) to render clearly without any text truncation or ellipses, so that I can switch views cleanly.
3. **As a user managing daily priorities**, I want overdue tasks clearly separated from today's scheduled tasks under their own "Overdue" section with relative day counters, so that I understand my true commitments for today.
4. **As a user triaging tasks**, I want status filter chips (`All`, `Active`, `Completed`, `Cancelled`) to display live counts and scroll horizontally on small screens, so that I know exactly how many tasks exist in each state.
5. **As a user reviewing accomplishments**, when I tap "Completed", I want to see all my completed tasks loaded from the server, so that I can verify completed work.

---

## Detailed Behavior & Component Specifications

### 1. Custom Fluid Pill Segment Bar (`TaskDateSegmentBar`)
- Replaces native `Picker(...).pickerStyle(.segmented)`.
- Displays 4 temporal segments:
  - `Today`
  - `Upcoming`
  - `Backlog`
  - `All`
- Each segment displays its label and a reactive count pill: e.g. `Today 2`, `Upcoming 0`, `Backlog 1`, `All 3`.
- Sizing is content-driven with intrinsic width and horizontal flexibility. Minimum touch target height: 38pt.
- Active segment renders as an elevated capsule with primary background or primary text highlight and smooth spring animation (`AppMotion.spring`).
- Labels and count badges never truncate or show ellipses on any supported iPhone screen size (iPhone SE to iPhone 17 Pro Max).

### 2. Horizontal Scrollable Status Filter Chips (`StatusFilterChipsView`)
- Sits below the date segment bar in a horizontal `ScrollView` with `showsIndicators: false`.
- Four chips:
  - `All (N)`
  - `Active (N)`
  - `Completed (N)`
  - `Cancelled (N)`
- Counts reflect the tasks matching each status *within the currently selected date segment*.
- Active chip is highlighted with `AppColors.primaryTint` background, `AppColors.primary` border, and `AppColors.primary` text.
- Inactive chips have clean white/surface background and subtle border.

### 3. Visual Grouping: Overdue vs. Today
When `Today` segment is selected:
- **Overdue Section** (rendered only if overdue tasks exist):
  - Section Header: `"OVERDUE"` with item count badge in warning coral/amber (`Color(hex: "FF6B4A")`).
  - Tasks listed in this section have `dueDate < todayISO`.
  - Rows display relative overdue badge: e.g. `"8d overdue"` or `"73d overdue"`.
- **Today Section**:
  - Section Header: `"TODAY"` with item count badge in primary purple.
  - Tasks listed have `dueDate == todayISO`.
  - Rows display `"Today"` pill or scheduled time window.

When `Upcoming` segment is selected:
- Chronological date grouping (e.g. `"Tomorrow"`, `"Saturday, Nov 15"`, etc.).

When `Backlog` segment is selected:
- Grouped by Project (or flat list under `"Backlog"`).

When `All` segment is selected:
- Multi-section grouping: `Overdue`, `Today`, `Upcoming`, `Backlog`.

### 4. Time-Sticky "Now & Up Next" Anchor Card (`TimeAnchorCardView`)
- Rendered prominently at the top of the `Today` segment (above the task sections).
- Features:
  1. **Clock Header**:
     - Current live time in large monospaced font (e.g. `15:45`).
     - Circadian phase / greeting subtitle: e.g. `Afternoon Focus • Friday, Nov 14`.
  2. **Card State Engine**:
     - **State A (Session Active)**: If a focus session is in progress, the card shows a pulsing accent ring, the current task title, elapsed/remaining time (`18m remaining`), and a `"Resume Focus"` button.
     - **State B (Up Next / Recommended Now)**: If no session is active and active today/overdue tasks exist, it picks the primary task (first Daily Top 3 item or highest-priority today task). Displays:
       - Subtitle: `UP NEXT`
       - Task title
       - Duration pill: `⏱️ 45m duration`
       - Estimated time window: `15:45 – 16:30`
       - 1-tap Action Button: `"Start Focus (45m)"` with play icon, launching the focus session sheet directly.
     - **State C (Plate Clear)**: If all today tasks are completed, shows a serene celebration: `"All caught up for today! 🎉"` with action `"Pull from Backlog"`.

### 5. Enhanced Task Row (`TaskRowView`)
- **Duration Pill**: Always renders `task.formattedDuration` (e.g. `45m`, `1h 30m`) in a sleek muted capsule next to the priority pill.
- **Urgency & Due Date Cue**:
  - Overdue: `8d overdue` in amber/coral text with `exclamationmark.circle.fill`.
  - Today: `Today` with subtle purple tint.
  - Tomorrow: `Tomorrow` in blue tint.
  - Future: formatted localized date (e.g. `Nov 20`) with calendar icon.
- **Project Metadata**:
  - If project is assigned: shows colored dot + project name.
  - If no project: cleanly omits the project element (no dangling `• — •`).
- **Context Actions**:
  - Long press context menu: `Edit Task`, `Reschedule to Today`, `Reschedule to Tomorrow`, `Move to Backlog`.
  - Trailing swipe actions: Quick reschedule buttons.

### 6. Backend Integration & Completed Tasks
- Backend contract:
  - `GET /api/v1/tasks?page=0&size=50`: returns active and recent tasks.
  - `GET /api/v1/tasks/completed?page=0&size=50`: returns user's completed tasks, sorted by `completedAt DESC`.
  - `PUT /api/v1/tasks/{id}`: full-replace update with `UpdateTaskRequest`.
- iOS Networking:
  - Add `case listCompletedTasks(page: Int = 0, size: Int = 50)` to `Endpoint.swift` pointing to `/api/v1/tasks/completed`.
  - Add `listCompletedTasks()` to `TaskService.swift`.
  - In `TasksViewModel`: When loading or when selecting `Completed` status filter, query completed tasks and populate `completedTasks`, ensuring the "Completed" filter displays real historical data and accurate counts.

---

## Rules & Invariants

1. **No Truncation Invariant**: No segment tab label or status filter chip text shall truncate or show ellipsis on any device with screen width >= 375pt (iPhone SE 2nd/3rd gen and above).
2. **Temporal Overdue Invariant**: In the `Today` segment, tasks with `dueDate < todayISO` MUST be visually isolated from tasks with `dueDate == todayISO`. Overdue tasks must never masquerade as tasks scheduled for today.
3. **Time Visibility Invariant**: Every task with an `estimatedDurationMinutes` value must render its duration pill. The UI must never force the user to type duration into the task title.
4. **Endpoint Strictness**: iOS networking must strictly conform to existing backend endpoints (`/api/v1/tasks` and `/api/v1/tasks/completed`). No fictitious query parameters or unverified endpoints.
5. **Calm Design Compliance**: All new UI components must use tokens from `AppColors`, `AppTypography`, `AppSpacing`, and `AppRadius`. Do not introduce arbitrary hardcoded colors or divergent styling.

---

## Constraints

- Platform: iOS 17.0+ (SwiftUI, Observation framework).
- Architecture: MVVM with `TasksViewModel` and `TaskService`.
- Backend: Kotlin / Spring Boot 3 running on port 8080.
- Localization/Timezone: Dates must be computed using `Calendar.current` and user's active timezone per ADR-006.

---

## Acceptance Criteria

### AC-001: Fluid Date Segment Bar Rendering & Zero Truncation
- **Given** an iPhone screen of any supported width (375pt to 430pt)
- **When** the Tasks view renders with counts across segments (e.g. `Today (2)`, `Upcoming (0)`, `Backlog (1)`, `All (3)`)
- **Then** all four segments must be fully visible with their entire titles and count badges without ellipses (no `"Upcoming (..."`).
- **And** tapping a segment selects it with smooth animated feedback.

### AC-002: Status Filter Chips with Reactive Counts
- **Given** the user is viewing the Tasks screen
- **When** tasks are loaded in the active date segment
- **Then** four status filter chips (`All`, `Active`, `Completed`, `Cancelled`) render in a horizontally scrollable container.
- **And** each chip displays the accurate count of tasks matching that status within the selected date segment (e.g. `All (2)`, `Active (2)`, `Completed (0)`, `Cancelled (0)`).
- **And** selecting a filter immediately filters the visible task list.

### AC-003: Overdue vs. Today Visual Separation
- **Given** the user has selected the `Today` date segment
- **And** there exist tasks with `dueDate < todayISO` (e.g. `2026-11-06`) and tasks with `dueDate == todayISO`
- **Then** the view must render two distinct sections:
  1. An `"OVERDUE"` section containing the lapsed tasks, displaying an urgency badge and relative overdue counter (e.g. `"8d overdue"`).
  2. A `"TODAY"` section containing only tasks due today.
- **And** if no overdue tasks exist, only the `"TODAY"` section is displayed.

### AC-004: Time-Sticky "Up Next" Anchor Card Display & Action
- **Given** the user opens the Tasks view on the `Today` segment at clock time `15:45`
- **And** no active focus session is currently running
- **When** the view renders
- **Then** a prominent `TimeAnchorCard` appears at the top displaying:
  1. The live time `15:45` and temporal phase subtitle.
  2. The next prioritized task for today.
  3. The task's estimated duration (e.g. `⏱️ 45m`) and suggested time block (e.g. `15:45 – 16:30`).
  4. A `"Start Focus (45m)"` action button.
- **When** the user taps the `"Start Focus"` button
- **Then** the app immediately opens the focus session for that task.

### AC-005: Time-Sticky "Happening Now" State
- **Given** the user has a focus session currently running or paused
- **When** the user views the Tasks screen
- **Then** the `TimeAnchorCard` displays `"Happening Now"`, the active task title, elapsed/remaining time, and a `"Resume Focus"` button.

### AC-006: TaskRow Duration & Urgency Metadata
- **Given** a task with `estimatedDurationMinutes = 45` and `dueDate = 2026-11-06` (8 days prior to current date 2026-11-14)
- **When** the task row is rendered
- **Then** it displays a duration pill `"45m"` alongside the priority badge.
- **And** it displays an overdue badge `"8d overdue"` in warning color with `exclamationmark.circle.fill`.
- **And** if `projectName` is nil or empty, no dangling bullet separator (`• — •`) is rendered.

### AC-007: Completed Tasks Data Loading & Display
- **Given** completed tasks exist on the backend for the current user
- **When** the user taps the `"Completed"` status filter chip
- **Then** the application queries `GET /api/v1/tasks/completed` via `TaskService`.
- **And** the completed tasks render in the list with completion indicators and completed timestamps.

### AC-008: Quick Reschedule Actions Preservation
- **Given** any task row in the Tasks view
- **When** the user swipes or long-presses to reveal actions
- **Then** `"Reschedule to Today"`, `"Reschedule to Tomorrow"`, and `"Move to Backlog"` actions are accessible.
- **And** selecting an action calls `PUT /api/v1/tasks/{id}`, updates `dueDate`, and immediately relocates the task to the appropriate segment without full page reloads.

---

## Edge Cases

1. **Zero Estimated Duration**: If `estimatedDurationMinutes` is nil or 0, default display to `"30m"` or omit the duration badge gracefully without breaking layout.
2. **Tasks with Due Date 1 Year Overdue**: Display formatted date (e.g. `"Sep 2, 2025 • Overdue"`) rather than unbounded relative days if greater than 90 days.
3. **Empty Overdue State**: When all overdue tasks are rescheduled or completed, the Overdue section dynamically disappears with animation.
4. **All Today Tasks Completed**: The `TimeAnchorCard` transitions smoothly to the "Plate Clear" celebration state.
5. **Offline / Network Failure during Completed Fetch**: Surface retryable `APIStateView` error rather than permanently empty list.

---

## Out of Scope
- Direct in-line creation of calendar events into Apple Calendar / EventKit (reserved for future calendar sync spec).
- Editing estimated duration via drag gestures on the task row (editing is done via `TaskEditSheet`).
- Modifying backend database schema or adding new Kotlin controllers (backend endpoints already exist).

---

## Dependencies
- Backend Endpoints: `GET /api/v1/tasks`, `GET /api/v1/tasks/completed`, `PUT /api/v1/tasks/{id}`.
- Shared Design System: `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppMotion`.
- Focus Module: `FocusSessionViewModel`, `FocusPreparationView`.

---

## Open Decisions (Pre-Implementation)

- **D1: Custom Pill Bar vs UISegmentedControl**: Replace native picker with custom SwiftUI pill bar to resolve label truncation once and for all.
- **D2: Overdue vs Today Visual Grouping**: Split `Today` segment into two distinct sections (`OVERDUE` with amber accent, `TODAY` with primary purple) to prevent cognitive distortion.
- **D3: Time-Sticky "Now & Up Next" Card**: Position time anchor card at the top of the Today view to answer the user's primary mental question immediately.
- **D4: TaskRow Duration & Time Cues**: Add `estimatedDurationMinutes` pill and relative overdue formatting to `TaskRowView`.
- **D5: Completed Tasks Data Source**: Wire `GET /api/v1/tasks/completed` into `TaskService` and `TasksViewModel`.

---

## Change History
| Date | Author | Description |
| :--- | :--- | :--- |
| 2026-11-14 | SDD Planner | Initial specification authoring addressing UI filter bugs, segmented control truncation, and time-sticky UX mandate. |
