# Daily Schedule Link-Map and Habit Tracker

## Status

Approved

## Problem

Users often struggle to balance **daily routines and habits** (morning rituals, workouts, hydration, evening wind-down) with **planned focus work** (Daily Top 3, project tasks). Current productivity tools either present rigid calendar blocks that induce anxiety when schedules slip, or disconnected habit checklists that lack temporal context. Furthermore, users have different cognitive styles: some think linearly, some prefer narrative journey flows, and others prefer tabular overviews.

## Goal

Provide an interactive, morning-to-bedtime **Link-Map Daily Schedule** that connects daily anchor habits, planned activities, and recharge breaks into a unified trajectory. Support **three switchable layout projections** (Central Spine, Serpentine Journey, and Swimlane Matrix) powered by a single underlying daily activity graph, featuring habit tracking, bedtime protection, and independent activity timing.

## Core Architectural Principle: Independence & Decoupling

The Schedule feature is an **autonomous, self-contained domain**:
- **No external Task backlog dependency:** Schedule activities are created, managed, and executed directly within the Schedule feature as native Schedule Blocks/Activities.
- **No Focus Session dependency:** Schedule activities track duration and active state natively within the schedule without coupling to global focus sessions.
- **No Daily Plan / Daily Top 3 coupling:** The schedule operates as its own dedicated day-planning and routine canvas.
- **Self-contained persistence:** Schedule items, habits, occurrences, and layout preferences belong strictly to the Schedule domain.

## User Stories

- **As a user**, I want to view my entire day from wake-up to bedtime as an interconnected link-map, so that I can see how my daily habits and activities support each other.
- **As a user**, I want to switch between Spine, Journey, and Matrix layouts without losing state, so that I can choose the visualization that best matches my mood and working mode.
- **As a user**, I want to check off habits directly on the map and see my streaks, so that my routines remain consistent.
- **As a user**, I want to see a live projected bedtime based on actual activity progress, so that I don't compromise my sleep.
- **As a user**, I want to track active time directly on scheduled activity blocks, so that I smoothly transition through my daily schedule.

---

## Architecture & Layout System

### 1. Unified Graph Data Model (Single Source of Truth)

All visual layouts render from the same underlying daily activity graph for a given calendar date in the user's timezone:

- **Anchor Nodes:** Fixed or target boundary events (Wake Up time, Bedtime target, Projected Bedtime).
- **Habit Nodes:** Recurring daily rituals with completion status, streak counts, and optional target time anchors.
- **Activity Nodes:** Scheduled activity blocks with estimated durations, category tags, and native active timer state.
- **Recharge Nodes:** Rest and transition breaks (e.g. nutrition, walk, wind-down).
- **Link Edges:** Directional connectors showing sequential progression, habit-stack dependencies, or phase transitions.

### 2. The Three Switchable Visual Layouts

```
                      [ View Switcher: Spine | Journey | Matrix ]
                                          │
            ┌─────────────────────────────┼─────────────────────────────┐
            ▼                             ▼                             ▼
  ┌───────────────────┐         ┌───────────────────┐         ┌───────────────────┐
  │   Option A:       │         │   Option B:       │         │   Option C:       │
  │   Central Spine   │         │ Serpentine Journey│         │  Swimlane Matrix  │
  │  (Bilateral Rail) │         │ (4-Phase S-Flow)  │         │ (Multi-Row Grid)  │
  └───────────────────┘         └───────────────────┘         └───────────────────┘
```

1. **Central Spine Layout (`spine`)**:
   - A vertical chronological axis running from wake-up to bedtime.
   - Bilateral distribution: Habit nodes dock on the left rail; Focus task cards dock on the right rail.
   - Current time is rendered as an illuminated pulsing marker along the central axis.

2. **Serpentine Journey Layout (`journey`)**:
   - A visual narrative journey through 4 interconnected phases:
     - Phase 1: Morning Activation (Wake-up, Hydration, Workout, Planning)
     - Phase 2: Deep Focus (Top 1 & Top 2 focus sessions, recharge pause)
     - Phase 3: Afternoon Momentum (Top 3 focus, shallow work, walk)
     - Phase 4: Bedtime Sanctuary (Wind-down habits, reading, screen curfew, sleep target)
   - Nodes are connected by fluid SVG illuminated bezier paths indicating flow and active progress.

