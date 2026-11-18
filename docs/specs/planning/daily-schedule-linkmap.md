# Daily Schedule Link-Map and Habit Tracker

## Status

Proposed (Amended 2026-11-18)

## Problem

Users often struggle to balance **daily routines and habits** (morning rituals, workouts, hydration, evening wind-down) with **planned focus work** (Daily Top 3, project tasks). Current productivity tools either present rigid calendar blocks that induce anxiety when schedules slip, or disconnected habit checklists that lack temporal context. Furthermore, users have different cognitive styles: some think linearly, some prefer narrative journey flows, and others prefer tabular overviews.

## Goal

Provide an interactive, morning-to-bedtime **Link-Map Daily Schedule** that connects daily anchor habits, planned activities, and recharge breaks into a unified trajectory. Support the **Serpentine Journey Layout** as the single, canonical schedule link-map projection powered by an underlying daily activity graph, featuring habit tracking, bedtime protection, and independent activity timing. (The experimental Central Spine and Swimlane Matrix layouts are retired).

## Core Architectural Principle: Independence & Decoupling

The Schedule feature is an **autonomous, self-contained domain**:
- **No external Task backlog dependency:** Schedule activities are created, managed, and executed directly within the Schedule feature as native Schedule Blocks/Activities.
- **No Focus Session dependency:** Schedule activities track duration and active state natively within the schedule without coupling to global focus sessions.
- **No Daily Plan / Daily Top 3 coupling:** The schedule operates as its own dedicated day-planning and routine canvas.
- **Self-contained persistence:** Schedule items, habits, occurrences, and layout preferences belong strictly to the Schedule domain.

## User Stories

- **As a user**, I want to view my entire day from wake-up to bedtime as an interconnected link-map, so that I can see how my daily habits and activities support each other.
- **As a user**, I want to view my morning-to-bedtime schedule as a fluid serpentine journey link-map, so that I can see the sequential narrative and circadian flow of my day without layout switching clutter.
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

### 2. Canonical Visual Layout: Serpentine Journey

```
                      [ Morning-to-Bedtime Circadian Trajectory ]
                                          │
                                          ▼
                                ┌───────────────────┐
                                │ Canonical Layout: │
                                │Serpentine Journey │
                                │ (4-Phase S-Flow)  │
                                └───────────────────┘
```

1. **Serpentine Journey Layout (`journey`) — Canonical**:
   - A visual narrative journey through interconnected circadian phases:
     - Phase 1: Morning Activation (`morning`, `06:20 – 10:00`): Wake anchor, deep breaths & hydration, morning workout, grooming, and arrive work planning.
     - Phase 2: Deep Focus Work (`deep-focus`, `10:00 – 12:00`): Morning deep work session.
     - Phase 3: Afternoon Momentum (`afternoon`, `12:00 – 18:30`): Lunch break & reset, daily review & admin, afternoon deep work, short break & breathwork, wrap-up.
     - Phase 4: Bedtime Sanctuary (`bedtime`, `20:00 – 23:20`): Shower & dinner, hobby time, reading, learn new skill, wind-down prep, and bedtime anchor.
   - Nodes are connected by fluid SVG illuminated bezier paths indicating flow and active progress.

2. **Retired Layout Projections**:
   - *Central Spine Layout (`spine`)*: Retired. Bilateral vertical chronological axis previously used during early link-map exploration.
   - *Swimlane Matrix Layout (`matrix`)*: Retired. Multi-lane tabular grid across phase columns previously used during early link-map exploration.

---

## Behavior

### 1. Canonical Serpentine Journey Layout & Legacy Preference Migration
- The Schedule link-map renders the Serpentine Journey layout directly as the single canonical projection without a segmented layout switcher.
- Legacy stored layout preferences (`spine` or `matrix` in local storage or user defaults) are automatically resolved and migrated to `journey`.

