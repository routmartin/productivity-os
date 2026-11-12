# Global Task Creation Shortcut ('c')

**Status:** Approved

## 1. Problem

Capturing a new task currently requires the user to navigate specifically to the Tasks workspace (`/tasks`) and click the primary "New Task" button, or navigate to Inbox (`/inbox`) and type into the inline QuickCapture input.

In fast-paced, keyboard-centric productivity environments (modeled after industry standards like Linear, Superhuman, and Gmail), power users expect to capture thoughts, todos, and follow-ups immediately from anywhere in the application without context switching or reaching for the mouse. Forcing page navigation breaks concentration, slows capture speed, and violates the "Calm Command Center" principle of reducing cognitive friction.

## 2. Goal

Provide an omnipresent, keyboard-first task capture shortcut: pressing the single key `'c'` anywhere in the authenticated web application immediately opens the `NewTaskDialog` with the task title input autofocused.

The shortcut must be bulletproof against false triggers:
- It must never intercept typing inside text inputs, textareas, selects, or rich text editors.
- It must never interfere with operating system or browser shortcuts (e.g., `Cmd+C` or `Ctrl+C` for clipboard copy).
- It must not fire when another modal dialog or overlay (e.g., Global Search `⌘K`, confirmation dialogs) is already open.
- It must provide clear discoverability in the UI so users naturally discover the shortcut.

## 3. User Story

As an authenticated user working in any section of Productivity OS (Today, Inbox, Tasks, Projects, Goals, Schedule, Settings, or AI),
I want to press `c` on my keyboard,
So that I can immediately capture a new task without interrupting my current workflow or navigating away from my screen.

## 4. Behavior

- **Keystroke Detection:** When an authenticated user is viewing any screen wrapped by the application shell and presses the key `'c'` (without modifier keys `Cmd`, `Ctrl`, or `Alt`), the global task creation dialog opens immediately.
- **Autofocus:** Upon opening, keyboard focus is automatically shifted into the "Task title" input field, enabling instant typing.
- **Modal Display:** The `NewTaskDialog` is rendered as an accessible modal overlay centered on screen with a dimming backdrop, consistent with the visual language in `docs/specs/ui/productivity-os-visual-system.md`.
- **Dismissal:**
  - Pressing `Escape` closes the dialog.
  - Clicking the close button (`X`) or the backdrop overlay closes the dialog.
  - Submitting the form (pressing `Enter` in the title field or clicking "Create Task") saves the task and closes the dialog.
- **Task Persistence & Store Reactivity:** Creating a task through the global dialog calls `tasksStore.addTask(...)`, updating in-memory store collections, triggering backend persistence (or mock dispatch), and updating reactive badges (such as the Inbox count in the sidebar) without requiring a manual refresh.
- **Workspace Retention:** Creating a task from non-task workspaces (e.g., Projects, Goals, Settings, Today) retains the user on their current page without an unwanted redirect, showing feedback that the item was captured.
- **Discoverability:** The primary "New Task" button in `TasksPage.vue` (and optional chrome triggers) displays a styled shortcut hint badge `<kbd class="kbd tnum">c</kbd>`.

## 5. Rules

1. **Rule 1 — Trigger Key:** The shortcut triggers only on the character key `'c'` (case-insensitive: lowercase `c` or uppercase `C`).
2. **Rule 2 — Strict Modifier Guard:** The shortcut must be completely ignored if `event.metaKey`, `event.ctrlKey`, or `event.altKey` is active. Standard clipboard copy (`Cmd+C` on macOS, `Ctrl+C` on Windows/Linux) and OS window/application accelerators must never be intercepted or prevented.
3. **Rule 3 — Typing Target Guard:** The shortcut must be ignored whenever the event target is an interactive text input element:
   - `<input>`
   - `<textarea>`
   - `<select>`
   - Any element with `isContentEditable === true` or inside an ancestor container with `contenteditable="true"`.