3. **Swimlane Matrix Layout (`matrix`)**:
   - A 4-phase horizontal column layout across the screen.
   - Divided into 3 horizontal swimlanes:
     - Swimlane 1: Habits & Rituals (compact chips with streak badges).
     - Swimlane 2: Focus Tasks (task cards with focus start controls).
     - Swimlane 3: Anchors & Recovery (wake, lunch, bedtime).
   - Curved cross-lane connectors show prerequisite relationships between habits and tasks.

---

## Behavior

### 1. View Switching & Preference Persistence
- The Schedule header displays a segmented control: `[ Spine | Journey | Matrix ]`.
- Switching views triggers a smooth visual transition without page reload or data refetch.
- The user's active layout preference is saved to user settings / local storage and restored automatically upon subsequent visits.

### 2. Habit Tracking & Stacking
- Each habit node contains an icon, title, streak counter (e.g., `🔥 7d`), and a completion toggle.
- Toggling a habit immediately updates its visual state across all views (turns illuminated/filled with green/accent hue).
- When a habit in a sequential stack is checked off, the edge connecting to the next habit lights up, prompting the user toward the next routine.

### 3. Native Activity Execution & Timing
- Activity blocks display title, estimated duration, category tag, and an activity execution toggle ("Start Activity" / "In Progress").
- Tracking an activity updates its active state and completed minutes natively within the schedule, without coupling to global focus sessions.

### 4. Bedtime Projection Engine
- The schedule tracks the cumulative duration of remaining planned activities and scheduled habits.
- When remaining scheduled items exceed the available time before the target bedtime:
  - The Bedtime Node updates with a warning tone (e.g., amber `23:15 (+45m)`).
  - The top summary bar displays: `"Schedule overflow: Bedtime shifts by 45m"`.

### 5. Full-Size Step Detail Dialog
- Clicking any node (Anchor, Habit, Activity, Break) opens a spacious, full-size centered modal dialog (`UiDialog size="full"`).
- Organizes step details into a two-column desktop command surface:
  - **Left Primary Column:** Large title, execution controls (big one-tap checkoff for habits with streak flame, activity timer, circadian wake/bedtime advice), and protocol notes.
  - **Right Supporting Column:** 14-day consistency matrix grid, schedule metadata attributes (phase, time target, duration), and circadian alignment info.
  - **Footer:** Destructive "Delete from Today" button and "Done" dismissal button.

### 6. Schedule Creation & Blueprint Engine
- **Daily Blueprint (Baseline Routine):**
  - The user defines a recurring blueprint (e.g. Weekday Routine) containing their Wake Anchor, target Bedtime, core Habit stack, and default Activity blocks.
  - When opening a new calendar date, the schedule is automatically pre-populated from the Blueprint so the user never starts with a blank screen.
- **In-Line Node Creation (`+ Add Step`):**
  - In each layout view (Spine, Journey, Matrix), a `+` button is available within phase sections and between connected nodes.
  - Clicking `+` opens a lightweight popover to insert:
    1. **Habit:** recurring ritual with icon, title, and optional target time.
    2. **Activity Block:** focus or operations session with title and duration (e.g. 15m, 30m, 60m, 90m).
    3. **Recharge Break:** rest pause (walk, meal, break).
  - Saving the step instantly updates the link-map graph, re-wires edge connections, and recalculates the bedtime projection.
- **Node Deletion & Reordering:**
  - Nodes can be removed from today's plan via the Context Drawer ("Delete from Today"). Removing a habit does not corrupt historical streak logs.

---

## Rules

1. **Feature Independence:** The Schedule feature is standalone and operates independently without coupling to Tasks, Projects, Daily Top 3, or Focus sessions.
2. **User Isolation:** A user can only view, edit, or track habits and schedules belonging to their own user account.
3. **Timezone Authority:** All daily schedules and habit occurrences are evaluated against the user's configured IANA timezone (per ADR-006). A day runs from `00:00:00` to `23:59:59` local time.
4. **State Parity Across Layouts:** All three layouts project the exact same underlying state. An action taken in one layout (e.g. check habit, start activity) immediately reflects if the user switches to another layout.
5. **Non-Destructive Habit Toggle:** Unchecking an accidentally checked habit reverses completion and restores the previous streak count without corrupting historical logs.
6. **Bedtime Invariant:** Every day has a configured Target Bedtime (defaulting to 22:30 if unset).

---

## Acceptance Criteria

### AC-001: Multi-Layout Switching and Persistence
- **Given** an authenticated user is on the Schedule page,
- **When** the user clicks a layout option in the switcher (`Spine`, `Journey`, or `Matrix`),
- **Then** the UI transitions immediately to the chosen layout displaying identical daily nodes and edges,
- **And** reloading the page retains the selected layout preference.

