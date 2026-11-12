# Plan 009: iOS Daily Schedule Link-Map and Habit Tracker

## Status

Approved (User approved on 2026-11-11; Schedule designated as app Homepage)

## Specification

Primary behavioral source of truth:
- [daily-schedule-linkmap.md](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/specs/planning/daily-schedule-linkmap.md) (Approved)

Acceptance Criteria in scope:
- **AC-001:** Multi-Layout Switching and Persistence (`Spine` | `Journey` | `Matrix`)
- **AC-002:** Habit Completion Toggle & Streak Increment
- **AC-003:** Native Activity Execution Toggle
- **AC-004:** Bedtime Projection Calculation
- **AC-005:** Habit Stacking Edge Illumination
- **AC-006:** Full-Size Step Detail Dialog / Inspection Sheet
- **AC-007:** In-Line Step Creation (`+` Sheet)
- **AC-008:** Node Deletion from Detail Sheet
- **AC-009:** Daily Blueprint Pre-population

Supporting specifications & architectural documents:
- `apps/ios/ARCHITECTURE.md` (One-way data flow, Design System tokens, `@Observable`, async/await)
- `docs/specs/ui/productivity-os-visual-system.md` (Color tokens, typography, surfaces)
- ADR-004 (User isolation), ADR-006 (Timezones)

---

## Architecture Overview (Autonomous iOS Domain)

Per the approved specification, Schedule is an **autonomous, self-contained domain**:
- **Zero coupling** to external Task backlog (`TaskService`), Daily Top 3, or global Focus session timers (`FocusSessionViewModel`).
- Operates on a unified graph data model (`ScheduleGraph`) with Anchor, Habit, Activity, and Recharge nodes.
- Preserves layout preference locally via `UserDefaults`.
- Dynamically recalculates bedtime projections client-side on every graph mutation.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        SWIFTUI VIEWS LAYER                             │
│                                                                        │
│   ScheduleView (Root Feature Screen)                                   │
│   ├── ScheduleViewSwitcher (Spine | Journey | Matrix)                  │
│   ├── ScheduleBedtimeBanner (Live target vs projected warning)         │
│   │                                                                    │
│   ├── Layout Projections:                                              │
│   │   ├── ScheduleSpineLayoutView (Bilateral vertical axis)            │
│   │   ├── ScheduleJourneyLayoutView (4-Phase S-curve flow)             │
│   │   └── ScheduleMatrixLayoutView (Horizontal swimlane columns)       │
│   │                                                                    │
│   ├── Reusable Node Views:                                             │
│   │   ├── ScheduleAnchorNodeView (Wake & Bedtime milestones)           │
│   │   ├── ScheduleHabitNodeView (Checkbox, streak flame, stack edge)   │
│   │   ├── ScheduleActivityNodeView (Duration badge, native timer pill) │
│   │   └── ScheduleRechargeNodeView (Break, walk, nutrition chip)       │
│   │                                                                    │
│   └── Presentation Sheets:                                             │
│       ├── ScheduleNodeDetailSheet (14-day history, controls, delete)   │
│       └── ScheduleAddStepSheet (+ Popover/Sheet to insert node)        │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ intents (closures / actions)
                                    │ @Observable state
┌───────────────────────────────────┴────────────────────────────────────┐
│                        SCHEDULE VIEW MODEL                             │
│   ScheduleViewModel (@Observable, @MainActor)                          │
│   • Owns: graph, activeLayout, selectedNodeId, activeActivityId        │
│   • Bedtime Projection Engine (recalculates overflow & projected time) │
│   • Graph Mutators: toggleHabit, startActivity, addNode, deleteNode    │
│   • Graph Edge Rewiring Engine (maintains topology & edge illumination)│
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ async calls / models
┌───────────────────────────────────┴────────────────────────────────────┐
│                         DOMAIN & SERVICE LAYER                         │
│   ScheduleService (protocol ScheduleServicing)                         │
│   • loadSchedule(for date: Date) -> ScheduleGraph                      │
│   • createDefaultBlueprint() -> ScheduleGraph                          │
│   • BedtimeCalculator (Pure domain math & projection rules)            │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Step 1 — Models & Domain Engine

