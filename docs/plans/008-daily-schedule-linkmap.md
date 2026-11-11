# Plan 008: Daily Schedule Link-Map and Multi-Layout Habit Tracker

## Status

Proposed (Awaiting human approval before implementation)

## Specification

Primary behavioral source of truth:
- [daily-schedule-linkmap.md](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/specs/planning/daily-schedule-linkmap.md) (Draft)

Acceptance Criteria in scope:
- **AC-001:** Multi-Layout Switching and Persistence (`Spine` | `Journey` | `Matrix`)
- **AC-002:** Habit Completion Toggle & Streak Increment
- **AC-003:** Native Activity Execution Toggle
- **AC-004:** Bedtime Projection Calculation
- **AC-005:** Habit Stacking Edge Illumination
- **AC-006:** Context Panel Node Inspection
- **AC-007:** In-Line Step Creation (`+` Popover)
- **AC-008:** Node Deletion from Context Drawer
- **AC-009:** Daily Blueprint Pre-population

Supporting specifications & ADRs:
- `docs/specs/ui/productivity-os-visual-system.md`
- ADR-002 (Tech stack: Vue 3, Pinia, TypeScript, Spring Boot), ADR-004 (User isolation), ADR-006 (Timezones)

---

## Architecture Overview (Independent Domain)

Schedule is an autonomous feature with zero runtime coupling to `tasks`, `daily_plan`, or `focus_sessions`:

```
 ┌─────────────────────────────────────────────────────────┐
 │                   apps/web (Frontend)                   │
 │                                                         │
 │  ┌───────────────────────────────────────────────────┐  │
 │  │ SchedulePage.vue                                  │  │
 │  │  • Header: Date, Intent, Bedtime ETA, Switcher    │  │
 │  │  • View Switcher: [ Spine | Journey | Matrix ]     │  │
 │  └────────────────────────┬──────────────────────────┘  │
 │                           │                             │
 │  ┌────────────────────────┴──────────────────────────┐  │
 │  │ Pluggable Layout Projections                      │  │
 │  │  • ScheduleSpineLayout.vue (Central Axis)         │  │
 │  │  • ScheduleJourneyLayout.vue (Serpentine S-Flow)  │  │
 │  │  • ScheduleMatrixLayout.vue (Swimlane Grid)       │  │
 │  └────────────────────────┬──────────────────────────┘  │
 │                           │                             │
 │  ┌────────────────────────┴──────────────────────────┐  │
 │  │ Shared Components: HabitNode, ActivityNode,       │  │
 │  │ AnchorNode, ScheduleContextPanel                  │  │
 │  └────────────────────────┬──────────────────────────┘  │
 │                           │                             │
 │  ┌────────────────────────┴──────────────────────────┐  │
 │  │ Pinia: useScheduleStore (Independent)             │  │
 │  │  • Graph: nodes, links, activeLayout, bedtime     │  │
 │  │  • Actions: toggleHabit, switchLayout, toggleAct  │  │
 │  └───────────────────────────────────────────────────┘  │
 └───────────────────────────┬─────────────────────────────┘
                             │ REST /api/v1 (Standalone)
 ┌───────────────────────────▼─────────────────────────────┐
 │                   apps/api (Backend)                    │
 │                                                         │
 │  • /api/v1/schedule/{date} (Autonomous Schedule API)    │
 │  • /api/v1/schedule/habits/{id}/toggle                  │
 │  • Tables: schedule_entries, schedule_habits            │
 └─────────────────────────────────────────────────────────┘
```

---

## Step 1 — Store & Multi-Layout Types

- **Files:**
  - `apps/web/src/features/planning/types.ts`
  - `apps/web/src/features/planning/scheduleStore.ts`
- **Spec/AC:** AC-001, AC-004.
- **Scope:**
  - Define `ScheduleLayoutMode = 'spine' | 'journey' | 'matrix'`.
  - Define `ScheduleNode` (types: `anchor`, `habit`, `task`, `recharge`) and `ScheduleEdge` (types: `sequential`, `prerequisite`, `phase`).
  - Implement `useScheduleStore` with reactive bedtime projection logic:
    `projectedBedtime = calculateBedtime(wakeTime, remainingTasks, scheduledHabits)`.
  - Persist `activeLayout` to `localStorage` key `productivity-os:schedule-layout`.

---

## Step 2 — Shared Node & Panel Component Library

