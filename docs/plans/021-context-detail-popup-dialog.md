# Plan 021: Context Detail Popup Dialog

## Status

Approved

---

## Specification

### Primary Behavioral Source of Truth

- [context-detail-popup-dialog.md](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/specs/ui/context-detail-popup-dialog.md) (Draft)

### Acceptance Criteria in Scope

- **AC-001:** Workspace Grid Stability
- **AC-002:** Task Detail Modal Rendering
- **AC-003:** Project Detail Modal Rendering
- **AC-004:** Goal Detail Modal Rendering
- **AC-005:** Multi-Modal Dismissal Controls
- **AC-006:** Nested Dialog Stacking Order
- **AC-007:** Cross-Entity Navigation Inside Dialog
- **AC-008:** Global Search Deep-Linking Integration
- **AC-009:** Unified ProjectsPage Dialog State
- **AC-010:** Route Change Auto-Dismissal
- **AC-011:** Clean Initial Page Load on GoalsPage

### Supporting Architecture & Decisions

- **ADR-001:** Specification-Driven Development (SDD workflow gate)
- **ADR-002:** Technology Stack (Vue 3, Pinia, TypeScript, Vite)
- **ADR-005:** API Architecture (Structured DTO contracts and clean client integration)
- **Visual System Spec:** [productivity-os-visual-system.md](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/specs/ui/productivity-os-visual-system.md) (modal overlay design tokens, backdrop blur, elevation)

---

## Architecture

Currently, `AppShell.vue` hosts `ContextPanel.vue` as a persistent 3rd column in a 3-track grid (`auto minmax(0, 1fr) auto`). When opened, the sidebar occupies ~420px, compressing `.workspace` and causing layout shifts, container query recalculations, and inconsistent local workarounds (e.g. `ProjectsPage.vue` rendering local modal dialogs).

The revised architecture converts detail viewing into a shell-level modal popup dialog utilizing `UiDialog`:

```mermaid
flowchart TD
    subgraph AppShell [AppShell.vue Layout]
        Grid[".shell grid: auto 1fr"]
        SideNav[SideNav.vue]
        Workspace["main.workspace (Full remaining width, stable)"]
      
        Grid --> SideNav
        Grid --> Workspace
    end

    subgraph UserTriggers [User Interaction Triggers]
        T1["TasksPage: click task row or board card"]
        T2["TodayPage: click task row"]
        T3["ProjectsPage: click project card"]
        T4["GoalsPage: click goal card"]
        T5["SearchOverlay / URL: ?open=<id>"]
    end

    subgraph Store [contextPanelStore.ts]
        T1 & T2 -->|openTask / toggleTask| ContentState["content: { kind: 'task', taskId }"]
        T3 -->|openProject / toggleProject| ContentState["content: { kind: 'project', projectId }"]
        T4 -->|openGoal / toggleGoal| ContentState["content: { kind: 'goal', goalId }"]
        T5 -->|openTask / openProject / openGoal| ContentState
    end

    subgraph DialogHost [ContextPanel.vue (Shell-Level)]
        ContentState --> UiDialog["UiDialog (:open='panel.isOpen', size='lg')"]
        UiDialog --> DynamicBody{"panel.content.kind"}
        DynamicBody -->|task| TaskPanel[TaskDetailPanel.vue]
        DynamicBody -->|project| ProjectPanel[ProjectDetailPanel.vue]
        DynamicBody -->|goal| GoalPanel[GoalDetailPanel.vue]
    end

    subgraph StackingOrder [Nested Dialog Management]
        TaskPanel -->|Edit task / Reschedule| NestedDialog["NewTaskDialog.vue (UiDialog stacking)"]
        ProjectPanel -->|Edit project| NestedProjectDialog["NewProjectDialog.vue"]
        GoalPanel -->|Complete goal| NestedGoalDialog["CompleteGoalDialog.vue"]
    end
```

### Key Architectural Tenets:

1. **Decoupled Grid Layout:** `.shell` in `AppShell.vue` changes from `grid-template-columns: auto minmax(0, 1fr) auto` to `grid-template-columns: auto 1fr`. The workspace never reflows or resizes when details open or close.
2. **Standardized Modal Experience (`UiDialog`):** `ContextPanel.vue` is refactored from a sliding `<aside>` sidebar to wrap `<UiDialog size="lg">`, gaining backdrop blur (`backdrop-filter: blur(4px)`), centered positioning, accessibility attributes, and responsive adaptations out-of-the-box.
3. **Stacked Dialog Hierarchy:** Because `UiDialog.vue` maintains an internal `openDialogs` array, secondary dialogs opened from within a detail panel (e.g. `NewTaskDialog` for editing, `CompleteGoalDialog`) automatically stack above the detail dialog. Pressing <kbd>Escape</kbd> dismisses only the topmost modal.
4. **Deduplication of Local Dialogs:** `ProjectsPage.vue` currently maintains local `UiDialog` instances for project and task details. These will be removed in favor of delegating to `contextPanelStore`, establishing a single global detail modal.
5. **No Auto-Opening Modals:** `GoalsPage.vue` previously auto-opened the first goal on load and mounted an artificial skeleton to reserve sidebar space. This behavior is removed to keep page arrivals clean.