### 2. Habit Tracking & Stacking
- Each habit node contains an icon, title, streak counter (e.g., `🔥 7d`), and a completion toggle.
- Toggling a habit immediately updates its visual state across all views (turns illuminated/filled with green/accent hue).
- When a habit in a sequential stack is checked off, the edge connecting to the next habit lights up, prompting the user toward the next routine.

### 3. Native Activity Execution & Timing
- Activity blocks display title, estimated duration, category tag, and an activity execution toggle ("Start Activity" / "In Progress").
- Tracking an activity updates its active state and completed minutes natively within the schedule, without coupling to global focus sessions.

### 4. Bedtime Projection Engine
- The schedule tracks the cumulative duration of remaining planned activities and scheduled habits against the target bedtime (`23:20`).
- When remaining scheduled items exceed the available time before the target bedtime:
  - The Bedtime Node updates with a warning tone (e.g., amber `23:50 (+30m)` or `00:05 (+45m)`).
  - The top summary bar displays: `"Schedule overflow: Bedtime shifts by 45m"`.

### 5. Full-Size Step Detail Dialog
- Clicking any node (Anchor, Habit, Activity, Break) opens a spacious, full-size centered modal dialog (`UiDialog size="full"`).
- Organizes step details into a two-column desktop command surface:
  - **Left Primary Column:** Large title, execution controls (big one-tap checkoff for habits with streak flame, activity timer, circadian wake/bedtime advice), and protocol notes.
  - **Right Supporting Column:** 14-day consistency matrix grid, schedule metadata attributes (phase, time target, duration), and circadian alignment info.
  - **Footer:** Destructive "Delete from Today" button and "Done" dismissal button.

### 6. Schedule Creation & Blueprint Engine
- **Personal Habit-Based Daily Blueprint (Baseline Routine):**
  - The recurring blueprint pre-populates each day with the user's authentic habit-based routine rather than fictitious task placeholders.
  - **Circadian Boundary Anchors:**
    - **Wake Anchor:** `06:20` (`anchor-wake`) in the Morning phase.
    - **Bedtime Anchor:** `23:20` (`anchor-bedtime`) in the Bedtime Sanctuary phase.
  - **15 Baseline Habits** (recurring in `schedule_habits`, checkable with tick, initialized with `completed = false`, `streak = 0`):
    - *Morning Activation (`06:20 – 10:00`):*
      1. `06:20` (10m): Deep Breaths & Hydration (`drop.fill`)
      2. `06:30` (30m): Morning Run or Workout (`figure.run`)
      3. `07:00` (40m): Grooming & Get Ready: Shower, teeth, dress up (`shower.fill`)
      *(07:40 – 09:30 Commute / Transit window)*
      4. `09:30` (20m): Arrive Work & Daily Task Planning (`list.bullet.clipboard`)
    - *Deep Focus Work (`10:00 – 12:00`):*
      5. `10:00` (90m): Morning Deep Work Session (`brain.head.profile`)
    - *Afternoon Momentum (`12:00 – 18:30`):*
      6. `12:00` (60m): Lunch Break & Reset: Eat, commute, relax / play game (`gamecontroller.fill`)
      7. `13:00` (60m): Daily Review, Admin & Meetings (`person.2.fill`)
      8. `14:00` (120m): Afternoon Deep Work (`flame.fill`)
      9. `16:30` (30m): Short Break: Light Workout & Breathwork (`figure.cooldown`)
      10. `17:00` (90m): Continue Work & Wrap-Up (`briefcase.fill`)
    - *Bedtime Sanctuary (`20:00 – 23:20`):*
      11. `20:00` (30m): Shower & Dinner (`fork.knife`)
      12. `20:30` (60m): Hobby Time (`sparkles`)
      13. `21:30` (30m): Reading Time (`book.fill`)
      14. `22:15` (50m): Learn New Skill (`graduationcap.fill`)
      15. `23:05` (15m): Wind-Down & Tomorrow Prep (`tshirt.fill`)
      *(23:20: Sleep Target Anchor)*
  - **Zero Dummy Task Entries:** `seedDefaultEntriesForDate` is permanently eliminated. The blueprint injects zero fake tasks or recharge entries into `schedule_entries`.
  - **Unticked State:** Every habit starts uncompleted each day; clicking the checkbox checks off the habit, increments streak, illuminates downstream edges, and updates bedtime projection.
