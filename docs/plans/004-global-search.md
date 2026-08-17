# Plan: Global Search

## Status

Approved — the governing specification
(`docs/specs/ui/global-search.md`) is **Approved** (human, "approve as-is",
2026-08-17). All pre-implementation decisions D1–D6 are resolved
(human-approved plan, 2026-08-17). Implementation may proceed.

## Specification

Primary behavioral source of truth:

- `docs/specs/ui/global-search.md` (Approved)

Acceptance criteria in scope:

- AC-001 open with ⌘K / Ctrl+K
- AC-002 open from TopBar
- AC-003 tasks match by title
- AC-004 projects match by name
- AC-005 goals match by title
- AC-006 results grouped by type
- AC-007 case-insensitive matching
- AC-008 empty result state
- AC-009 keyboard navigation
- AC-010 selecting a result navigates and opens its detail
- AC-011 Escape closes without navigating
- AC-012 user isolation
- AC-013 works in mock mode
- AC-014 query resets on reopen

Supporting decisions and constraints:

- ADR-004 — user isolation (Rule 3)
- `docs/specs/api-integration.md` — feature stores and their load/error/mock
  conventions
- `docs/specs/ui/tasks-and-inbox-ui.md` §11 — task-search precedent
- No backend changes: V1 is client-side over the in-memory stores (spec
  Rule 1, Constraints)

## Architecture

Global search is a new feature module (`features/search/`) that reads the
three existing feature stores (tasks, projects, goals) and the context panel
store. It adds no data fetching and no backend calls:

- `features/search/store.ts` — new: search state (open, query, highlighted
  index) plus derived, grouped results from the tasks/projects/goals stores
  (read-only).
- `features/search/components/SearchOverlay.vue` — new: dialog overlay
  (input, grouped results, empty/loading states, keyboard nav) mounted in
  `AppShell.vue` so it is global across the authenticated shell.
- `app/layouts/AppShell.vue` — mount the overlay.
- `app/layouts/TopBar.vue` — the existing search button opens the overlay
  (its ⌘K hint and "Search tasks, projects, goals…" label already match the
  scope).
- Result landing: the overlay navigates to the owning workspace with an
  `?open=<id>` query; `TasksPage` / `ProjectsPage` / `GoalsPage` honor it in
  their existing `loadAndSelect` (prefer the queried entity over the default
  first item). The context panel opens the entity's detail.

## Step 1 — Search store

- **Files/modules:** `features/search/store.ts` (new)
- **Spec/AC:** AC-003–AC-008, AC-012, AC-013, AC-014 (foundation)
- **Behavior:**
  - State: `open` (bool), `query` (string), `highlightedIndex` (flat
    index). `open()` resets query + selection (AC-014); `close()`.
  - Results derive from the stores with a case-insensitive substring match
    on task title, project name, goal title (AC-003–005, AC-007):
    `SearchResult { type: "task" | "project" | "goal"; id; title; subtitle }`
    where subtitle is the project name (tasks), goal title (projects), or
    null (goals).
  - Grouped lists (`tasks`, `projects`, `goals`) capped at N per group
    (Rule 9); a flat `visibleResults` list drives keyboard nav.
  - Per-group loading flags derived from each store's `status`
    ("loading"/"idle" → loading state, never stale data — Rule 1).
  - Read-only: never mutates the feature stores.
- **Dependencies:** tasks/projects/goals stores; `features/planning/types`
  not needed. Mock mode needs nothing extra — the stores already serve
  mock data, so AC-013 holds by construction (Rule 8).
- **Tests:** group matching per type; case-insensitivity; cap per group;
  empty query → no results; loading flags; no store mutation (AC-012/013).
- **Risks/ambiguities:** D6 (shortcut conflicts) affects only Step 2+; the
  store is unaffected.

## Step 2 — SearchOverlay component