- **Files:**
  - `apps/ios/ProductivityOS/Models/Schedule.swift`
  - `apps/ios/ProductivityOS/Core/Utilities/BedtimeCalculator.swift`
- **Spec/AC:** AC-001, AC-004, AC-009.
- **Scope:**
  - Define `ScheduleLayoutMode`: enum (`spine`, `journey`, `matrix`).
  - Define `ScheduleNodeType`: enum (`anchor`, `habit`, `activity`, `recharge`).
  - Define `ScheduleEdgeType`: enum (`sequential`, `prerequisite`, `phase`).
  - Define `SchedulePhaseId`: enum (`morning`, `deepFocus`, `afternoon`, `bedtime`).
  - Define `SchedulePhase`, `HabitStreakDay`, `ScheduleNode`, `ScheduleEdge`, `ScheduleGraph`.
  - Implement `BedtimeCalculator`:
    - Evaluates pending habits + incomplete activities.
    - Computes overflow minutes (up to max 45m based on pending workload).
    - Formats projected bedtime (e.g. `23:15 (+45m)`).
  - Implement default Blueprint factory generating the 16-node circadian baseline schedule.

---

## Step 2 — ScheduleService & ScheduleViewModel

- **Files:**
  - `apps/ios/ProductivityOS/Core/Services/ScheduleService.swift`
  - `apps/ios/ProductivityOS/Features/Schedule/ScheduleViewModel.swift`
- **Spec/AC:** AC-001, AC-002, AC-003, AC-004, AC-005, AC-007, AC-008, AC-009.
- **Scope:**
  - `ScheduleService`: Provides blueprint generation, date loading, and optimistic caching.
  - `ScheduleViewModel` (@Observable):
    - Reactive state: `graph: ScheduleGraph?`, `activeLayout: ScheduleLayoutMode`, `selectedNode: ScheduleNode?`, `activeActivityId: String?`.
    - `setLayout(_ mode:)`: Updates layout and stores choice in `UserDefaults`.
    - `toggleHabit(id:)`: Inverts completion, increments/decrements streak count, updates 14-day history array, illuminates outgoing edges, triggers haptic feedback (`UINotificationFeedbackGenerator`), recalculates bedtime.
    - `startActivity(id:)` / `stopActivity()`: Toggles native in-schedule active state with pulsing animation.
    - `addNode(phaseId:type:title:duration:icon:)`: Inserts node into correct phase, re-wires edges smoothly, recalculates bedtime.
    - `deleteNode(id:)`: Prevents deleting anchor nodes; bridges incoming and outgoing edges; recalculates bedtime.

---

## Step 3 — Shared Node Components & Sheets

- **Files:**
  - `apps/ios/ProductivityOS/Features/Schedule/Components/ScheduleViewSwitcher.swift`
  - `apps/ios/ProductivityOS/Features/Schedule/Components/ScheduleBedtimeBanner.swift`
  - `apps/ios/ProductivityOS/Features/Schedule/Components/Nodes/ScheduleAnchorNodeView.swift`
  - `apps/ios/ProductivityOS/Features/Schedule/Components/Nodes/ScheduleHabitNodeView.swift`
  - `apps/ios/ProductivityOS/Features/Schedule/Components/Nodes/ScheduleActivityNodeView.swift`
  - `apps/ios/ProductivityOS/Features/Schedule/Components/Nodes/ScheduleRechargeNodeView.swift`
  - `apps/ios/ProductivityOS/Features/Schedule/Components/Connectors/ScheduleEdgeView.swift`
  - `apps/ios/ProductivityOS/Features/Schedule/Sheets/ScheduleNodeDetailSheet.swift`
  - `apps/ios/ProductivityOS/Features/Schedule/Sheets/ScheduleAddStepSheet.swift`