- **In-Line Node Creation (`+ Add Step`):**
  - Within the Serpentine Journey layout, a `+` button is available within phase sections and between connected nodes.
  - Clicking `+` opens a lightweight popover to insert:
    1. **Habit:** recurring ritual with icon, title, and optional target time.
    2. **Activity Block:** focus or operations session with title and duration (e.g. 15m, 30m, 60m, 90m).
    3. **Recharge Break:** rest pause (walk, meal, break).
  - Saving the step instantly updates the link-map graph, re-wires edge connections, and recalculates the bedtime projection.
- **Node Deletion & Reordering:**
  - Nodes can be removed from today's plan via the Context Drawer ("Delete from Today"). Removing a habit does not corrupt historical streak logs.

### 7. Step Details Update & Live Sync
- **In-Place Step Mutation:**
  - Clicking any custom node (Habit, Activity Block, Recharge Break) allows editing its core attributes: title, subtitle, phase, target time / time slot, duration in minutes, notes, and icon (for habits).
  - Editing can be initiated directly within the Step Detail Dialog (`UiDialog size="full"` on web, inspection sheet on iOS).
  - Saving the updated step persists the changes via `PUT /api/v1/schedule/steps/{id}`.
- **Topological Edge Rewiring & Phase Transitions:**
  - If a step's phase is changed (e.g. from `morning` to `deep-focus` or `afternoon`), the step is re-assigned to the new phase container within the Serpentine Journey layout.
  - Connecting graph edges are dynamically re-routed to preserve sequential ordering and avoid orphan links or broken DAG trajectories.
- **Bedtime Projection Recalculation:**
  - Modifying duration or completion expectations automatically triggers the Bedtime Projection Engine to re-evaluate overflow minutes and update the Bedtime anchor node.
- **Circadian Anchor Protection:**
  - Circadian anchor nodes (`anchor-wake` and `anchor-bedtime`) are immutable boundary anchors and cannot be mutated via step update endpoints.

---

## Rules

1. **Feature Independence:** The Schedule feature is standalone and operates independently without coupling to Tasks, Projects, Daily Top 3, or Focus sessions.
2. **User Isolation:** A user can only view, edit, or track habits and schedules belonging to their own user account.
3. **Timezone Authority:** All daily schedules and habit occurrences are evaluated against the user's configured IANA timezone (per ADR-006). A day runs from `00:00:00` to `23:59:59` local time.
4. **Canonical Projection Invariant:** The Serpentine Journey layout is the single, canonical link-map projection across web and iOS.
5. **Non-Destructive Habit Toggle:** Unchecking an accidentally checked habit reverses completion and restores the previous streak count without corrupting historical logs.
6. **Bedtime Invariant:** Every day has a configured Target Bedtime (defaulting to 23:20 if unset, paired with a 06:20 Wake Anchor providing a 7-hour circadian sleep window).
7. **Anchor Immutability Protection:** Circadian anchor nodes (`anchor-wake` and `anchor-bedtime`) are permanent boundary milestones and cannot be deleted or mutated via generic step endpoints. Any attempt to update an anchor node via `PUT /api/v1/schedule/steps/{id}` is rejected with `400 Bad Request` (`ANCHOR_UPDATE_NOT_ALLOWED`).
8. **Step Mutation Parity:** Updating a step immediately synchronizes across the Serpentine Journey link-map projection without full page reloads.
9. **Habit Blueprint Propagation:** Updating a habit's definition (title, duration, target time, notes) updates the recurring blueprint in `schedule_habits`, whereas updating an activity block modifies the specific date's entry in `schedule_entries`.

