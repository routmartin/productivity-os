# Tasks & Inbox UI Specification

**Status:** Draft

## 1. Problem

Productivity OS needs a dedicated workspace for capturing, organizing, and
managing tasks.

The Tasks workspace should support both deliberate task management and fast
capture through the Inbox while maintaining the calm, premium visual
language established by the Today workspace.

## 2. Goal

Create a desktop-first task workspace that allows users to:

- Quickly capture tasks.
- Browse tasks.
- Search and filter tasks.
- Distinguish Inbox tasks from organized tasks.
- Understand task status at a glance.
- Open task details without leaving the workspace.
- Perform common task actions quickly.
- Move naturally between Inbox and organized task views.

The UI should feel lightweight and fast rather than like a traditional
project-management table.

## 3. Design Direction

Follow the existing Productivity OS visual direction:

**Calm Command Center**

The screen should feel:

- Premium
- Focused
- Calm
- Fast
- Information-dense without being cluttered

Reuse the visual language from the Today screen.

Do not introduce a separate visual design system.

## 4. Layout

The Tasks workspace uses:

```
┌────────────┬───────────────────────────────────────────┐
    │            │                                           │
    │ Navigation │ Task Workspace                            │
    │            │                                           │
    │            │ Header                                    │
    │            │                                           │
    │            │ Filters / Search                          │
    │            │                                           │
    │            │ Task List                                 │
    │            │                                           │
    │            │                                           │
    └────────────┴───────────────────────────────────────────┘
```

When a task is selected:

```
┌────────────┬──────────────────────────────┬─────────────┐
    │ Navigation │ Task List                    │ Task Detail │
    └────────────┴──────────────────────────────┴─────────────┘
```

The detail panel is contextual and should not require a page navigation.

## 5. Navigation

The existing application sidebar remains unchanged.

Tasks should be visually highlighted when the user is in:

- `/tasks`
- `/inbox`

Inbox should remain a distinct navigation destination.

## 6. Tasks Header

The Tasks workspace header should contain:

- Page title.
- Short contextual description.
- Search.
- Primary "New Task" action.

Example:

```
Tasks
```

```
Everything you're working on.
```

```
[ Search tasks... ] [ + New Task ]
```

The exact copy may evolve during visual implementation.

## 7. Inbox

Inbox represents projectless captured tasks.

The Inbox should communicate:

> Things you've captured but haven't organized yet.

Example:

```
Inbox
    7 things waiting for your attention.
```

```
┌──────────────────────────────────────────────┐
    │ ○ Buy new monitor                         ⋯ │
    │   Captured today                             │
    ├──────────────────────────────────────────────┤
    │ ○ Review payment documentation            ⋯ │
    │   Captured yesterday                         │
    └──────────────────────────────────────────────┘
```

Inbox should prioritize quick capture and organization.

## 8. Task List

Tasks should be displayed primarily as lightweight rows.

Avoid large card layouts.

A task row may contain:

- Completion/status indicator.
- Task title.
- Project.
- Goal relationship where relevant.
- Status.
- Priority.
- Due information.
- Estimated duration.
- Overflow actions.

Example:

```
○ Finish authentication             IN PROGRESS
      Productivity OS                   Today · 1h 30m
```

Rows should have enough spacing to remain easy to scan.

## 9. Task Status

Status should be visually clear but restrained.

Supported lifecycle states from Task Management:

- INBOX
- PLANNED
- IN_PROGRESS
- COMPLETED
- CANCELLED

The frontend must not redefine lifecycle rules.

The backend remains the source of truth for valid transitions.

## 10. Filters

The workspace should provide lightweight filtering.

Initial filter concepts:

- All
- Inbox
- Planned
- In Progress
- Completed

Additional filters may include:

- Project
- Goal
- Priority
- Due date

Filters should not dominate the interface.

## 11. Search

Search should be visually accessible from the task workspace.

Search should support finding tasks by title.

The UI should provide:

- Search input.
- Clear action.
- Empty result state.
- Loading state where applicable.

Keyboard shortcuts may be added later.

## 12. Task Creation

The primary "New Task" action should make task capture extremely fast.

Preferred interaction:

```
+ New Task
```

opens a lightweight creation interface.

The creation interface should initially contain:

- Title.
- Optional description.
- Optional project.
- Optional goal.
- Optional priority.
- Optional due date.
- Optional duration.
- Destination: Inbox, Plan for today, or Start now (see 12.1).

