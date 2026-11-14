# Context Detail Popup Dialog

## Status

Approved

## Problem

Currently, inspecting item details across tasks, projects, and goals relies on a persistent right-side contextual panel (`ContextPanel.vue`) embedded directly in the application layout grid inside `AppShell.vue`:

```css
.shell {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr) auto;
  height: 100vh;
  overflow: hidden;
}
```

This side-panel layout suffers from several key UX and architectural flaws:

1. **Workspace Layout Reflow & Squeeze:** Opening the side panel allocates horizontal space (`var(--panel-width)`, ~420px), squeezing the central `.workspace` column. This forces immediate container query re-evaluations, compresses table and Kanban board columns, truncates titles, and degrades readability across dense productivity views.
2. **Artificial Loading Skeletons:** To mitigate jarring layout shifts on initial load, pages like `GoalsPage.vue` trigger `panel.openSkeleton()` before data loads, reserving space artificially and auto-opening the first goal on arrival, creating an unwanted master-detail paradigm.
3. **Fragmented Detail Patterns:** Because the right sidebar was disruptive, `ProjectsPage.vue` bypassed `ContextPanel.vue` entirely and implemented local `UiDialog` modals for project details and nested task details, causing architectural inconsistency across pages.
4. **Responsive Breakpoint Complexity:** Below 1100px viewports, `ContextPanel.vue` had to switch from an in-grid sidebar to a `fixed` drawer with a custom backdrop overlay, creating dual rendering modes and unpredictable z-index collisions with other modals.

## Goal

Unify all detail viewing across tasks, projects, and goals into a centered, accessible modal popup dialog utilizing the core design-system component `UiDialog`.

The unified detail popup dialog will:

- Provide a focused, distraction-free container (`size="lg"` / 820px max-width) with backdrop blur (`backdrop-filter: blur(4px)`).
- Eliminate workspace squeezing in `AppShell.vue`: `.shell` becomes `grid-template-columns: auto 1fr`, giving the workspace full, stable viewport width at all times without layout reflows when details are opened or closed.
- Seamlessly render `TaskDetailPanel`, `ProjectDetailPanel`, and `GoalDetailPanel` dynamically based on `contextPanelStore` state.
- Support comprehensive dismissal mechanics: <kbd>Escape</kbd> key, explicit close button (<kbd>X</kbd>), backdrop overlay click, and navigation dismissal (`app:close-overlays` and route transitions).
- Leverage `UiDialog`'s built-in stacking order so secondary modals (e.g. edit task, complete goal, delete confirmations) stack safely on top and dismiss without closing the underlying detail dialog.
- Eliminate fragmented local detail dialogs in `ProjectsPage.vue` and remove disruptive auto-opening skeletons on `GoalsPage.vue`.

## User Story

As an authenticated user managing my tasks, schedule, projects, and goals,
I want clicking any item's detail view to open in a centered modal popup dialog,
so that my workspace layout remains wide and stable, and I can inspect and edit item context without visual layout shift.

## Behavior

