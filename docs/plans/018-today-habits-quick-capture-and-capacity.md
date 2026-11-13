# Plan 018: Today Habits, Inline Quick Capture, and Capacity Telemetry

## Status

Approved for implementation

---

## Specification

### Primary Behavioral Source of Truth

- [today-habits-and-capacity.md](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/specs/planning/today-habits-and-capacity.md) (Proposed)
- [daily-schedule-linkmap.md](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/specs/planning/daily-schedule-linkmap.md) (Approved)
- [task-creation-shortcut.md](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/specs/ui/task-creation-shortcut.md) (Approved)
- [productivity-os-visual-system.md](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/specs/ui/productivity-os-visual-system.md) (Approved)

### Acceptance Criteria in Scope

- **AC-001:** Scheduled Habits Rendered in Today Timeline (`ScheduleTimeline.vue`)
- **AC-002:** 1-Tap Habit Completion Toggle (`ScheduleTimeline.vue` -> `scheduleStore.toggleHabit`)
- **AC-003:** 1-Tap Habit Unchecking (streak decrement & pending state restoration)
- **AC-004:** Dynamic Bedtime Recalculation on Habit Toggle (`recalculateBedtime` & overflow telemetry)
- **AC-005:** Optimistic Rollback on Server Error (state reverts to snapshot on failure)
- **AC-006:** Inline Quick Capture Presence & Hint (`QuickCapture.vue` with `<kbd>c</kbd>`)
- **AC-007:** Single-Key 'c' Shortcut Focuses Inline Capture (`useGlobalTaskShortcut.ts`)
- **AC-008:** Successful Inline Task Capture (`tasksStore.addTask` -> Recent Activity)
- **AC-009:** Whitespace-Only Capture Guard (disabled submission)
- **AC-010:** Capacity & Energy Telemetry Ratio Display (`CapacityTelemetryCard.vue`)
- **AC-011:** Over-Capacity Warning State (warning tone & overflow minutes)
- **AC-012:** Bedtime Trajectory Telemetry (target vs projected bedtime)
- **AC-013:** Dynamic AI Briefing Synthesis (`AiBriefing.vue` subline and CTA)
- **AC-014:** Deterministic Preview States (`?preview=loading|error|empty`)

### Supporting Decisions & Architectural Guidelines

- **ADR-001: Spec-Driven Development Workflow** (Specifications precede implementation; human approval required before coding)
- **ADR-002: Technology Stack** (Vue 3, Pinia, TypeScript, Vite)
- **ADR-004: Authentication & User Isolation** (Stateless JWT, user-scoped data)
- **ADR-005: API Architecture** (REST `/api/v1`, resource URIs, structured error responses)
- **ADR-006: Time & Timezone Handling** (IANA user timezone, `LocalDate`, deterministic date boundaries)

---

## Architecture & Endpoint Contracts

### 1. Endpoint Verification (Strict Endpoint Contract Rule)

All required backend endpoints already exist, are fully tested, and verified in `apps/api`:

| Method | Verified Endpoint URI | Request DTO | Response DTO | Purpose |
|---|---|---|---|---|
| `GET` | `/api/v1/schedule/{date}` | *None* | `ScheduleGraphResponse` | Load daily circadian schedule graph with habit and task nodes |
| `POST` | `/api/v1/schedule/habits/{id}/toggle` | `ToggleHabitRequest(date?)` | `ToggleHabitResponse` | 1-Tap habit toggle with updated streak, edges, and projected bedtime |
| `GET` | `/api/v1/daily-plan/{date}/capacity` | *None* | `CapacityInfo` | Fetch daily planned hours, capacity hours, and over-capacity flag |
| `POST` | `/api/v1/tasks` | `CreateTaskRequest(title, ...)` | `TaskResponse` | Task capture into Inbox |

*No new backend endpoints or DTO modifications are required. All work in this plan executes in `apps/web`.*

### 2. State & Data Flow Architecture

