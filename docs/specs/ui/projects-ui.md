# Projects UI Specification

**Status:** Draft

## 1. Problem

Productivity OS needs a Projects workspace where users can understand their
ongoing bodies of work and how individual tasks contribute to them.

Projects should provide more context than the Tasks workspace without
becoming a traditional project-management dashboard.

## 2. Goal

Create a premium desktop-first Projects experience that allows users to:

- See active projects at a glance.
- Understand project progress.
- See the relationship between Projects and Goals.
- See task counts and completion progress.
- Open a project and inspect its tasks.
- Create a new project.
- Understand which projects are active versus archived.

The experience should remain calm and lightweight.

### 3. Design Direction**\*\*\*\***

Use the existing Productivity OS visual language:

**Calm Command Center**

Reuse the visual system from:

- Today
- Tasks
- Inbox

Do not introduce a new visual language.

Projects should feel like an organizational layer above Tasks.

Conceptually:

```
Goal
      ↓
    Project
      ↓
    Tasks
```

## 4. Layout

Desktop layout:

```
┌────────────┬─────────────────────────────────────────┐
    │            │                                         │
    │ Navigation │ Projects                                │
    │            │                                         │
    │            │ Header + New Project                    │
    │            │                                         │
    │            │ Filters                                 │
    │            │                                         │
    │            │ Project List / Grid                     │
    │            │                                         │
    └────────────┴─────────────────────────────────────────┘
```

When a project is selected:

```
┌────────────┬─────────────────────────────┬─────────────┐
    │ Navigation │ Projects / Tasks            │ Project     │
    │            │                             │ Detail      │
    └────────────┴─────────────────────────────┴─────────────┘
```

## 5. Projects Header

Display:

```
Projects
```

```
Everything you're building.
```

```
[ + New Project ]
```

The exact copy may evolve during implementation.

## 6. Project Filters

Provide lightweight filters:

- Active
- Completed
- Archived

The default view is Active.

Filters should remain visually subtle.

## 7. Project Representation

Projects should be represented using polished project surfaces.

Each project should communicate:

- Project name.
- Short description.
- Goal relationship.
- Progress.
- Task count.
- Completed task count.
- Remaining task count.
- Optional project color/accent.
- Recent activity.

Example:

```
Productivity OS
```

```
Build your personal productivity system.
```

```
Goal
    Become a better developer
```

```
███████████████░░░░░
```

```
72%
```

```
12 tasks · 8 completed · 4 remaining
```

The project surface should have enough visual hierarchy without becoming a
large dashboard card.

## 8. Project Progress

Progress should be visually obvious.

Use a restrained progress indicator.

Progress is derived from task completion in the future product.

For this UI milestone, progress uses mock data.

Do not invent additional progress concepts such as velocity, burn-down,
sprints, or story points.

## 9. Project Colors

Projects may have a small identifying accent.

Use restrained colors.

Example:

- Productivity OS → purple
- Mobile App → blue
- Website Redesign → green
- Personal → orange

Color should help recognition rather than dominate the interface.

## 10. Goal Relationship

When a project belongs to a Goal, show that relationship clearly but
subtly.

Example:

```
Goal
    Become a better developer
```

The UI should reinforce:

```
Goal → Project → Task
```

Projects without a Goal should remain valid.

Do not imply that every Project requires a Goal.

## 11. Project Detail

Selecting a project opens its detail experience.

The detail area should contain:

- Project name.
- Description.
- Goal.
- Progress.
- Task summary.
- Active tasks.
- Recently completed tasks.
- Project actions.

Example:

```
Productivity OS
```

```
Build your personal productivity system.
```

```
Goal
    Become a better developer
```

```
Progress
    ███████████████░░░░░ 72%
```

```
12 tasks
    8 completed
    4 remaining
```

```
ACTIVE TASKS
```

```
○ Build task dashboard
    ○ Review API implementation
    ○ Write documentation
```

The first implementation may use mock data.

## 12. Project Tasks

Project detail should expose a lightweight task list.

Reuse the existing TaskRow visual component from Tasks/Inbox where possible.

Do not create a second task-row design.

Clicking a task may open the existing task detail panel.

## 13. Project Creation

The New Project action opens a lightweight creation interface.

Initial fields:

- Project name.
- Description.
- Goal.
- Accent color.

The UI should not require unnecessary configuration.

For this milestone, submission uses mock behavior.

## 14. Archived Projects

Archived projects should be visually separated from active work.

Archived projects should not dominate the default Active view.

The interface may provide:

```
Active    Completed    Archived
```

Archived projects can be restored in the future.

The exact restoration behavior is outside this UI milestone.

## 15. Completed Projects

Completed projects should be visually quieter than active projects.