4. **Rule 4 — Overlay & Modal Guard:** The shortcut must not fire if another dialog or overlay is currently open:
   - Any modal dialog registered in `UiDialog` (`hasOpenDialog() === true`).
   - The Global Search overlay (`useSearchStore().open === true`).
   - The `NewTaskDialog` itself is already visible.
   Unlike Global Search (`⌘K`), which deliberately takes over and dismisses other overlays, single-key `'c'` must never close an active dialog or steal focus from an in-progress modal workflow.
5. **Rule 5 — Form Reset on Open:** Opening the dialog resets all fields to an empty draft state (empty title, default Inbox destination, no initial project/goal/due date/priority), unless pre-seeded by contextual page actions.
6. **Rule 6 — Route Change Cleanup:** If the browser route changes while the dialog is open (e.g., user presses browser back/forward buttons), the dialog must immediately close to prevent detached modal states.
7. **Rule 7 — Authenticated Scope Only:** The shortcut listener is mounted only within the authenticated `AppShell.vue` layout. Unauthenticated screens (such as `/login` or `/register`) must never register the shortcut listener or mount the task dialog.
8. **Rule 8 — Single Global Instance:** The creation modal must have a single global instance mounted in `AppShell.vue`. Local duplicate creation dialogs in `TasksPage.vue` must be removed in favor of controlling the global dialog via `tasksStore`. Contextual task editing in `TaskDetailPanel.vue` remains isolated.

## 6. Constraints

- **No Backend Changes:** Task creation must utilize the existing backend endpoints (`POST /api/v1/tasks`, `POST /api/v1/tasks/{id}/plan`, `POST /api/v1/tasks/{id}/start`, `PUT /api/v1/tasks/{id}/project`) via `useTasksStore.addTask(draft)`.
- **Mock & Real API Parity:** Must function identically in both mock mode (`VITE_USE_MOCK_DATA=true`) and real backend mode.
- **Zero External Dependencies:** Implemented using native browser DOM events (`keydown`), Vue 3 reactivity, and existing Pinia stores.
- **Accessibility:** Must comply with WAI-ARIA modal dialog specifications (`role="dialog"`, `aria-modal="true"`, focus trapping within dialog, focus return on dismiss).

## 7. Acceptance Criteria

### AC-001 — Global 'c' Key Opens New Task Dialog
Given an authenticated user viewing any page in the application shell (e.g., `/today`, `/tasks`, `/inbox`, `/projects`, `/goals`, `/schedule`, `/settings`, `/ai`),
When the user presses the `c` key with no input focused,
Then the `NewTaskDialog` modal opens immediately, and keyboard focus is placed into the "Task title" input field.

### AC-002 — Ignored When Focused in Form Inputs and Textareas
Given an authenticated user with focus inside an `<input>`, `<textarea>`, `<select>`, or contenteditable element,
When the user presses the `c` key,
Then the default typing behavior occurs (a letter 'c' is entered into the field), the event is not prevented, and the New Task dialog does not open.

### AC-003 — Modifier Keys Preserve Clipboard Copy (Cmd+C / Ctrl+C)
Given an authenticated user on any screen with or without text selected,
When the user presses `Cmd+C` (macOS) or `Ctrl+C` (Windows/Linux) or `Alt+C`,
Then the default system copy / shortcut behavior is executed, `event.preventDefault()` is not called, and the New Task dialog does not open.

### AC-004 — Ignored When Another Modal or Overlay Is Open
Given an overlay or dialog is currently open (such as Global Search ⌘K or a `UiDialog` confirmation prompt),
When the user presses the `c` key,
Then the keystroke is ignored, the active overlay remains in its current state, and the New Task dialog does not open.

### AC-005 — Ignored When New Task Dialog Is Already Open
Given the New Task dialog is already open on the screen,
When the user presses `c` while focus is on a non-input element inside the dialog (e.g., on a button or dialog header),
Then the dialog does not re-open, reset, or flash.