- **Triggering Detail Views:**
  - In `TasksPage.vue` (list rows, board cards): clicking an item calls `panel.openTask(taskId)` (or `toggleTask`), opening the detail popup dialog.
  - In `TodayPage.vue` (today's tasks list): clicking a task row calls `panel.openTask(taskId)`.
  - In `ProjectsPage.vue` (project cards): clicking a project card calls `panel.openProject(projectId)`.
  - In `GoalsPage.vue` (goal cards): clicking a goal card calls `panel.openGoal(goalId)`.
  - In `SearchOverlay.vue` (global search results): selecting a search result navigates to `/tasks?open=<id>`, `/projects?open=<id>`, or `/goals?open=<id>`, automatically opening the detail popup dialog for that entity.
- **Dialog Sizing & Presentation:**
  - The dialog renders centered on screen with `size="lg"` (`max-width: 820px`, `max-height: calc(100vh - 64px)`).
  - The backdrop overlay dims the background with `var(--surface-overlay)` and applies `backdrop-filter: blur(4px)`.
  - The dialog container features elevated elevation (`var(--shadow-panel)`), rounded corners (`var(--radius-lg)`), and smooth entrance transitions (`translateY(10px)` fade-in).
- **Header & Title Binding:**
  - Displays the contextual title in the dialog header:
    - Task details: `"Task details"`
    - Project details: `"Project details"`
    - Goal details: `"Goal details"`
  - An accessible close button (`aria-label="Close"`) with an `<X />` icon sits at the top right of the dialog header.
- **Cross-Entity Navigation Inside Dialog:**
  - If a user clicks a linked project inside `GoalDetailPanel.vue`, `panel.openProject(projectId)` updates the dialog content to that project in-place without closing the modal.
  - If a user clicks a linked task inside `ProjectDetailPanel.vue` or `GoalDetailPanel.vue`, `panel.openTask(taskId)` updates the dialog content to that task in-place.
- **Dismissal & Stacking Order:**
  - Pressing <kbd>Escape</kbd> dismisses the dialog if it is the topmost dialog registered in `UiDialog`.
  - Clicking the close button (<kbd>X</kbd>) or clicking directly on the blurred backdrop overlay closes the dialog.
  - Triggering Global Search (`⌘K` / `Ctrl+K`) emits `app:close-overlays`, automatically closing the detail dialog.
  - Navigating to another route closes the dialog.
  - When a user opens an edit dialog (e.g. `NewTaskDialog` from `TaskDetailPanel`), the edit dialog registers as topmost. Pressing <kbd>Escape</kbd> dismisses only the edit dialog, leaving the detail dialog visible beneath.
- **Active State Highlighting:**
  - While the detail dialog is open, the originating item in the workspace (list row, board card, project card, goal card) reflects an active visual state through `panel.activeTaskId`, `panel.activeProjectId`, or `panel.activeGoalId`.
  - Upon dialog dismissal (`panel.close()`), active highlights clear immediately.

## Rules

1. **Rule 1 — Full-Width Workspace Stability:** `.shell` in `AppShell.vue` must define `grid-template-columns: auto 1fr` (SideNav + Workspace). The workspace must never allocate grid space to detail views, ensuring zero container reflow or column squeeze when details open or close.
2. **Rule 2 — Single Source of Truth for Detail Dialogs:** All contextual detail views (`task`, `project`, `goal`) must render through the shell-level `ContextPanel.vue` powered by `UiDialog`. Local modal duplicates (such as those in `ProjectsPage.vue`) must be removed in favor of `contextPanelStore`.
3. **Rule 3 — Standardized Dialog Sizing:** Detail modals must default to `size="lg"` (820px max-width). Responsive constraints down to mobile viewports (<= 640px) must inherit `UiDialog`'s padding and full-height adaptations.
4. **Rule 4 — Backward-Compatible Store API:** `contextPanelStore` must preserve its existing public API:
   - State/Getters: `isOpen`, `content`, `activeTaskId`, `activeProjectId`, `activeGoalId`, `isSkeleton`
   - Actions: `openTask(id)`, `openProject(id)`, `openGoal(id)`, `openSkeleton()`, `close()`, `toggleTask(id)`, `toggleProject(id)`, `toggleGoal(id)`
5. **Rule 5 — Dismissal Invariants:** The detail dialog must be dismissible via:
   - <kbd>Escape</kbd> key when topmost
   - Top-right close button (<kbd>X</kbd>)
   - Backdrop overlay click (`@click.self`)
   - Global `app:close-overlays` event
   - Route transitions (`route.fullPath` change)
6. **Rule 6 — Nested Dialog Independence:** Secondary dialogs opened from within detail panels (e.g. `NewTaskDialog`, `CompleteGoalDialog`, `ReopenGoalDialog`) must leverage `UiDialog`'s stacking registration (`openDialogs`). Dismissing a child dialog must never inadvertently dismiss the underlying detail modal.
7. **Rule 7 — Clean Page Entry (No Auto-Popups):** Navigating to a page (including `GoalsPage.vue` and `TasksPage.vue`) must never automatically pop up a modal dialog on clean page loads. Modals must open only in response to explicit user interaction or deep-link query parameters (`?open=<id>`).
8. **Rule 8 — Deep-Link Parity:** Opening any view with `?open=<id>` (from Global Search, notifications, or direct URL) must open the corresponding popup dialog once the store data is ready.

## Constraints

- **ADR Compliance:** Complies with [ADR-001](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/decisions/ADR-001-spec-driven-development.md) (SDD workflow), [ADR-002](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/decisions/ADR-002-technology-stack.md) (Vue 3, Pinia, TypeScript), and [ADR-005](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/decisions/ADR-005-api-architecture.md).
- **Zero Backend Changes:** Does not introduce, alter, or require any changes to backend APIs or DTO contracts in `apps/api`.
- **Existing Component Reuse:** Must utilize the existing `apps/web/src/components/ui/UiDialog.vue` component rather than introducing a separate dialog wrapper or third-party modal library.
- **Accessibility:** Must maintain WAI-ARIA modal dialog accessibility standards: `role="dialog"`, `aria-modal="true"`, accessible label via header title, keyboard focus trapping, and focus return on close.

## Acceptance Criteria

### AC-001 — Workspace Grid Stability

Given an authenticated user viewing any page in `AppShell.vue` (e.g. Tasks, Projects, Goals, Today),
When a detail popup dialog is opened, switched, or closed,
Then the `.shell` layout remains `grid-template-columns: auto 1fr`,
And `.workspace` retains its exact horizontal width and does not trigger container query reflows or column compression.

### AC-002 — Task Detail Modal Rendering

Given an authenticated user on `TasksPage.vue` (list or board view) or `TodayPage.vue`,
When the user clicks a task row or board card,
Then a centered modal popup dialog opens using `UiDialog` with `size="lg"`,
And the dialog displays the title `"Task details"`,
And renders `TaskDetailPanel` with the selected task's data,
And a backdrop blur overlay (`backdrop-filter: blur(4px)`) covers the underlying workspace.

### AC-003 — Project Detail Modal Rendering

Given an authenticated user on `ProjectsPage.vue`,
When the user clicks a project card,
Then a centered modal popup dialog opens using `UiDialog` with `size="lg"`,
And the dialog displays the title `"Project details"`,
And renders `ProjectDetailPanel` with the selected project's data.

### AC-004 — Goal Detail Modal Rendering

Given an authenticated user on `GoalsPage.vue`,
When the user clicks a goal card,
Then a centered modal popup dialog opens using `UiDialog` with `size="lg"`,
And the dialog displays the title `"Goal details"`,
And renders `GoalDetailPanel` with the selected goal's data.

### AC-005 — Multi-Modal Dismissal Controls

Given an open detail popup dialog for a task, project, or goal,
When the user triggers any of the following dismissal actions:

- Clicks the header close button (<kbd>X</kbd>)
- Clicks outside the dialog on the backdrop overlay
- Presses the <kbd>Escape</kbd> key
  Then the detail popup dialog closes immediately,
  And `contextPanelStore.isOpen` becomes `false` (`content = null`),
  And the originating item in the workspace is no longer highlighted.

### AC-006 — Nested Dialog Stacking Order

Given an open task detail popup dialog,
When the user clicks the "Edit task" action to open `NewTaskDialog`,
Then the edit dialog opens stacked on top of the task detail dialog,
And pressing <kbd>Escape</kbd> closes only the `NewTaskDialog`, leaving the task detail dialog open,
And a subsequent press of <kbd>Escape</kbd> closes the task detail dialog.

### AC-007 — Cross-Entity Navigation Inside Dialog

Given an open `GoalDetailPanel` in the popup dialog,
When the user clicks a linked project inside the panel,
Then the dialog content transitions in-place to render `ProjectDetailPanel` for that project,
And the dialog header updates to `"Project details"`,
And the dialog backdrop remains mounted without flickering.

### AC-008 — Global Search Deep-Linking Integration

Given an authenticated user using Global Search (`SearchOverlay`),
When the user selects a search result for a task, project, or goal,
Then the application navigates to the respective page with `?open=<id>`,
And upon page data load, the corresponding detail popup dialog opens automatically.

### AC-009 — Unified ProjectsPage Dialog State

Given the updated `ProjectsPage.vue`,
When inspecting the component implementation,
Then redundant local `UiDialog` instances for project details and task details are removed,
And selecting a project card delegates directly to `contextPanelStore.toggleProject(id)`.

### AC-010 — Route Change Auto-Dismissal

Given an open detail popup dialog on any page,
When the user navigates to another route via the side navigation or browser back/forward buttons,
Then the detail popup dialog closes automatically and `contextPanelStore.close()` is called.

### AC-011 — Clean Initial Page Load on GoalsPage

Given an authenticated user navigating to `/goals`,
When the page loads initially with visible goals,
Then no modal dialog or skeleton popup is automatically opened,
And the user can view the full goals grid unobstructed until clicking a card.

## Edge Cases

- **Deleted Entity in Open Dialog:** If a user deletes a task, project, or goal from within its detail panel, the deletion handler calls `panel.close()`, smoothly dismissing the popup dialog and returning to the workspace without orphaned state.
- **Global Search Shortcut Takeover (`⌘K`):** If a detail popup dialog is open and the user presses `Cmd+K` or `Ctrl+K`, the `app:close-overlays` event dismisses the detail dialog immediately before the search overlay opens.
- **Non-Existent ID in Query (`?open=unknown`):** If a deep-link query parameter specifies an ID not found in the store, the page ignores the query or calls `panel.close()`, preventing an empty or broken modal dialog.
- **Rapid Item Toggling:** If a user rapidly clicks different items in a list or board, `contextPanelStore` updates `content` reactively, updating the dialog body without remounting the dialog or breaking backdrop focus trapping.

## Out of Scope

- Redesigning the internal layouts or visual styling of `TaskDetailPanel`, `ProjectDetailPanel`, or `GoalDetailPanel`.
- Modifying backend endpoints, DTOs, or database schemas.
- iOS platform detail presentation in `apps/ios` (which follows native iOS SwiftUI navigation paradigms).

## Dependencies

- `apps/web/src/components/ui/UiDialog.vue` — foundation modal dialog component providing backdrop blur, stacking order, and escape dismissal.
- `apps/web/src/app/layouts/contextPanelStore.ts` — Pinia store governing detail modal state.
- `apps/web/src/features/tasks/components/TaskDetailPanel.vue` — task detail content component.
- `apps/web/src/features/projects/components/ProjectDetailPanel.vue` — project detail content component.
- `apps/web/src/features/goals/components/GoalDetailPanel.vue` — goal detail content component.

## Open Questions

- **Q1:** Should navigation history (breadcrumbs or "Back" button) be introduced for cross-entity navigation inside the dialog (e.g. Goal -> Project -> Task), or is in-place switching sufficient? *(Tracked in Plan Decision D3).*
- **Q2:** Should `GoalsPage.vue` remove auto-opening on load? *(Tracked in Plan Decision D1).*

## Change History

- **2026-11-14:** Initial Draft authored to replace right contextual sidebar with centered `UiDialog` popup modal across all views.