```
                                 ┌────────────────────────────────────────┐
                                 │              TodayPage.vue             │
                                 └───────────────────┬────────────────────┘
                                                     │
                   ┌─────────────────────────────────┼────────────────────────────────┐
                   ▼                                 ▼                                ▼
       ┌───────────────────────┐         ┌───────────────────────┐        ┌───────────────────────┐
       │     todayStore.ts     │         │    scheduleStore.ts   │        │     tasksStore.ts     │
       └───────────┬───────────┘         └───────────┬───────────┘        └───────────┬───────────┘
                   │                                 │                                │
                   │ plannedMinutes / capacity       │ habitNodes / overflowMinutes   │ addTask (inbox capture)
                   ▼                                 ▼                                ▼
       ┌───────────────────────┐         ┌───────────────────────┐        ┌───────────────────────┐
       │ CapacityTelemetryCard │         │  ScheduleTimeline.vue │        │    QuickCapture.vue   │
       │  (Ratio & Bedtime)    │         │  (1-tap habit toggle) │        │ (Inline + 'c' shortcut)
       └───────────────────────┘         └───────────────────────┘        └───────────────────────┘
```

---

## Implementation Steps

### Step 1 — Schedule Store Synchronization on Today & Unified Habit Timeline

**Status:** pending

- **Files/modules:**
  - `apps/web/src/pages/TodayPage.vue`
  - `apps/web/src/features/planning/components/ScheduleTimeline.vue`
  - `apps/web/src/features/planning/todayStore.ts`
  - `apps/web/src/features/planning/types.ts`
- **Spec/AC:** `AC-001`, `AC-002`, `AC-003`, `AC-004`, `AC-005`, `AC-014`
- **Behavior:**
  1. Mount and synchronize `scheduleStore.load(preview)` in `TodayPage.vue` alongside `today.load()`, `tasksStore.load()`, and `focusStore.load()`.
  2. Enhance `ScheduleTimeline.vue` to accept both scheduled tasks and habit nodes (or a unified list of timeline items), or accept `habits: ScheduleNode[]` alongside `entries: ScheduleEntry[]`.
  3. Render habit items with:
     - Habit icon and title.
     - Scheduled / target time label.
     - Streak badge with flame icon (e.g. `🔥 12d`).
     - 1-tap interactive completion checkbox / toggle button.
     - Distinct visual styling: subtle emerald/success tone or purple accent with dashed or softly highlighted left border when active.
  4. Handle habit toggling: Clicking the toggle button calls `scheduleStore.toggleHabit(habit.id)`, immediately mutating local state optimistically, updating the streak count, and recalculating the bedtime projection.
  5. Rollback on failure: If the server request fails, the optimistic change reverts to the prior snapshot and an error message is surfaced.
- **Dependencies:** `scheduleStore.ts`, `scheduleApi.ts`.
- **Tests:**
  - Vitest unit test verifying habit rendering with streak badges (`ScheduleTimeline.spec.ts`).
  - Vitest unit test verifying 1-tap toggle emits event and calls `scheduleStore.toggleHabit`.
- **Risks/ambiguities:** Preventing duplicate requests on rapid clicks (handled by `scheduleStore.toggleHabit` debounce / active mutation guard).

---

### Step 2 — Inline Quick Capture on Today with `<kbd>c</kbd>` Shortcut

**Status:** pending

- **Files/modules:**
  - `apps/web/src/features/tasks/components/QuickCapture.vue`
  - `apps/web/src/features/tasks/composables/useGlobalTaskShortcut.ts`
  - `apps/web/src/pages/TodayPage.vue`
- **Spec/AC:** `AC-006`, `AC-007`, `AC-008`, `AC-009`
- **Behavior:**
  1. Mount `QuickCapture.vue` directly on `TodayPage.vue` in the main workspace above or alongside `RecentActivity.vue`.
  2. Add `data-quick-capture-input` attribute and autofocus helper to the input field in `QuickCapture.vue`.
  3. Display the shortcut indicator badge `<kbd class="kbd tnum">c</kbd>` inside the Quick Capture input container.
  4. Update `useGlobalTaskShortcut.ts`:
     - When single key `'c'` is pressed (without modifiers) and the user is NOT typing in an existing input/textarea:
     - Check if the current route is `'today'` (`route.name === 'today'`).
     - If on Today, query `document.querySelector('[data-quick-capture-input]')` and immediately focus the input, suppressing the global `NewTaskDialog` modal.
     - If not on Today, continue existing behavior opening the global dialog.
  5. On submit in `QuickCapture.vue`:
     - Dispatches `tasksStore.addTask({ title, status: 'INBOX' })`.
     - Clears the input field immediately.
     - Automatically updates `RecentActivity.vue` with the captured item.
     - Rejects empty or whitespace-only submissions.