- **Files/modules:** `features/search/components/SearchOverlay.vue` (new)
- **Spec/AC:** AC-001, AC-002, AC-006, AC-008, AC-009, AC-011, AC-014
- **Behavior:**
  - Dialog (`role="dialog"`, `aria-modal`), labeled input, focus moves to
    the input on open and returns to the trigger on close (Rule 4).
  - Renders the store's groups with visible type labels (AC-006); empty
    query shows a hint only; no matches shows the empty state (AC-008);
    per-group loading states.
  - Keyboard: Escape closes (AC-011); ↑/↓ move `highlightedIndex`;
    Enter selects (AC-009); ⌘K / Ctrl+K toggles while closed (global
    `keydown` listener registered on mount, removed on unmount).
  - Selection emits a navigate request (AC-010 handled in Step 4);
    clicking selects too. Reopen resets (AC-014).
  - Styling follows the "Calm Command Center" tokens (surface/border/
    shadow/radius); overlay is dismissible, never blocks the page.
- **Dependencies:** Step 1; `components/ui/*` primitives where suitable.
- **Tests:** component-level: opens with ⌘K and focuses input (AC-001);
  grouped rendering (AC-006); empty state (AC-008); arrow/enter
  navigation (AC-009); Escape closes without selecting (AC-011);
  reopened overlay has empty query (AC-014).
- **Risks/ambiguities:** D6 resolved: ⌘K takes over — it closes any other
  open overlay/dialog and opens search (in-progress dialog form input is
  discarded); Escape closes only the search overlay.

## Step 3 — Shell + TopBar wiring

- **Files/modules:** `app/layouts/AppShell.vue` (edit),
  `app/layouts/TopBar.vue` (edit)
- **Spec/AC:** AC-001, AC-002
- **Behavior:**
  - `AppShell` mounts `<SearchOverlay />` (authenticated shell only — the
    login page never exposes search).
  - `TopBar`'s search button opens the overlay; update its stale
    `title`/placeholder copy ("Search arrives in a later milestone" →
    descriptive) and keep the ⌘K hint.
- **Dependencies:** Step 2.
- **Tests:** manual: ⌘K from any authenticated page opens search (AC-001);
  TopBar click opens it (AC-002); ⌘K on the login page does nothing.
- **Risks/ambiguities:** none beyond D6.

## Step 4 — Result landing

- **Files/modules:** `pages/TasksPage.vue`, `pages/ProjectsPage.vue`,
  `pages/GoalsPage.vue` (edits — each `loadAndSelect` honors `?open=`)
- **Spec/AC:** AC-010
- **Behavior:**
  - The overlay navigates: `router.push({ name, query: { open: id } })`
    per result type (task → "tasks", project → "projects", goal →
    "goals").
  - Each workspace's `loadAndSelect` reads `route.query.open`: if the
    entity exists in the loaded data, open its detail via the context
    panel (`openTask` / `openProject` / `openGoal`); otherwise fall back
    to the current behavior (first item / close).
- **Dependencies:** Step 2; `app/layouts/contextPanelStore`.
- **Tests:** per page: `?open=<existing-id>` opens that entity's detail;
  `?open=<missing-id>` falls back to the default; selecting a search
  result closes the overlay and lands on the workspace with the detail
  open (AC-010).
- **Risks/ambiguities:** the `?open` query is idempotent and survives
  reloads; deleted entities fall back gracefully. No page structural
  changes — only the selection branch in `loadAndSelect`.

## Step 5 — End-to-end verification

- **Files/modules:** none new.
- **Spec/AC:** all.
- **Behavior:** run the stack (or mock mode), then: ⌘K and TopBar open
  (AC-001/002); type substrings covering tasks, projects, goals, case
  variations (AC-003–005, AC-007); verify grouping (AC-006), no-match
  empty state (AC-008), keyboard nav + Enter (AC-009), landing with detail
  open (AC-010), Escape (AC-011), isolation (AC-012), mock mode parity
  (AC-013), reopen resets (AC-014). Check ⌘K with a dialog open per D6.
- **Dependencies:** Steps 1–4.
- **Tests:** manual checklist mapped to AC-001–014.

## Tests

Traceability matrix:

