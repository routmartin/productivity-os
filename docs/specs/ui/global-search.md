# Global Search

**Status:** Approved

## Problem

The app has one entry point to find anything — the TopBar search field
("Search tasks, projects, goals…" with a ⌘K hint) — but it is a placeholder
("Search arrives in a later milestone"). Users who want to jump to a task,
project, or goal must navigate to each workspace and use its local filters.
With more data on the server, scanning three separate lists is slow, and the
existing task-search spec (`docs/specs/ui/tasks-and-inbox-ui.md` §11) covers
only the Tasks workspace. There is no single, keyboard-first way to locate
anything in the product.

## Goal

Provide a global search overlay that finds the signed-in user's own tasks,
projects, and goals by title/name from anywhere in the app, opened with ⌘K
(or Ctrl+K) or the TopBar search button, navigable entirely by keyboard.

V1 searches the data already loaded in the app's feature stores — no new
backend endpoint is required, and mock/real mode behave identically.

## User Story

As a user, I want to press ⌘K, type part of a task, project, or goal name,
and jump straight to it, so that I never have to hunt through workspaces to
find my own work.

## Behavior

- Pressing ⌘K (Meta+K) or Ctrl+K anywhere in the app opens the search
  overlay with the input focused. Pressing it again, or pressing Escape,
  closes it.
- Clicking the TopBar search field opens the same overlay.
- Typing filters the signed-in user's tasks (by title), projects (by name),
  and goals (by title) with a case-insensitive substring match. Results are
  grouped by type ("Tasks", "Projects", "Goals").
- ↑/↓ move the selection across the flattened result list; Enter opens the
  selected result; clicking a result opens it too. Selecting a result closes
  the overlay and navigates to that entity's workspace with its detail open
  (the existing context panel).
- A query with no matches shows an empty state. An empty query shows nothing
  to select (a hint only).
- Reopening the overlay resets the previous query and selection.
- The overlay follows the "Calm Command Center" visual system and never
  blocks the underlying page's behavior (it is a dismissible overlay).

## Rules

1. Search runs entirely client-side over the feature stores (tasks,
   projects, goals); V1 issues no network requests and requires no backend
   change. If a store has not finished loading, its group shows a loading
   state instead of stale or empty results.
2. Matching is a case-insensitive substring test against the task title,
   project name, or goal title. No fuzzy matching, prefix ranking, or
   operators in V1.
3. Only the signed-in user's own data is searchable — the stores are
   user-scoped and never contain another user's data (ADR-004).
4. ⌘K (Meta+K) and Ctrl+K both toggle the overlay; Escape closes it; ↑/↓
   navigate; Enter selects. Focus moves into the input on open and returns
   to the trigger on close.
5. Selecting a result closes the overlay and navigates to the entity's
   workspace with its detail open via the existing context panel
   (`openTask` / `openProject` / `openGoal`); the route changes to the
   owning workspace.
6. The overlay is stateless: opening it always starts from an empty query.
7. Keyboard and click behavior must be accessible: the overlay is a dialog
   (`role="dialog"`), results carry `aria-selected`, and the input has an
   accessible label.
8. Mock mode (`VITE_USE_MOCK_DATA=true`) and real mode behave identically,
   because the search reads the same in-memory stores.
9. Long result lists are capped per group (top N, scrollable); the cap is a
   presentation detail, not a data limit.

## Constraints

- No new backend endpoints in V1 (per the endpoint contract rule, backend
  changes require human approval; none is needed).
- The feature must not change store data, fetch new data, or mutate domain
  objects — it only reads the stores.
- Uses the existing Vue 3 + Pinia stack and the existing TopBar trigger;
  no new dependencies.
- Global keyboard handling must not conflict with the timezone picker,
  dialogs, or the focus timer's shortcuts.

## Acceptance Criteria

### AC-001 — Opens with keyboard shortcut

Given a signed-in user on any page,
when they press ⌘K (or Ctrl+K),
then the search overlay opens with the input focused.

### AC-002 — Opens from the TopBar

Given a signed-in user,
when they click the TopBar search field,
then the search overlay opens.

### AC-003 — Tasks match by title

Given a signed-in user with loaded tasks,
when they type a substring that appears in a task title,
then that task appears under a "Tasks" group.

### AC-004 — Projects match by name

Given a signed-in user with loaded projects,
when they type a substring that appears in a project name,
then that project appears under a "Projects" group.

### AC-005 — Goals match by title

Given a signed-in user with loaded goals,
when they type a substring that appears in a goal title,
then that goal appears under a "Goals" group.