The first visual milestone may use mock submission.

The interface should be designed so the real Task API can be connected later.

### 12.1 Creation destination (amended)

Creation always requests the backend create operation first; the resulting
task starts in Inbox. The destination choice then chains sanctioned
lifecycle transitions, using the same rules as Section 15.1:

- **Inbox** (default): no further transitions. Quick capture is unchanged.
- **Plan for today**: the UI chains `plan` (Inbox → Planned) after create.
- **Start now**: the UI chains `plan`, then `start`
  (Inbox → Planned → In Progress) after create.

The choice appears only when creating a task, never when editing. If a
chained transition fails, the task remains visible in its actual lifecycle
state and the error is surfaced — the task must never be silently lost.

The destination is a UI-only concern; no initial-status field is added to
the backend create contract.

## 13. Quick Capture

Inbox should support fast task capture.

A quick capture interaction may use:

```
What needs to be done?
```

```
[ Enter task... ]
```

```
[ Add ]
```

The interaction should minimize unnecessary fields.

The user should be able to capture a task first and organize it later.

## 14. Task Detail Panel

Selecting a task opens the contextual detail panel.

The panel may contain:

- Title.
- Description.
- Lifecycle status.
- Project.
- Goal.
- Priority.
- Due date.
- Estimated duration.
- Created time.
- Completion time where applicable.
- Focus action.
- Task actions.

Example:

```
Finish authentication
```

```
IN PROGRESS
```

```
Build JWT authentication and refresh-token
    handling.
```

```
Project
    Productivity OS
```

```
Priority
    High
```

```
Duration
    1h 30m
```

```
──────────────────────────
```

```
[ Start Focus ]
```

```
[ Complete ]
```

```
...
```

The panel should remain visually consistent with the Today contextual
panel.

## 15. Task Actions

Common actions should be accessible without navigating away.

Potential actions:

- Plan.
- Start.
- Complete.
- Cancel.
- Reopen.
- Delete.
- Restore.
- Move to project.
- Change priority.
- Edit task.

### 15.3 Cancel and Reopen (amended)

A task in any active state — Inbox, Planned, or In Progress — can be
cancelled from the UI. Cancelling is a deliberate action and must use a
confirmation step, but it must not require deleting the task: "stop working
on this" and "delete this" are distinct operations.

The backend `cancellation` endpoint is the only path to Cancelled; the UI
requests it and renders the result. A Cancelled task remains visible with
reduced emphasis (consistent with Completed treatment) and exposes a
**Reopen** action, which requests the backend `reopening` transition
(Cancelled → Planned).

Restore of deleted tasks stays out of scope for this milestone
(Section 17).

### 15.1 One-click Start (amended)

Starting work on a task must be a single, obvious action available wherever
the task appears: the task row/card action menu and the task detail panel.

A single **Start** action means "I am working on this now":

- On a Planned task, Start requests the backend `start` transition
  (Planned → In Progress).
- On an Inbox task, Start is still one click for the user. The UI requests
  the sanctioned backend transitions in sequence (`plan`, then `start`) as
  one user-initiated operation. The intermediate Planned state is never
  shown as a separate required step.
- The Start action must not be buried so that the primary path to working
  on a task requires opening a context menu twice.

The task detail panel's primary action follows the same rule:

- If the task is active but not In Progress (Inbox or Planned), pressing
  **Start focus session** first moves the task to In Progress using the
  chaining above, then proceeds to focus. It must not dead-end with only a
  message telling the user to start the task elsewhere.
- Only Completed or Cancelled tasks are ineligible, and the panel should
  communicate why.

### 15.2 Backend authority

The UI must not implement lifecycle transitions independently.

It should request the operation and respond to the backend result. Chained
operations use only existing backend transition endpoints; no client-side
state invention.

## 16. Completed Tasks

Completed tasks should remain visually distinguishable.

Use:

- Reduced visual emphasis.
- Completion indicator.
- Completed status.
- Optional completion timestamp.

Do not visually treat completed tasks as active work.

## 17. Deleted Tasks

Deleted tasks are soft-deleted according to Task Management.

Normal active task views should not display deleted tasks.

If a future deleted-task view is provided, deleted tasks may expose a Restore
action.

The first UI milestone does not need a dedicated deleted-task workspace.

## 18. Empty States

### Empty Tasks

```
No tasks yet.
```