### AC-002: Habit Completion Toggle & Streak Increment
- **Given** an incomplete habit node is displayed on the link-map for today,
- **When** the user clicks the habit completion checkbox,
- **Then** the habit node changes to completed state,
- **And** the streak counter increments by 1,
- **And** the connecting edge to the subsequent node illuminates,
- **And** the daily habit progress counter in the top bar increments.

### AC-003: Native Activity Execution Toggle
- **Given** a planned activity block exists on the schedule link-map,
- **When** the user clicks "Start Activity" on the activity block,
- **Then** the activity block transitions to an active "In Progress" state with a live pulsing indicator across all layout views,
- **And** no dependency or side-effect is triggered on external task or focus session systems.

### AC-004: Bedtime Projection Calculation
- **Given** the user has a target bedtime of 22:30,
- **When** the sum of remaining activity durations and scheduled habits pushes expected completion past 22:30 (e.g. 23:10),
- **Then** the Bedtime terminus node displays the projected time `23:10` with an amber warning badge and delta `+40m`.

### AC-005: Habit Stacking Edge Illumination
- **Given** Habit A is linked as a prerequisite to Habit B in the Morning Activation phase,
- **When** Habit A is marked complete,
- **Then** the connecting link between Habit A and Habit B transitions from muted dashed line to solid illuminated accent line.

### AC-006: Full-Size Detail Dialog Inspection
- **Given** any node (Habit, Activity, or Anchor) on the link-map,
- **When** the user clicks the node,
- **Then** a full-size modal dialog (`UiDialog size="full"`) opens displaying the two-column inspection workspace with execution controls and consistency matrix,
- **And** closing the dialog dismisses the overlay and restores view of the link-map.

### AC-007: In-Line Step Creation (`+` Popover)
- **Given** the user is viewing the schedule map in any layout (`Spine`, `Journey`, or `Matrix`),
- **When** the user clicks the `+` button in a phase,
- **Then** a lightweight creation modal opens allowing choice of step type (`habit`, `activity`, or `recharge`), title, and duration/target time,
- **And** submitting immediately adds the new node to the active phase in the graph, animates the connecting link, and updates the bedtime projection.

### AC-008: Node Deletion from Detail Dialog
- **Given** an existing node is open in the detail dialog,
- **When** the user clicks "Delete from Today" in the dialog footer,
- **Then** the node is removed from today's graph,
- **And** the dialog closes,
- **And** adjacent connecting edges re-link smoothly,
- **And** the bedtime projection recalculates immediately.

### AC-009: Daily Blueprint Pre-population
- **Given** a user opens a calendar day with no previous modifications,
- **When** the schedule loads,
- **Then** the schedule graph is automatically pre-populated with the user's recurring Blueprint (wake anchor, morning habit stack, default activity blocks, and bedtime anchor),
- **And** all blueprint items are displayed ready for immediate tracking or customization.

---

## Edge Cases

1. **Empty Schedule:** When no habits or activities are scheduled for the day, the link-map displays a calm placeholder with quick-add actions ("Add Morning Anchor", "Add Habit", "Add Activity", "Set Bedtime").
2. **Midnight-Crossing Schedules:** If activities extend past 00:00 local time, the bedtime node shows next-day indication (`00:30 +1d`) and calculates total sleep opportunity against tomorrow's wake anchor.
3. **Offline Habit Check-off:** If network is lost, habit toggles are optimistically applied in the UI and queued for sync.

---

## Out of Scope

- Coupling to Tasks backlog, Daily Top 3, or Daily Plan (Schedule is an autonomous feature).
- Coupling to external Focus Session timer (Schedule tracks activity duration natively).
- Calendar two-way sync (Google Calendar / Outlook integration).
- Complex multi-dependency DAG solver (arbitrary circular graph dependencies).
- Social habit sharing / community feeds.

---

## Dependencies

- `docs/specs/ui/productivity-os-visual-system.md` (Visual design language and color tokens).

---

## Change History

- **2026-11-11:** Initial draft specifying the Daily Schedule Link-Map and Habit Tracker with multi-layout switching (`Spine`, `Journey`, `Matrix`).
- **2026-11-11:** *(Clarification)* Decoupled Schedule from Tasks, Daily Top 3, and Focus Sessions; established Schedule as a fully independent domain.
- **2026-11-11:** Added Daily Blueprint engine and In-Line `+` creation workflows (AC-007, AC-008, AC-009).
- **2026-11-11:** Replaced right slide-out panel with full-size, big modal dialog (`UiDialog size="full"`) for step details (AC-006, AC-008).