---

## Step 1 — AppShell Layout Decoupling & Grid Simplification

**Status:** pending

- **Files/modules:**
  - `apps/web/src/app/layouts/AppShell.vue`
- **Spec/AC:** AC-001
- **Behavior:**
  - Update `.shell` CSS grid template from `auto minmax(0, 1fr) auto` to `auto 1fr`.
  - Ensure `.workspace` expands to 100% of the available horizontal space next to `SideNav`.
  - Verify that opening or closing any modal overlay creates zero layout displacement or container query reflow on the workspace.
- **Dependencies:** None
- **Tests:** Verify visual layout in browser and ensure no broken container query widths in `TasksPage` board/list view.
- **Risks/ambiguities:** None.

---

## Step 2 — Refactor ContextPanel into Modal Popup Dialog via UiDialog

**Status:** pending

- **Files/modules:**
  - `apps/web/src/app/layouts/ContextPanel.vue`
  - `apps/web/src/app/layouts/contextPanelStore.ts`
- **Spec/AC:** AC-002, AC-003, AC-004, AC-005, AC-006, AC-007, AC-010
- **Behavior:**
  - Replace the `<aside class="context-panel">` markup and manual fixed-sidebar CSS with `<UiDialog :open="panel.isOpen" :title="panelTitle" size="lg" @close="panel.close()">`.
  - Compute `panelTitle` dynamically:
    - `'task'` -> `"Task details"`
    - `'project'` -> `"Project details"`
    - `'goal'` -> `"Goal details"`
  - Render `TaskDetailPanel`, `ProjectDetailPanel`, and `GoalDetailPanel` dynamically inside `UiDialog`'s default slot.
  - Remove redundant manual `window.addEventListener('keydown', onKeydown)` and custom `.backdrop` styles (since `UiDialog` handles Escape stacking, backdrop click, and `app:close-overlays` natively).
  - Retain `watch(() => route.name, () => panel.close())` to ensure route transitions dismiss open dialogs.
  - Ensure cross-entity clicks inside detail panels (e.g. clicking a task row in `ProjectDetailPanel` calling `panel.openTask(id)`) update the dialog content and header in-place.
- **Dependencies:** `apps/web/src/components/ui/UiDialog.vue`
- **Tests:** Unit test in `ContextPanel.spec.ts` covering dialog open/close, title updates, and dismissal controls.
- **Risks/ambiguities:** Detail panel height should comfortably fit within `UiDialog` max-height (`calc(100vh - 64px)`) with smooth internal scrolling.

---

## Step 3 — Deduplicate and Unify Detail Invocation Across Workspaces

**Status:** pending

- **Files/modules:**
  - `apps/web/src/pages/ProjectsPage.vue`
  - `apps/web/src/pages/GoalsPage.vue`
  - `apps/web/src/pages/TasksPage.vue`
  - `apps/web/src/pages/TodayPage.vue`
- **Spec/AC:** AC-002, AC-003, AC-004, AC-008, AC-009, AC-011
- **Behavior:**
  - In `ProjectsPage.vue`:
    - Remove local `detailProjectId` and `taskDialogId` refs and their local `<UiDialog>` wrappers.
    - Update `onSelectProject(projectId)` to call `panel.toggleProject(projectId)`.
    - Update deep-link watcher `route.query.open` to call `panel.openProject(id)`.
    - Remove redundant watchers for `panel.activeTaskId`.
  - In `GoalsPage.vue`:
    - Remove `panel.openSkeleton()` call from `loadAndSelect`.
    - Remove automatic invocation of `panel.openGoal(store.visibleGoals[0].id)` on clean page arrival.
    - Retain card selection handler calling `panel.toggleGoal(goalId)` and deep-link `route.query.open` handler calling `panel.openGoal(id)`.
  - In `TasksPage.vue` & `TodayPage.vue`:
    - Confirm task clicks in list rows, board cards, and today's schedule smoothly trigger `panel.toggleTask(id)` and open the popup dialog.
    - Confirm `route.query.open` continues to open the task detail popup dialog.
- **Dependencies:** Step 2
- **Tests:** Vitest tests for `ProjectsPage`, `GoalsPage`, and `TasksPage`.
- **Risks/ambiguities:** Ensuring `active` prop on cards/rows continues to react accurately to `panel.activeTaskId`, `panel.activeProjectId`, and `panel.activeGoalId`.

---

## Step 4 — Automated Unit & Component Verification

**Status:** pending

- **Files/modules:**
  - `apps/web/src/app/layouts/__tests__/ContextPanel.spec.ts` (new)
- **Spec/AC:** All ACs (AC-001 through AC-011)
- **Behavior:**
  - Mount `ContextPanel.vue` in Vitest with active Pinia store.
  - Verify that when `panel.openTask('task-1')` is called, `UiDialog` renders with title `"Task details"` and displays `TaskDetailPanel`.
  - Verify that when `panel.openProject('proj-1')` is called, `UiDialog` renders with title `"Project details"` and displays `ProjectDetailPanel`.
  - Verify that when `panel.openGoal('goal-1')` is called, `UiDialog` renders with title `"Goal details"` and displays `GoalDetailPanel`.
  - Verify dismissal via `@close` event resets `panel.isOpen` to false.
  - Verify that route change dismisses open dialog.