They remain accessible for history.

Do not visually treat completed projects as active work.

## 16. Empty States

### No Projects

```
No projects yet.
```

```
Group related tasks into a project when you're
    ready to work toward something bigger.
```

```
[ + New Project ]
```

### No Active Projects

```
You're clear.
```

```
There are no active projects right now.
```

### No Projects for Goal

```
No projects connected to this goal yet.
```

```
[ Create Project ]
```

## 17. Loading States

Use localized loading states.

Examples:

- Project list skeleton.
- Project detail skeleton.
- Project task loading.

Avoid full-screen loading indicators.

## 18. Error States

Use concise, user-friendly errors.

Examples:

- Unable to load projects.
- Project could not be created.
- Project is no longer available.

Do not expose raw backend exceptions.

## 19. Responsive Behavior

Desktop-first.

At smaller desktop widths:

- Project surfaces may switch from multiple columns to one column.
- Detail panel may collapse.
- Sidebar may reduce.

The project list remains the primary workspace.

Full mobile optimization is not required.

## 20. Motion

Use subtle motion for:

- Opening project detail.
- Closing project detail.
- Creating a project.
- Changing filters.
- Progress updates.

Avoid decorative animation.

## 21. Mock Data

Use realistic mock projects:

### Productivity OS

Description:
Build your personal productivity system.

Goal:
Become a better developer.

Progress:
72%

Tasks:
12 total
8 completed
4 remaining

### Mobile App

Description:
Improve the mobile application experience.

Goal:
Become a better developer.

Progress:
54%\*\*\*\*

Tasks:
18 total
10 completed
8 remaining

### Website Redesign

Description:
Refresh the company website experience.

Progress:
38%

Tasks:
10 total
4 completed
6 remaining

### Personal

Description:
Personal projects and life tasks.

No Goal.

Progress:
25%

Tasks:
8 total
2 completed
6 remaining

## 22. First Implementation Scope

Build:

- Projects route.
- Project header.
- Active/Completed/Archived filters.
- Project surfaces.
- Progress indicators.
- Goal relationship.
- Project detail panel.
- Project task list.
- New Project interface.
- Loading states.
- Empty states.
- Error states.
- Responsive desktop behavior.

Use mock data only.

## 23. Exclusions

Do not implement:

- Real Project API integration.
- Backend changes.
- Real Goal integration.
- Real Task API integration.
- Project archival persistence.
- Project restoration persistence.
- AI functionality.
- Focus functionality.
- Project analytics.
- Gantt charts.
- Kanban boards.
- Sprints.
- Story points.
- Burndown charts.

Do not turn Projects into a traditional project-management system.

## 24. Reusable Components

Reuse existing components where appropriate.

Potential components:

- ProjectCard
- ProjectProgress
- ProjectFilters
- ProjectDetailPanel
- ProjectTaskList
- NewProjectDialog
- ProjectStatus
- EmptyState
- LoadingState

Avoid unnecessary abstraction.

## 25. Architecture

Follow the existing frontend feature-oriented architecture.

Prefer:

```
features/
      projects/
        components/
        pages/
        data/
        types/
```

Reuse shared components from the existing frontend.

Do not introduce another UI framework.

## 26. Dependencies

- frontend-ui.md
- tasks-and-inbox-ui.md
- Task Management Specification
- Goal Management Specification
- Project Management Specification
- ADR-002
- ADR-005
- ADR-006

## 27. First Milestone Constraint

This is a UI milestone.

**Mock data only.**

Do not connect backend APIs.

Do not modify backend code.

## 28. Change History

- Initial Draft created for the Projects frontend experience.

# Frontend UI Milestone — Goals

Build the next Productivity OS frontend UI milestone:

GOALS

This is a UI-only milestone.

DO NOT connect APIs.

DO NOT modify the backend.

Use realistic mock data.

## Read first

Read:

- AGENTS.md
- docs/specs/ui/frontend-ui.md
- docs/specs/ui/tasks-and-inbox-ui.md
- docs/specs/ui/projects-ui.md
- docs/specs/ui/goals-ui.md
- docs/specs/goals/goal-management.md
- docs/specs/projects/project-management.md
- docs/specs/tasks/task-management.md
- docs/architecture/system.md
- docs/decisions/ADR-002-technology-stack.md

Inspect the existing Today, Tasks, Inbox, and Projects implementations.

## Visual baseline

Today, Tasks, Inbox, and Projects are the visual source of truth.

Do NOT redesign them.

Goals must look like the same Productivity OS.

Preserve:

- Dark theme
- Typography
- Sidebar
- Navigation
- Colors
- Blue/purple accent language
- Borders
- Spacing
- Buttons
- Contextual panels
- Empty/loading/error states