### AC-006 — Dismissible via Escape, Close Button, or Backdrop
Given the New Task dialog has been opened via the `c` keyboard shortcut,
When the user presses the `Escape` key, clicks the dialog close button (`X`), or clicks the backdrop outside the dialog panel,
Then the dialog closes and the in-progress draft is dismissed.

### AC-007 — Successful Task Creation from Any Workspace
Given the New Task dialog is opened via `c` while on a non-task page (e.g., `/projects` or `/today`),
When the user fills in a task title and submits the form,
Then the task is created via `tasksStore.addTask(...)`, the sidebar Inbox badge count increments (if destination is Inbox), and the dialog closes while keeping the user on their current workspace.

### AC-008 — Dialog Closes on Route Change
Given the New Task dialog is open,
When the route fullPath changes (e.g. back navigation),
Then the New Task dialog closes automatically.

### AC-009 — Visual Shortcut Discoverability Hint
Given an authenticated user viewing the Tasks workspace (`/tasks`),
When viewing the primary "New Task" button in the hero actions area,
Then a shortcut hint badge `<kbd class="kbd tnum">c</kbd>` is displayed inside or adjacent to the button.

### AC-010 — Unauthenticated Screens Do Not Listen or Open
Given an unauthenticated visitor on the `/login` or `/register` route,
When the visitor presses the `c` key outside any input field,
Then no New Task dialog opens and no errors occur.

## 8. Edge Cases

- **Rapid Double Press:** If a user rapidly taps `c` twice in succession, the first press opens the dialog and moves focus to the title input; the second press falls under the `isTypingTarget` guard and types `c` into the title.
- **Caps Lock and Shift Key:** If Caps Lock is on or Shift is held (`Shift+C`), pressing `C` while not in an input target opens the dialog identically to lowercase `c`.
- **IME / Non-Latin Input Methods:** When an IME composition session is active (`event.isComposing === true`), the key event must be ignored to prevent interrupting composition.
- **Focus Return on Dismissal:** When dismissed via `Escape` or backdrop click, focus should gracefully return to the previous active element or `document.body` without keyboard trapping.

## 9. Out of Scope

- Inline command palette task capture (e.g., quick capture bar with natural language date parsing inside the search overlay).
- User-configurable keyboard shortcut rebinding (custom shortcut key preferences).
- Persistent draft restoration across page refreshes (localStorage caching of unsaved task drafts).
- Global keyboard shortcuts on mobile touch screens (no physical keyboard attached).

## 10. Dependencies

- Layout Shell: `apps/web/src/app/layouts/AppShell.vue`
- Task Components: `apps/web/src/features/tasks/components/NewTaskDialog.vue`
- UI Components: `apps/web/src/components/ui/UiDialog.vue`
- Task Store: `apps/web/src/features/tasks/store.ts`
- Search Store: `apps/web/src/features/search/store.ts`
- Tasks Page: `apps/web/src/pages/TasksPage.vue`

## 11. Open Questions

- **O1 (D1): Chrome Discoverability:** Should a compact "New Task" icon button (`+` with tooltip `New task (c)`) be placed in `TopBar.vue` alongside the Global Search trigger (`⌘K`) for mouse users navigating non-task workspaces?
- **O2 (D2): Shift Key Behavior:** Confirm whether `Shift+C` should open the dialog identically to unshifted `c` (Linear standard) or require strictly lowercase `c`.
- **O3 (D3): Post-Creation Navigation:** Confirm that creating a task from `/projects` or `/goals` keeps the user on that page with a subtle toast notification rather than redirecting to `/tasks`.

## 12. Change History

- **2026-11-12:** Initial Draft created for global `'c'` keyboard shortcut specification in the web application (`apps/web`). Covers trigger rules, typing target guards, overlay exclusion, store reactivity, discoverability, and testable acceptance criteria `AC-001` through `AC-010`.