- **Dependencies:** `tasksStore.ts`, `useGlobalTaskShortcut.ts`.
- **Tests:**
  - Vitest unit test verifying quick capture input submission creates task in `tasksStore` (`QuickCapture.spec.ts`).
  - Vitest unit test verifying `'c'` keydown on Today focuses the inline input instead of opening modal (`useGlobalTaskShortcut.spec.ts`).
- **Risks/ambiguities:** Ensuring `Escape` blurs the inline input gracefully without triggering conflicting shortcuts.

---

### Step 3 — Dynamic Capacity & Bedtime Telemetry Card & AI Briefing Integration

**Status:** pending

- **Files/modules:**
  - `apps/web/src/features/planning/components/CapacityTelemetryCard.vue` (new component)
  - `apps/web/src/features/ai/components/AiBriefing.vue`
  - `apps/web/src/pages/TodayPage.vue`
- **Spec/AC:** `AC-010`, `AC-011`, `AC-012`, `AC-013`, `AC-014`
- **Behavior:**
  1. Create `CapacityTelemetryCard.vue` in `apps/web/src/features/planning/components/`:
     - Reads `todayStore.plan` (`plannedMinutes`, `focusCapacityMinutes`) and `scheduleStore` (`overflowMinutes`, `targetBedtime`, `projectedBedtime`, `completedHabitsCount`, `totalHabitsCount`).
     - Renders visual capacity ratio bar with percentage fill.
     - Renders buffer remaining (e.g. `+1.5h buffer remaining`) or over-capacity warning badge (e.g. `⚠️ Over capacity by 45m`) when planned minutes exceed capacity.
     - Renders Bedtime Trajectory:
       - If `overflowMinutes > 0`: `⚠️ Bedtime shifts by +[overflowMinutes]m to [projectedBedtime]` in warning tone.
       - If `overflowMinutes === 0`: `✓ On track for [targetBedtime] bedtime` in success/accent tone.
     - Renders Habit Completion Pill: e.g. `3/5 habits completed`.
  2. Mount `CapacityTelemetryCard.vue` into the right context rail of `TodayPage.vue` (above `DailySummaryCard.vue`).
  3. Enhance dynamic `briefingData` in `TodayPage.vue`:
     - Incorporates `scheduleStore.overflowMinutes` and capacity telemetry into the AI Briefing subline.
     - Dynamically changes CTA button:
       - When overflowing: `"Review Schedule"` -> navigates to `/schedule`.
       - When under capacity: `"Plan My Day"` -> navigates to `/schedule`.
       - When all priorities and habits complete: `"Review Schedule"`.
- **Dependencies:** `todayStore.ts`, `scheduleStore.ts`, `AiBriefing.vue`.
- **Tests:**
  - Vitest unit test for `CapacityTelemetryCard.vue` checking ratio bar calculations, buffer display, and overflow warning (`CapacityTelemetryCard.spec.ts`).
  - Vitest unit test for dynamic briefing computations based on telemetry state (`TodayPage.spec.ts`).
- **Risks/ambiguities:** Ensuring container queries properly wrap and stack the card when the context panel opens or screen width shrinks.

---

### Step 4 — Verification, Preview State Hardening & Test Suite Execution

**Status:** pending

- **Files/modules:**
  - `apps/web/src/pages/TodayPage.vue`
  - `apps/web/src/features/planning/__tests__/`
  - `apps/web/src/features/tasks/__tests__/`
- **Spec/AC:** `AC-001` through `AC-014`
- **Behavior:**
  1. Verify all preview states (`?preview=loading`, `?preview=error`, `?preview=empty`) on Today to ensure zero layout shift, proper skeleton loaders, and graceful error boundaries.
  2. Run the complete test and lint suite across `apps/web`:
     - `pnpm --filter @productivity-os/web test:unit --run`
     - `pnpm --filter @productivity-os/web typecheck`
     - `pnpm --filter @productivity-os/web lint`