Goals should feel more strategic and reflective than Tasks.

Do not make Goals another task-management dashboard.

## Objective

Build:

/goals

The conceptual hierarchy is:

Goal
↓
Project
↓
Task

The Goal screen should communicate direction and outcomes.

## Goal list

Header:

Goals

What you're working toward.

Primary action:

- New Goal

Filters:

- Active
- Completed
- Archived

Default:

Active

## Goal surfaces

Create polished but relatively lightweight goal surfaces.

Each should show:

- Goal title
- Description
- Status
- Progress
- Project count
- Recent activity where useful

Avoid excessive metrics.

Mock goals:

1. Become a better developer

   - ACTIVE
   - 68%
   - Productivity OS
   - Mobile App
   - Backend Architecture

2. Build a sustainable side business

   - ACTIVE
   - 42%
   - Productivity OS
   - Customer Research

3. Improve personal health

   - ACTIVE
   - 54%
   - Fitness Routine
   - Better Sleep

4. Launch personal portfolio

   - COMPLETED
   - 100%

5. Old Personal Goals

   - ARCHIVED

Also include:

- one DRAFT goal
- one ACTIVE goal without Projects

This allows us to visually test all important states.

## Goal → Project relationship

Make the relationship obvious:

Goal
↓
Projects
↓
Tasks

A goal without projects must also look completely valid.

Example:

"No projects connected yet.
You can still work toward this goal directly."

## Goal detail panel

Clicking a goal opens the contextual right panel.

Show:

- Goal name
- Description
- Status
- Progress
- Projects
- Project progress
- Recent activity
- Available actions

Reuse existing ProjectCard or a lighter project-row representation where
appropriate.

Do not create a new visual system.

## Complete Goal interaction

Build a mock completion interaction.

It should make clear that:

- A goal can be completed directly.
- A goal can be completed when its projects are achieved.

Do NOT implement the lifecycle logic in the frontend.

This is only a UI preview.

## Reopen Goal interaction

Build a mock reopen interaction.

When reopening a completed goal, show the projects that were archived with it.

Allow the user to select which projects to reactivate.

Example:

Reopen this goal?

These projects were archived when the goal was completed.

☑ Productivity OS
☑ Mobile App
☐ Old Portfolio

[ Reopen Goal ]

This interaction is especially important.

Do not automatically select every project without showing the user the
choice.

## Projectless goal

Include one projectless active goal in mock data.

The UI should clearly communicate:

"No projects connected yet.
You can still work toward this goal directly."

## New Goal

Build a polished mock creation dialog.

Fields:

- Title
- Description
- Optional target/deadline if supported by the existing UI model

Keep it lightweight.

Mock creation should update local state.

## Filters

Make Active, Completed, and Archived filters work against mock data.

Do not connect APIs.

## States

Implement:

- Loading
- Empty
- No active goals
- No projects
- No filtered results
- Error

Use the same visual state patterns as existing screens.

## Responsive behavior

Desktop-first.

At smaller desktop widths:

- Reduce goal columns.
- Collapse contextual panel when necessary.
- Preserve usable goal list.

Do not spend significant time on mobile.

## Code organization

Use the existing feature-oriented architecture.

Prefer:

features/goals/

Reuse:

- existing UI components
- existing contextual panel
- existing ProjectCard
- existing TaskRow where appropriate
- existing Dialog
- existing filters

Do not duplicate existing components.

Do not introduce Pinia or another state-management framework unless the
current application already requires it.

## Important constraints

DO NOT:

- Connect APIs.
- Modify Spring Boot.
- Modify backend specs.
- Modify ADRs.
- Implement Projects.
- Implement Tasks.
- Implement Focus.
- Implement AI.
- Redesign Today.
- Redesign Tasks.
- Redesign Inbox.
- Redesign Projects.
- Add gamification.
- Add goal analytics.

The goal is to finish the visual Goal experience.

## Quality bar

Run the frontend and verify:

1. /goals loads.
2. Active filter works.
3. Completed filter works.
4. Archived filter works.
5. Draft goal appears correctly.
6. Projectless goal appears correctly.
7. Goal detail opens/closes.
8. Projects are visible inside goal detail.
9. Complete Goal UI works as a mock interaction.
10. Reopen Goal UI works with project selection.
11. New Goal mock creation works.
12. Loading/empty/error states work.
13. The screen visually matches Today, Tasks, Inbox, and Projects.

## Final report

Report:

1. Files changed.
2. Components created/reused.
3. Route added.
4. Mock data.
5. Interactions implemented.
6. Verification results.
7. Visual decisions.
8. Recommended next UI screen.

Do not connect APIs.
Do not modify backend.