- **Dependencies:** Steps 1–3
- **Tests:** `pnpm --filter @productivity-os/web test:unit`
- **Risks/ambiguities:** Mocking child panels or store dependencies cleanly in Vitest.

---

## Tests

### Traceability Matrix


| Acceptance Criteria                               | Implementation Step | Test Suite / Verification                                |
| --------------------------------------------------- | --------------------- | ---------------------------------------------------------- |
| **AC-001** (Workspace Grid Stability)             | Step 1              | Manual visual check + CSS validation                     |
| **AC-002** (Task Detail Modal Rendering)          | Step 2, Step 3      | `ContextPanel.spec.ts` + `TaskBoard.spec.ts`             |
| **AC-003** (Project Detail Modal Rendering)       | Step 2, Step 3      | `ContextPanel.spec.ts`                                   |
| **AC-004** (Goal Detail Modal Rendering)          | Step 2, Step 3      | `ContextPanel.spec.ts`                                   |
| **AC-005** (Multi-Modal Dismissal Controls)       | Step 2              | `ContextPanel.spec.ts`                                   |
| **AC-006** (Nested Dialog Stacking Order)         | Step 2              | `ContextPanel.spec.ts` + `useGlobalTaskShortcut.spec.ts` |
| **AC-007** (Cross-Entity Navigation)              | Step 2              | `ContextPanel.spec.ts`                                   |
| **AC-008** (Global Search Deep-Linking)           | Step 3              | `SearchOverlay.vue` deep link check                      |
| **AC-009** (Unified ProjectsPage Dialog State)    | Step 3              | `ProjectsPage.vue` refactoring review                    |
| **AC-010** (Route Change Auto-Dismissal)          | Step 2              | `ContextPanel.spec.ts`                                   |
| **AC-011** (Clean Initial Page Load on GoalsPage) | Step 3              | `GoalsPage.vue` component check                          |

---

## Verification

Per `AGENTS.md`, execute the following verification pipeline:

1. **Frontend Typecheck:**
   ```bash
   pnpm --filter @productivity-os/web typecheck
   ```
2. **Frontend Linter:**
   ```bash
   pnpm --filter @productivity-os/web lint
   ```
3. **Frontend Unit Tests:**
   ```bash
   pnpm --filter @productivity-os/web test:unit
   ```
4. **Git Diff Review:**
   Verify no unexpected regressions in `AppShell.vue`, `ContextPanel.vue`, `ProjectsPage.vue`, `GoalsPage.vue`, or `TasksPage.vue`.

---

## Pre-Implementation Decisions (must be resolved first)

- **D1: Discontinue Auto-Open of First Goal on GoalsPage (OPEN — Recommended: Yes)**

  - *Context:* In the previous right-sidebar UI, `GoalsPage.vue` auto-opened the first goal on initial page mount (`panel.openGoal(store.visibleGoals[0].id)`) and loaded an artificial skeleton (`panel.openSkeleton()`). In a popup dialog architecture, popping up a modal on initial page arrival obstructs the workspace.
  - *Recommendation:* Disable automatic opening of the first goal on `GoalsPage.vue`. Goals will only open when explicitly clicked by the user or when arriving via deep link `?open=<id>`.
  - *Status:* **OPEN (Awaiting Human Approval)**
- **D2: Remove Redundant Local Dialogs in ProjectsPage (OPEN — Recommended: Yes)**

  - *Context:* `ProjectsPage.vue` previously avoided the right sidebar by rendering local `<UiDialog>` instances for project details (`detailProjectId`) and task details (`taskDialogId`).
  - *Recommendation:* Remove the local `<UiDialog>` instances in `ProjectsPage.vue` and route project selection through `panel.openProject(id)` / `panel.toggleProject(id)`, consolidating all detail dialog presentation into the shell-level `ContextPanel.vue`.
  - *Status:* **OPEN (Awaiting Human Approval)**
- **D3: Cross-Entity Navigation Inside Dialog (OPEN — Recommended: In-Place Transition)**

  - *Context:* When viewing a Goal in the detail popup dialog and clicking a linked Project or Task, or viewing a Project and clicking an active Task, how should navigation behave?
  - *Recommendation:* Replace the dialog content in-place with the selected entity (`openProject` or `openTask`), updating the header title accordingly. Full breadcrumb/back history stack can be deferred to a follow-up enhancement if requested.
  - *Status:* **OPEN (Awaiting Human Approval)**

---

## Out of Scope for This Plan

- Redesigning the interior layout, form controls, or styling of `TaskDetailPanel`, `ProjectDetailPanel`, or `GoalDetailPanel`.
- Modifying backend API endpoints, Spring Boot controllers, or database schemas in `apps/api`.
- iOS application navigation changes in `apps/ios`.

---

## Change History

- **2026-11-14:** Initial Draft authored for converting contextual detail sidebar to centered `UiDialog` popup modal across all views.
