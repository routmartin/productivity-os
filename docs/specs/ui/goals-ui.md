# Goals UI Specification

**Status:** Draft

## 1. Problem

Productivity OS needs a Goals workspace where users can understand what
they are trying to achieve and how their Projects contribute to those
outcomes.

Goals should sit above Projects in the product hierarchy:

```
Goal
      ↓
    Projects
      ↓
    Tasks
```

The Goals experience should feel more strategic and reflective than the
Tasks and Projects experiences.

## 2. Goal

Create a premium desktop-first Goals experience that allows users to:

- See active goals.
- Understand goal progress.
- See associated projects.
- Distinguish active, completed, and archived goals.
- Open a goal and inspect its projects and recent work.
- Create a new goal.
- Complete a goal directly or through achieved projects.
- Reopen a completed goal.
- Understand what will happen when a goal is completed or reopened.

The UI uses mock data for this milestone.

## 3. Important Domain Behavior

The UI must respect the current Goal Management behavior:

Goal lifecycle:

```
DRAFT → ACTIVE → COMPLETED → ARCHIVED
```

Completed goals can be reopened.

Goals may contain Projects.

A goal may be completed directly even if it has no Projects.

A goal may be completed when its Projects are achieved.

A Project is considered achieved when it is:

- Completed, or
- Cancelled.

When a Goal is completed, its Projects are archived.

When a completed Goal is reopened, the user is asked which archived Projects
should be reactivated.

The frontend must present these behaviors clearly but must not implement
business rules independently. The backend remains the source of truth.

## 4. Design Direction

Use the existing Productivity OS visual language:

**Calm Command Center**

Goals should feel:

- Strategic
- Calm
- Premium
- Motivating without being gamified
- Less operational than Tasks
- More purposeful than Projects

Reuse the visual system from:

- Today
- Tasks
- Inbox
- Projects

Do not introduce a new design system.

## 5. Layout

Desktop:

```
┌────────────┬─────────────────────────────────────────┐
    │            │                                         │
    │ Navigation │ Goals                                   │
    │            │                                         │
    │            │ Header + New Goal                       │
    │            │                                         │
    │            │ Filters                                 │
    │            │                                         │
    │            │ Goal surfaces                           │
    │            │                                         │
    └────────────┴─────────────────────────────────────────┘
```

When a goal is selected:

```
┌────────────┬─────────────────────────────┬─────────────┐
    │ Navigation │ Goal List                   │ Goal Detail │
    └────────────┴─────────────────────────────┴─────────────┘
```

The goal detail area is contextual and should reuse the existing contextual
panel system.

## 6. Goals Header

Display:

```
Goals
```

```
What you're working toward.
```

```
[ + New Goal ]
```

The exact copy may evolve during visual implementation.

## 7. Goal Filters

Provide:

- Active
- Completed
- Archived

Default view:

Active

The filter should remain visually subtle.

## 8. Goal Representation

Goals should be represented with a lighter, more strategic surface than
Projects.

Each goal should communicate:

- Goal title.
- Short description.
- Lifecycle state.
- Progress.
- Number of active projects.
- Number of completed projects.
- Recent activity.
- Optional target/deadline if supported by the existing domain data.

Example:

```
Become a better developer
```

```
Build stronger backend and system design skills.
```

```
ACTIVE
```

```
███████████████░░░░░
```

```
68%
```

```
3 active projects · 1 completed
```

The UI should not turn goals into metric-heavy analytics dashboards.

## 9. Goal Progress

Goal progress should be visually clear but intentionally simple.

For this UI milestone, progress uses coherent mock data.

When the real backend is connected, the backend/domain model is the source
of truth for progress.

Do not invent additional goal metrics such as:

- Velocity
- Score
- Streak
- Productivity rating
- Burn-down
- Points

unless future product specifications define them.

## 10. Goal → Project Relationship

The relationship between a Goal and its Projects should be one of the most
important visual elements.

Example:

```
Become a better developer
```

```
PROJECTS
```

```
● Productivity OS
      72%
```

```
● Mobile App
      54%
```

```
● Backend Architecture
      38%
```

Projects should be visually recognizable as children of the Goal.

A goal may also have no projects.

Example:

```
No projects yet.
```

```
You can work toward this goal directly.
```

## 11. Goal Detail

Selecting a goal opens a contextual detail panel.

The panel may contain:

- Goal title.
- Description.
- Lifecycle state.
- Progress.
- Projects.
- Project completion summary.
- Recent activity.
- Goal actions.

Example:

```
Become a better developer
```

```
ACTIVE
```

```
Build stronger backend and system
    design skills.
```

```
Progress
    ███████████████░░░░░ 68%
```

```
PROJECTS
```

```
Productivity OS             72%
    Mobile App                  54%
```

```
RECENT PROGRESS
```

```
Completed API authentication
    Started task planning UI
```

```
[ Complete Goal ]
```

## 12. Draft Goal

Draft goals should be visually distinguishable from active goals without
looking like errors.

Example:

```
DRAFT
```

```
Learn system design deeply
```

```
Not active yet.
```

The user should be able to activate a Draft goal through the appropriate
future product flow.

The exact activation interaction is outside the scope of this UI milestone
unless already implemented elsewhere.

## 13. Completed Goal

Completed goals should feel visually quieter than active goals.

Example:

```
✓ Become a better developer
```

```
COMPLETED
```

```
Completed Aug 2026
```

The completed state should communicate accomplishment without excessive
gamification.

Completed goals remain accessible.

## 14. Archived Goal