---

## Acceptance Criteria

### AC-001 *(amended)*: Canonical Serpentine Journey Link-Map Layout
- **Given** an authenticated user is on the Schedule page,
- **When** the user views their daily schedule link-map,
- **Then** the UI renders the Serpentine Journey layout directly as the single canonical projection without a layout switcher control,
- **And** legacy stored layout preferences (`spine` or `matrix`) in client storage (localStorage / UserDefaults) gracefully resolve to `journey`.

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
- **Then** the activity block transitions to an active "In Progress" state with a live pulsing indicator across the Serpentine Journey layout,
- **And** no dependency or side-effect is triggered on external task or focus session systems.

### AC-004 *(amended)*: Bedtime Projection Calculation
- **Given** the user has a target bedtime of 23:20,
- **When** the sum of remaining activity durations and scheduled habits pushes expected completion past 23:20 (e.g. 23:50 or 00:05 next day),
- **Then** the Bedtime terminus node displays the projected time (e.g. `23:50` or `00:05`) with an amber warning badge and delta (e.g. `+30m` or `+45m`).

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
- **Given** the user is viewing the schedule map in the Serpentine Journey layout,
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

### AC-009 *(amended)*: Personal Daily Blueprint Pre-population
- **Given** a user opens a calendar day with no previous modifications,
- **When** the schedule loads,
- **Then** the schedule graph is automatically pre-populated with the user's recurring personal Blueprint containing:
  - Wake Anchor (`06:20`)
  - 15 baseline habits across 4 calibrated circadian phases, all initialized as uncompleted (`completed = false`, `streak = 0`)
  - Bedtime Anchor (`23:20`)
- **And** zero hardcoded fake tasks or dummy recharge entries are seeded into the day's schedule entries (`schedule_entries`),
- **And** all blueprint items are displayed ready for immediate tracking or customization.

### AC-010: Step Details Update & Real-Time Sync
- **Given** an existing custom step or habit on the schedule link-map,
- **When** the user edits its title, subtitle, duration, target time, or protocol notes and confirms the update,
- **Then** the updated step details persist to the backend via `PUT /api/v1/schedule/steps/{id}` returning HTTP `200 OK` with the updated `ScheduleNodeDTO`,
- **And** the step node on the canvas immediately reflects the updated attributes in the Serpentine Journey link-map,
- **And** the bedtime projection engine recalculates any shift based on the updated duration,
- **And** adjacent connecting edges remain cleanly wired without orphaned links.

### AC-011: Anchor Immutability Protection on Update
- **Given** an anchor node (`anchor-wake` or `anchor-bedtime`),
- **When** a client sends a `PUT /api/v1/schedule/steps/{id}` targeting the anchor ID,
- **Then** the server rejects the request with HTTP `400 Bad Request` and structured error code `ANCHOR_UPDATE_NOT_ALLOWED`,
- **And** the anchor node attributes (e.g., wake `06:20`, bedtime `23:20`) remain unchanged in the graph.

### AC-012: Step Phase Reassignment & Topological Rewiring
- **Given** a schedule step currently assigned to a specific phase (e.g., `morning`),
- **When** the user updates the step's phase to another valid phase (e.g., `deep-focus` or `afternoon`),
- **Then** the step moves into the target phase container in the Serpentine Journey layout,
- **And** topological connecting edges dynamically rewire so that the moved node is placed in chronological sequence within the new phase without orphan edges.

### AC-013: User Isolation on Step Update (ADR-004)
- **Given** User A and User B,
- **When** User A attempts to update a step or habit owned by User B via `PUT /api/v1/schedule/steps/{id}`,
- **Then** the server responds with HTTP `404 Not Found` without disclosing the resource's existence,
- **And** User B's schedule record remains completely unmodified.