```
Capture something you're thinking about.
```

```
[ + New Task ]
```

### Empty Inbox

```
Your inbox is clear.
```

```
Nothing waiting to be organized.
```

### No Search Results

```
No tasks found.
```

```
Try a different search.
```

Empty states should remain concise and actionable.

## 19. Loading States

Use localized loading states.

Examples:

- Task list skeleton.
- Search loading indicator.
- Task detail loading.
- Creation submission state.
- Action-level loading.

Avoid replacing the entire workspace with a full-screen spinner.

## 20. Error States

Errors should be:

- Clear.
- Concise.
- Recoverable where possible.

Examples:

- Unable to load tasks.
- Task could not be created.
- Task could not be updated.
- Task is no longer available.

Do not expose raw backend exceptions.

## 21. Responsive Behavior

Desktop is the primary experience.

At smaller desktop widths:

- Detail panel may collapse.
- Filters may condense.
- Sidebar may reduce.

The task list remains the primary workspace.

Full mobile optimization is not part of this milestone.

## 22. Visual Hierarchy

The hierarchy should be:

```
Page
      ↓
    Search + New Task
      ↓
    Filters
      ↓
    Task List
      ↓
    Task Metadata
```

Avoid giving every metadata field equal visual weight.

Task titles should remain the strongest element within each row.

## 23. Motion

Use subtle motion for:

- Opening detail panel.
- Closing detail panel.
- Task creation.
- Task completion.
- Filtering.
- Reordering where applicable.

Avoid decorative animation.

## 24. Mock Data

The first implementation uses realistic mock data.

Example:

- Finish authentication
- Build task dashboard
- Review API implementation
- Write documentation
- Fix login validation
- Review database schema
- Prepare sprint review

Use realistic projects and statuses.

Avoid lorem ipsum or generic placeholder content.

## 25. First Implementation Scope

Build:

- Tasks page.
- Inbox page.
- Search UI.
- Filter UI.
- New Task UI.
- Quick Capture UI.
- Task list.
- Task row.
- Task detail panel.
- Task action menu.
- Loading states.
- Empty states.
- Error states.
- Responsive desktop behavior.

Use mock data.

## 26. First Implementation Exclusions

Do not implement:

- Real Task API integration.
- Real authentication changes.
- Projects functionality.
- Goals functionality.
- Focus functionality.
- AI functionality.
- Backend changes.
- Full keyboard command system.
- Advanced task filtering.
- Mobile-specific optimization.

## 27. Reusable Components

Where appropriate, create reusable components such as:

- TaskRow
- TaskList
- TaskStatus
- TaskPriority
- TaskDetailPanel
- TaskActionMenu
- TaskSearch
- TaskFilters
- NewTaskDialog
- QuickCapture
- EmptyState
- LoadingState

Do not over-abstract simple UI elements.

## 28. Dependencies

- Frontend UI Specification
- Task Management Specification
- User Management Specification
- ADR-002 — Technology Stack
- ADR-005 — API Architecture
- ADR-006 — Time and Timezone

## 29. Open Questions

1. Should task creation use a modal, side panel, or inline composer?
2. Should Inbox and Tasks share the same list component?
3. Should filtering use URL query parameters?
4. Should task search eventually support keyboard shortcuts?
5. Should completed tasks appear in the default Tasks view?
6. Should the task detail panel remain open when navigating between tasks?
7. Should users be able to drag tasks between lifecycle/group sections?

These should be resolved through visual iteration rather than extensive
upfront architecture decisions.

## 30. Change History

- Initial Draft created for the Tasks and Inbox frontend experience.
- Amended per human request to simplify starting work: added Section 15.1
  "One-click Start" — a single Start action on Inbox/Planned tasks (UI chains
  the sanctioned plan → start transitions), and the detail panel's
  "Start focus session" starts the task instead of dead-ending with a message.
- Amended per human request to allow creating tasks directly into Planned or
  In Progress: added Section 12.1 "Creation destination" — New Task dialog
  gains an Inbox / Plan for today / Start now choice; UI chains sanctioned
  transitions after create; backend create contract unchanged.
- Amended to wire up Cancel and Reopen: added Section 15.3 — Cancel available
  on Inbox/Planned/In Progress tasks with confirmation (uses the backend
  cancellation endpoint), Cancelled tasks expose Reopen (backend reopening
  endpoint). Previously these endpoints had no UI path at all.