Archived goals should be visually subdued.

They are historical rather than active work.

Archived goals should not dominate the default Active view.

## 15. Complete Goal

The UI should provide a clear completion action for an active goal.

Completion may happen:

- Directly, including when the goal has no projects.
- When all relevant projects have reached an achieved state.

The UI must not independently decide whether the goal can be completed.

Send the completion operation to the backend when API integration is added.

If completion causes Projects to become archived, the UI should reflect that
result from the backend.

## 16. Reopen Goal

Completed goals can be reopened.

The reopen experience must communicate that previously archived Projects may
need to be reactivated.

Example:

```
Reopen this goal?
```

```
These projects were archived when the goal was completed.
```

```
☑ Productivity OS
    ☑ Mobile App
    ☐ Old Portfolio
```

```
[ Reopen Goal ]
```

The user chooses which Projects to reactivate.

The frontend must not guess which projects should be reactivated.

## 17. Projectless Goal

A goal with no Projects remains valid.

The UI should communicate that the goal can still be completed directly.

Example:

```
No projects attached.
```

```
You can still work toward and complete this goal directly.
```

## 18. New Goal

Create a lightweight goal creation interface.

Initial fields:

- Title.
- Description.
- Optional target/deadline if supported by the domain.
- Initial state.

For the UI milestone, creation may use mock state.

Avoid forcing the user to create a Project immediately.

## 19. Goal Actions

Potential actions:

- Activate.
- Complete.
- Reopen.
- Archive where applicable.
- Edit.
- Add Project.

Actions should be shown based on the visual state.

The backend remains responsible for validating lifecycle transitions.

## 20. Empty States

### No Goals

```
No goals yet.
```

```
Decide what you want to achieve.
```

```
[ + New Goal ]
```

### No Active Goals

```
You're clear.
```

```
There are no active goals right now.
```

### Goal With No Projects

```
No projects connected yet.
```

```
You can still work toward this goal directly.
```

## 21. Loading States

Use localized loading states:

- Goal list skeleton.
- Goal detail skeleton.
- Project list loading.

Avoid a full-page spinner.

## 22. Error States

Use concise user-facing messages:

- Unable to load goals.
- Goal could not be created.
- Goal could not be completed.
- Goal could not be reopened.

Do not expose raw backend exceptions.

## 23. Responsive Behavior

Desktop-first.

At smaller desktop widths:

- Goal surfaces reduce columns.
- Contextual detail panel may collapse.
- Sidebar may reduce.

The goals list remains the primary workspace.

Full mobile optimization is not required for this milestone.

## 24. Motion

Use subtle motion for:

- Opening goal detail.
- Completing a goal.
- Reopening a goal.
- Filter transitions.
- Project selection.

Avoid gamified celebration animations.

## 25. Mock Data

Use realistic examples.

### Become a better developer

Description:
Build stronger backend, architecture, and system design skills.

Status:
ACTIVE

Progress:
68%

Projects:

- Productivity OS — 72%
- Mobile App — 54%
- Backend Architecture — 38%

### Build a sustainable side business

Description:
Build and validate a profitable software product.

Status:
ACTIVE

Progress:
42%

Projects:

- Productivity OS — 60%
- Customer Research — 35%

### Improve personal health

Description:
Build consistent habits and improve overall health.

Status:
ACTIVE

Progress:
54%

Projects:

- Fitness Routine — 70%
- Better Sleep — 38%

### Launch personal portfolio

Status:
COMPLETED

Progress:
100%

### Old Personal Goals

Status:
ARCHIVED

Include enough mock data to demonstrate Active, Completed, Archived, Draft,
and projectless states.

## 26. First Implementation Scope

Build:

- Goals route.
- Goal header.
- Active/Completed/Archived filters.
- Goal surfaces.
- Progress indicators.
- Goal → Project relationship.
- Goal detail panel.
- Goal project list.
- New Goal interface.
- Completion interaction preview.
- Reopen interaction preview with project selection.
- Loading states.
- Empty states.
- Error states.
- Responsive desktop behavior.

Use mock data only.

## 27. Exclusions

Do not implement:

- Real Goal API integration.
- Backend changes.
- Real Project API integration.
- Real Task API integration.
- AI functionality.
- Focus functionality.
- Goal analytics.
- Gamification.
- Streaks.
- Scores.
- Complex progress calculations.
- Automatic goal completion logic.

Do not create a project-management dashboard inside the Goal screen.

## 28. Reusable Components

Reuse existing components where possible.

Potential components:

- GoalCard
- GoalProgress
- GoalFilters
- GoalDetailPanel
- GoalProjectList
- NewGoalDialog
- ReopenGoalDialog
- GoalStatus
- EmptyState
- LoadingState

Reuse ProjectCard/TaskRow where appropriate rather than creating duplicate
visual components.

## 29. Architecture

Follow the existing feature-oriented frontend structure:

```
features/
      goals/
        components/
        pages/
        data/
        types/
```

Reuse shared components and the existing contextual panel system.

Do not introduce another UI framework.

Do not introduce unnecessary state-management infrastructure.

## 30. Dependencies

- frontend-ui.md
- projects-ui.md
- tasks-and-inbox-ui.md
- Goal Management Specification
- Project Management Specification
- Task Management Specification
- ADR-002
- ADR-005
- ADR-006

## 31. UI Milestone Constraint

This is a UI milestone.

**Mock data only.**

Do not connect backend APIs.

Do not modify backend code.

## 32. Change History

- Initial Draft created for the Goals frontend experience.