- **Dependencies:** Steps 1–3.
- **Tests:** Full Vitest unit test pass.
- **Risks/ambiguities:** None.

---

## Tests & Traceability Matrix

| Acceptance Criteria | Description | Implementing Step | Verification Suite |
|---|---|---|---|
| **AC-001** | Scheduled habits rendered in Today timeline | Step 1 | `ScheduleTimeline.spec.ts` |
| **AC-002** | 1-Tap habit completion toggle | Step 1 | `ScheduleTimeline.spec.ts` |
| **AC-003** | 1-Tap habit unchecking (streak decrement) | Step 1 | `ScheduleTimeline.spec.ts` |
| **AC-004** | Dynamic bedtime recalculation on habit toggle | Step 1 | `scheduleStore.spec.ts` |
| **AC-005** | Optimistic rollback on server error | Step 1 | `scheduleStore.spec.ts` |
| **AC-006** | Inline Quick Capture presence & `<kbd>c</kbd>` hint | Step 2 | `TodayPage.spec.ts` |
| **AC-007** | Single-key 'c' shortcut focuses inline capture | Step 2 | `useGlobalTaskShortcut.spec.ts` |
| **AC-008** | Successful inline task capture to Inbox | Step 2 | `QuickCapture.spec.ts` |
| **AC-009** | Whitespace-only capture guard | Step 2 | `QuickCapture.spec.ts` |
| **AC-010** | Capacity & energy telemetry ratio display | Step 3 | `CapacityTelemetryCard.spec.ts` |
| **AC-011** | Over-capacity warning state | Step 3 | `CapacityTelemetryCard.spec.ts` |
| **AC-012** | Bedtime trajectory telemetry | Step 3 | `CapacityTelemetryCard.spec.ts` |
| **AC-013** | Dynamic AI Briefing synthesis | Step 3 | `TodayPage.spec.ts` |
| **AC-014** | Deterministic preview states | Step 1, 3, 4 | `TodayPage.spec.ts` |

---

## Verification Plan

Per `AGENTS.md` and repository standards:

1. **Unit Tests**:
   - `pnpm --filter @productivity-os/web test:unit --run`
2. **Type Checking**:
   - `pnpm --filter @productivity-os/web typecheck`
3. **Linting & Code Standards**:
   - `pnpm --filter @productivity-os/web lint`
4. **Manual & Visual Preview Verification**:
   - Verify `http://localhost:5173/today?preview=loading`
   - Verify `http://localhost:5173/today?preview=empty`
   - Verify `http://localhost:5173/today` with normal data

---

## Pre-Implementation Decisions (Must Be Resolved First)

- **D1: Shortcut Precedence on Today**
  - *Status*: OPEN (Recommended: Confirmed)
  - *Proposal*: When on `/today`, pressing single key `'c'` exclusively focuses the inline Quick Capture bar. Users desiring full modal capture with project/goal selection can use `Shift+C` or click the global "+" button.
- **D2: Timeline Habit Integration Layout**
  - *Status*: OPEN (Recommended: Confirmed)
  - *Proposal*: Chronologically integrated timeline inside `ScheduleTimeline.vue`, displaying habits with dedicated icon/streak pill badges and 1-tap toggle controls alongside scheduled task blocks.
- **D3: Capacity Telemetry Placement**
  - *Status*: OPEN (Recommended: Confirmed)
  - *Proposal*: Create `CapacityTelemetryCard.vue` in the right context rail (directly above `DailySummaryCard.vue`), keeping focus metrics separate from capacity/circadian telemetry while dynamically feeding summary insights into `AiBriefing.vue`.

---

## Out of Scope for This Plan

- Modifying backend endpoints in `apps/api` (all required endpoints exist).
- Habit creation, reordering, or phase reconfiguration (managed in `/schedule`).
- Two-way Google/Outlook calendar synchronization.

---

## Change History

- **2026-11-13**: Initial Draft implementation plan authored for Today Web Milestones 3 & 4 (Habit Stacking, Inline Quick Capture, and Capacity Telemetry).