- **Files:**
  - `apps/web/src/features/planning/components/nodes/ScheduleHabitNode.vue`
  - `apps/web/src/features/planning/components/nodes/ScheduleTaskNode.vue`
  - `apps/web/src/features/planning/components/nodes/ScheduleAnchorNode.vue`
  - `apps/web/src/features/planning/components/ScheduleContextPanel.vue`
- **Spec/AC:** AC-002, AC-003, AC-006.
- **Scope:**
  - `ScheduleHabitNode.vue`: Circular check-action, title, streak flame badge, hover effect.
  - `ScheduleTaskNode.vue`: Task title, duration badge, Top 3 priority tag, "Start Focus" button triggering active focus session.
  - `ScheduleAnchorNode.vue`: Morning Wake anchor & Bedtime target with live warning indicator if overflow occurs.
  - `ScheduleContextPanel.vue`: Slide-out context drawer when a node is clicked.

---

## Step 3 — The Three Layout Projections

- **Files:**
  - `apps/web/src/features/planning/components/layouts/ScheduleSpineLayout.vue`
  - `apps/web/src/features/planning/components/layouts/ScheduleJourneyLayout.vue`
  - `apps/web/src/features/planning/components/layouts/ScheduleMatrixLayout.vue`
  - `apps/web/src/features/planning/components/ScheduleViewSwitcher.vue`
- **Spec/AC:** AC-001, AC-005.
- **Scope:**
  - **Spine:** Vertical line with current-time beacon; habits on left rail, tasks on right rail.
  - **Journey:** 4 distinct phase cards (Morning Activation, Deep Focus, Afternoon Momentum, Bedtime Sanctuary) connected by fluid SVG glowing bezier curves.
  - **Matrix:** 4 columns × 3 rows (Habits, Focus Tasks, Anchors) with cross-lane connector lines.
  - **View Switcher:** Segmented control toggling `spine | journey | matrix` with instant re-render.

---

## Step 4 — Schedule Page Integration & Preview Modes

- **Files:**
  - `apps/web/src/pages/SchedulePage.vue`
- **Spec/AC:** AC-001 through AC-006.
- **Scope:**
  - Replace static `ScheduleTimeline` placeholder with multi-layout canvas and view switcher.
  - Support `?preview=empty`, `?preview=loading`, and full mock preview data for all 3 layouts.

---

## Step 4b — In-Line Node Creation & Blueprint Management

- **Files:**
  - `apps/web/src/features/planning/components/ScheduleAddStepDialog.vue`
  - `apps/web/src/features/planning/scheduleStore.ts` (`addNode`, `deleteNode`, `resetToBlueprint`)
  - `apps/web/src/features/planning/components/ScheduleContextPanel.vue` (add delete action)
  - `apps/web/src/features/planning/components/layouts/*.vue` (`+ Add Step` action triggers)
- **Spec/AC:** AC-007, AC-008, AC-009.
- **Scope:**
  - Implement `ScheduleAddStepDialog.vue`: Modal allowing user to select Phase (`morning`, `deep-focus`, `afternoon`, `evening`), Type (`habit`, `task`/`activity`, `recharge`), Title, Icon/Category, and Duration.
  - Expose `addNode(phaseId, stepData)` on `scheduleStore` which generates node, wires edges, and updates bedtime.
  - Expose `deleteNode(nodeId)` on `scheduleStore` which removes node, closes panel, and recalculates bedtime.
  - Add `+ Add Step` trigger button on header and phase cards.

---

## Step 5 — Backend Schema & REST Endpoints (Integration Phase)

- **Files:**
  - `apps/api/src/main/resources/db/migration/V15__habits_and_schedule.sql`
  - `apps/api/src/main/kotlin/com/productivityos/habit/...`
  - `apps/api/src/main/kotlin/com/productivityos/schedule/...`
- **Spec/AC:** AC-001, AC-002, AC-003.
- **Scope:**
  - Create `habits` and `habit_occurrences` tables with user isolation.
  - Expose `/api/v1/schedule/{date}` aggregating tasks from `DailyPlan`, `TopThree`, and `HabitOccurrence`.
  - Expose `POST /api/v1/habits/{id}/toggle/{date}` to record habit completion.

---

## Verification & Test Plan

1. **Frontend Type & Lint Check:**
   `pnpm --dir apps/web typecheck && pnpm --dir apps/web lint`
2. **Component Tests (Vitest):**
   - Verify layout switching preserves active node selection and habit state.
   - Verify habit check-off increments streak and lights up connected edge.
   - Verify bedtime calculation correctly flags overflow past target sleep time.
3. **Backend Integration Tests:**
   `./gradlew :apps:api:test`