- **Spec/AC:** AC-002, AC-003, AC-005, AC-006, AC-007, AC-008.
- **Scope:**
  - **Node Views:**
    - `ScheduleHabitNodeView`: Checkbox circle, title, subtitle, streak flame badge (`🔥 12d`), time badge.
    - `ScheduleActivityNodeView`: Duration pill, category tag, "Start" / "Active" execution button.
    - `ScheduleAnchorNodeView`: Circadian milestone card (Wake Up at `06:30`, Bedtime at `22:30` with amber overflow tag).
    - `ScheduleRechargeNodeView`: Compact chip for rest/walk/nutrition.
    - `ScheduleEdgeView`: Custom `Shape` with glowing solid accent line when active, dashed muted line when inactive.
  - **Sheets:**
    - `ScheduleNodeDetailSheet`: Full-size inspection sheet with 14-day consistency matrix grid, execution controls, circadian notes, and "Delete from Today" action.
    - `ScheduleAddStepSheet`: Clean picker for step type (`habit`, `activity`, `recharge`), title, duration presets (15m, 30m, 45m, 60m, 90m), and target phase.

---

## Step 4 — The Three Switchable iOS Layout Projections

- **Files:**
  - `apps/ios/ProductivityOS/Features/Schedule/Layouts/ScheduleSpineLayoutView.swift`
  - `apps/ios/ProductivityOS/Features/Schedule/Layouts/ScheduleJourneyLayoutView.swift`
  - `apps/ios/ProductivityOS/Features/Schedule/Layouts/ScheduleMatrixLayoutView.swift`
- **Spec/AC:** AC-001, AC-005.
- **Scope:**
  - **Spine Layout (`spine`):**
    - Vertical chronological timeline with central axis line running from Wake to Bedtime.
    - Bilateral rail: habit nodes on left rail, activity nodes on right rail (or alternating staggered cards optimized for iPhone portrait width).
    - Pulsing current-time indicator beacon.
  - **Journey Layout (`journey`):**
    - 4-Phase narrative flow: Morning Activation → Deep Focus → Afternoon Momentum → Bedtime Sanctuary.
    - Fluid S-curve connectors linking sequential nodes.
    - Illuminated active edges showing daily momentum.
  - **Matrix Layout (`matrix`):**
    - Horizontal phase paging/scroll across 4 columns.
    - 3 distinct swimlane rows: Habits & Rituals, Focus Activities, Anchors & Recovery.
    - Prerequisite cross-lane indicators.

---

## Step 5 — Schedule Main Screen & App Navigation Integration

- **Files:**
  - `apps/ios/ProductivityOS/Features/Schedule/ScheduleView.swift`
  - `apps/ios/ProductivityOS/Features/Main/MainTabView.swift` (or `TodayView.swift` integration)
- **Spec/AC:** AC-001 through AC-009.
- **Scope:**
  - `ScheduleView.swift`: Composes header (date, intention, habit progress bar), `ScheduleBedtimeBanner`, `ScheduleViewSwitcher`, and active layout view with smooth animated transitions.
  - Provides `+ Add Step` action in header and phase sections.
  - Integrates with `TodayView` (e.g. entry banner / tab / sheet) and `MainTabView` ensuring seamless access without breaking existing navigation.

---

## Step 6 — Verification & Unit Tests

- **Files:**
  - `apps/ios/ProductivityOSTests/ScheduleViewModelTests.swift`
  - `apps/ios/ProductivityOSTests/BedtimeCalculatorTests.swift`
  - `apps/ios/ProductivityOSTests/ScheduleGraphRewiringTests.swift`
- **Spec/AC:** All ACs (AC-001 through AC-009).
- **Scope:**
  - Test layout switching and `UserDefaults` preference persistence.
  - Test habit completion toggling: streak increment on check, streak decrement on uncheck, history array update.
  - Test habit stacking edge illumination: outgoing edges become active.
  - Test Bedtime projection calculations: overflow arithmetic when tasks/habits pending, warning state.
  - Test node addition: correct phase insertion, edge rewiring.
  - Test node deletion: preserves anchors, re-bridges edges, updates bedtime projection.
  - Test daily blueprint pre-population: correct 16 baseline nodes and edges.

---

## Implementation Readiness Checklist

- [x] Approved specification inspected (`docs/specs/planning/daily-schedule-linkmap.md`)
- [x] iOS architecture guidelines reviewed (`apps/ios/ARCHITECTURE.md`)
- [x] Domain independence verified (no coupling to Task backlog, Daily Plan, or Focus Session state)
- [x] Mobile UX considerations addressed (touch targets, haptics, iPhone viewport adaptation for all 3 layouts)
- [x] Test strategy defined covering all 9 Acceptance Criteria