### AC-014: Personal Habit-Based Baseline Blueprint & Calibrated Phases
- **Given** an authenticated user whose schedule blueprint is seeded (via `seedDefaultBlueprint` or initial baseline load),
- **When** the user fetches their daily schedule graph via `GET /api/v1/schedule/{date}`,
- **Then** the graph contains:
  - Wake Anchor at `06:20` (`anchor-wake`) with `phase: "morning"`
  - Bedtime Anchor at `23:20` (`anchor-bedtime`) with `phase: "bedtime"`
  - 4 calibrated circadian phases:
    - Morning Activation (`morning`, `06:20 – 10:00`)
    - Deep Focus Work (`deep-focus`, `10:00 – 12:00`)
    - Afternoon Momentum (`afternoon`, `12:00 – 18:30`)
    - Bedtime Sanctuary (`bedtime`, `20:00 – 23:20`)
  - Exactly 15 recurring baseline habits in `schedule_habits`:
    1. Morning: Deep Breaths & Hydration (`06:20`, 10m, `drop.fill`)
    2. Morning: Morning Run or Workout (`06:30`, 30m, `figure.run`)
    3. Morning: Grooming & Get Ready: Shower, teeth, dress up (`07:00`, 40m, `shower.fill`)
    4. Morning: Arrive Work & Daily Task Planning (`09:30`, 20m, `list.bullet.clipboard`)
    5. Deep Focus: Morning Deep Work Session (`10:00`, 90m, `brain.head.profile`)
    6. Afternoon: Lunch Break & Reset: Eat, commute, relax / play game (`12:00`, 60m, `gamecontroller.fill`)
    7. Afternoon: Daily Review, Admin & Meetings (`13:00`, 60m, `person.2.fill`)
    8. Afternoon: Afternoon Deep Work (`14:00`, 120m, `flame.fill`)
    9. Afternoon: Short Break: Light Workout & Breathwork (`16:30`, 30m, `figure.cooldown`)
    10. Afternoon: Continue Work & Wrap-Up (`17:00`, 90m, `briefcase.fill`)
    11. Bedtime: Shower & Dinner (`20:00`, 30m, `fork.knife`)
    12. Bedtime: Hobby Time (`20:30`, 60m, `sparkles`)
    13. Bedtime: Reading Time (`21:30`, 30m, `book.fill`)
    14. Bedtime: Learn New Skill (`22:15`, 50m, `graduationcap.fill`)
    15. Bedtime: Wind-Down & Tomorrow Prep (`23:05`, 15m, `tshirt.fill`)
- **And** all 15 habits are uncompleted (`completed = false`, `streak = 0`),
- **And** no fake tasks or recharge entries are seeded in `schedule_entries` (`seedDefaultEntriesForDate` eliminated).

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
- **2026-11-12:** Added step update requirement, anchor immutability protection, phase reassignment, and user isolation acceptance criteria (AC-010, AC-011, AC-012, AC-013).
- **2026-11-18:** *(Amended)* Retired Central Spine Layout and Swimlane Matrix Layout on web per user directive (iOS application retained unchanged). Established Serpentine Journey Layout as the single, canonical schedule link-map projection on web. Amended AC-001 to render Serpentine Journey directly without a layout switcher and migrate legacy stored layout preferences in localStorage. Updated AC-003, AC-007, AC-010, and AC-012 to remove multi-layout references.
- **2026-11-18:** *(Amended)* Replaced generic blueprint with user's personal habit-based schedule: calibrated circadian anchors (Wake `06:20`, Bedtime `23:20`), repartitioned 4 circadian phase windows (Morning `06:20–10:00`, Deep Focus `10:00–12:00`, Afternoon `12:00–18:30`, Bedtime `20:00–23:20`), established 15 baseline habits initialized as uncompleted (`completed = false`, `streak = 0`), and eliminated hardcoded fake task and recharge entries (`seedDefaultEntriesForDate`). Updated AC-004, amended AC-009, updated AC-011 anchor times, and added AC-014.