### AC-006 — Results are grouped

Given search results exist,
then they are rendered in type groups with visible labels
("Tasks", "Projects", "Goals").

### AC-007 — Case-insensitive matching

Given a task titled "Ship the mobile app",
when the user types "MOBILE",
then the task is still matched.

### AC-008 — Empty result state

Given a query that matches nothing,
then the overlay shows an empty state and no selectable results.

### AC-009 — Keyboard navigation

Given an open overlay with results,
when the user presses ↑/↓,
then the selection moves; pressing Enter opens the selected result.

### AC-010 — Selecting a result navigates

Given an open overlay,
when the user selects a task result,
then the overlay closes and the task's detail opens in its workspace;
the same holds for project and goal results.

### AC-011 — Escape closes without navigating

Given an open overlay,
when the user presses Escape,
then the overlay closes, nothing is selected or opened, and focus returns
to the trigger.

### AC-012 — User isolation

Given any search query,
when the results are inspected,
then they contain only the signed-in user's own tasks, projects, and goals.

### AC-013 — Works in mock mode

Given `VITE_USE_MOCK_DATA=true` (no backend),
when the user opens the overlay and searches,
then matching behaves identically to real mode.

### AC-014 — Query resets on reopen

Given a completed search,
when the overlay is reopened,
then the input is empty and no result is selected.

## Edge Cases

- The overlay opens before a store finishes loading: that group shows a
  loading state and populates when ready; it never shows stale data.
- The overlay is open and the route changes (e.g., keyboard navigation or a
  dialog): the overlay closes.
- Enter with no selection: opens the first result (when any exist).
- A fresh account with no tasks/projects/goals: each group shows its empty
  state; the overall overlay still works.
- Very long result lists: capped per group with scrolling.
- The timezone picker or a dialog is open and ⌘K is pressed: the overlay
  should not fight the open control (it may close it first or be ignored —
  flagged as an implementation detail, see Open Question 6).

## Out of Scope

- Server-side search endpoint, ranking, or fuzzy matching (see Open
  Question 5).
- Searching focus sessions, daily plans, Top 3, weekly reviews, settings, or
  account data.
- Search history, recent searches, or saved searches.
- Advanced query syntax (quotes, `type:`, operators, status filters).
- Search within the Tasks workspace's local search — that behavior stays per
  `docs/specs/ui/tasks-and-inbox-ui.md` §11.

## Dependencies

- `docs/specs/api-integration.md` — feature stores, load/error/mock
  conventions the search reads from.
- `docs/decisions/ADR-004-authentication-user-isolation.md` — search is
  scoped to the user's own data (Rule 3).
- `docs/specs/ui/tasks-and-inbox-ui.md` §11 — existing task-search precedent
  (title matching, clear action, empty state).
- Feature stores (`features/tasks`, `features/projects`, `features/goals`)
  and the context panel store (`openTask` / `openProject` / `openGoal`).
- `docs/specs/ui/productivity-os-visual-system.md` — overlay presentation.

## Open Questions

1. **Match scope:** should matching also cover descriptions (task
   description, project description, goal description)? V1 is title/name
   only.
2. **Result landing:** a result opens the entity's detail in the context
   panel on its workspace (recommended, uses existing behavior) — confirm
   this is preferred over scroll-and-highlight in the list.
3. **Empty query:** show nothing but a hint (V1) vs. a "recent items" list.
4. **Entity scope:** confirm V1 covers only tasks, projects, and goals
   (matching the TopBar placeholder), not focus sessions or daily plans.
5. **Server-side search:** client-side search works while the app loads
   full collections. Is a backend search endpoint a future requirement
   (scale, mobile), or is client-side acceptable indefinitely?
6. **Shortcut conflicts:** pressing ⌘K while the timezone picker or
   another overlay is open — **resolved (2026-08-17): ⌘K takes over.** It
   closes any other overlay/dialog and opens the search overlay;
   in-progress form input in a closed dialog is discarded. Escape closes
   only the search overlay.
## Change History

- Promoted to Approved by human ("approve as-is", 2026-08-17). V1
  behavior is pinned by the acceptance criteria: title/name-only matching
  (AC-003–005), context-panel landing (AC-010), hint-only empty query
  (AC-014), tasks/projects/goals scope. Open Question 6 resolved by human
  (2026-08-17): ⌘K takes over — it closes any other overlay and opens the
  search overlay. The remaining Open Questions are future/deferred
  considerations, not V1 blockers.
- Initial Draft created for the Global Search feature (TopBar placeholder
  "Search arrives in a later milestone").