- AC-001 → Step 2 component test + Step 3 manual
- AC-002 → Step 3 manual
- AC-003 → Step 1 store tests + Step 5 manual
- AC-004 → Step 1 store tests + Step 5 manual
- AC-005 → Step 1 store tests + Step 5 manual
- AC-006 → Step 2 component test
- AC-007 → Step 1 store test (case-insensitivity)
- AC-008 → Step 2 component test (empty state)
- AC-009 → Step 2 component test (arrows/enter)
- AC-010 → Step 4 page tests + Step 5 manual
- AC-011 → Step 2 component test (Escape)
- AC-012 → Step 1 store test (only own stores' data)
- AC-013 → Step 5 manual (mock mode parity; holds by construction)
- AC-014 → Step 1 store test + Step 2 component test (reset on open)

## Verification

Before reporting completion (per AGENTS.md):

1. All in-scope acceptance criteria pass (automated where possible, manual
   checklist otherwise).
2. `vue-tsc` and `eslint` pass (web).
3. No unrelated changes introduced (diff review).
4. Completion report: summary, specification references, files changed,
   AC pass/fail evidence, deviations, risks, follow-ups.

## Pre-Implementation Decisions

- **D1:** the spec `docs/specs/ui/global-search.md` is **Approved**
  (human, "approve as-is", 2026-08-17). ✔ resolved
- **D2 (spec O1):** match scope is title/name only (pinned by
  AC-003–005). ✔ resolved by approval
- **D3 (spec O2):** a result opens its detail in the context panel on the
  owning workspace via `?open=<id>` + `loadAndSelect`. ✔ resolved by
  approval
- **D4 (spec O3):** empty query shows a hint only, no recent items.
  ✔ resolved by approval
- **D5 (spec O4/O5):** V1 scope is tasks/projects/goals, client-side;
  server-side search stays a future consideration. ✔ resolved by approval
- **D6 (spec O6):** ⌘K while another overlay/dialog is open — **takes
  over**: pressing ⌘K closes any other overlay (modal dialogs included,
  accepting that in-progress form input in a dialog is discarded) and opens
  the search overlay. ✔ resolved (human, 2026-08-17)

## Out of Scope for This Plan

- Backend changes of any kind (no search endpoint in V1).
- Search over focus sessions, daily plans, Top 3, weekly reviews, settings.
- Fuzzy matching, ranking, operators, filters inside search.
- Search history / recent / saved searches.
- Changes to the Tasks workspace's local search behavior.

## Change History

- Initial plan created against `docs/specs/ui/global-search.md`
  (Approved); D1–D5 resolved by the spec approval, D6 flagged for human
  confirmation.
- Status set to **Approved** after the human approved D6 ("⌘K takes over")
  and said "approve and start implement" (2026-08-17).

## Implementation Status

Implemented (2026-08-17), all five steps:

- **Step 1** — `features/search/store.ts`: read-only search state over the
  tasks/projects/goals stores; case-insensitive substring match on task
  title / project name / goal title; groups capped at 6 (Rule 9); flat
  `visibleResults` + `groupOffsets` for keyboard nav; per-group loading
  derived from store status; query change resets the highlight (AC-014).
- **Step 2** — `features/search/components/SearchOverlay.vue`: dialog with
  autofocused input, focus returns to the TopBar trigger on close (Rule 4),
  group headers, per-group loading rows, "no results" empty state (AC-008),
  ↑/↓/Enter/Escape keyboard nav, backdrop click closes, route change
  closes. Global ⌘K/Ctrl+K listener dispatches `app:close-overlays` before
  opening so other overlays are closed (D6).
- **Step 3** — `<SearchOverlay />` mounted in `AppShell.vue`; TopBar search
  button wired to `search.openSearch()` (stale "later milestone" title
  removed).
- **Step 4** — `TasksPage.vue`, `ProjectsPage.vue`, `GoalsPage.vue` honor
  `?open=<id>` in `loadAndSelect` (search result wins over the default
  first item) plus a `watch` on `route.query.open` for same-page searches
  (AC-010). `UiDialog.vue` and the settings `TimezonePicker.vue` listen for
  `app:close-overlays` and close (D6).
- **Step 5** — `npm run typecheck`, `npm run lint`, `npm run build` all
  pass. Manual acceptance walk-through pending on a running stack
  (make web / make web-mock).

Known issue: the Cline reviewer CLI fails to spawn on this machine
(`Unknown system error -88`), so `scripts/agent-review.sh` could not
produce a review; this is an environment problem, not a code problem.
