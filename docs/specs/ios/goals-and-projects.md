# Goals & Projects — iOS View-Only

## Status

Approved for implementation.

## Purpose

Add a read-only Goals & Projects experience to the Productivity OS iOS app.

The purpose is to let users understand:

- What they are trying to achieve
- Which projects support each goal
- How those projects are progressing

The iOS app must NOT become another place to manage goals or projects.

Goals and projects continue to be managed through the existing Productivity OS system.

The iOS experience is primarily for **context and awareness**.

---

# 1. Scope

### Included

- View all goals
- View goal progress
- View projects belonging to a goal
- View project progress
- View basic project metadata
- Navigate from Goals → Goal Details → Project Details
- Loading state
- Empty state
- Error state
- Pull-to-refresh
- Read-only presentation

### Not Included

- Create goal
- Edit goal
- Delete goal
- Create project
- Edit project
- Delete project
- Reorder goals
- Reorder projects
- Advanced filtering
- Goal/project management

---

# 2. Navigation

Add a new `Goals` destination to the iOS application.

Recommended navigation:

Today → Goals → Goal Details → Project Details

The Goals destination should feel like a natural part of the existing Productivity OS navigation.

Use the existing navigation architecture.

Do not introduce a separate navigation system.

---

# 3. Goals Screen

## Header

Title:

`Goals`

Optional supporting text:

`Keep your work connected to what matters.`

Include a refresh action if consistent with the existing navigation style.

---

## Overview Card

Display a compact progress overview.

Example:

    ┌──────────────────────────────┐
    │ Overall Progress             │
    │                              │
    │       ◯ 64%                  │
    │                              │
    │  Completed    24             │
    │  In Progress  18             │
    │  Not Started   6             │
    └──────────────────────────────┘

The overview is informational only.

---

# 4. Goal List

Each goal should be presented as a polished card.

Example:

    ┌──────────────────────────────┐
    │ 🎯  Build the best version   │
    │     of Productivity OS      ›│
    │                              │
    │     ━━━━━━━━━━━━━━━  76%    │
    │                              │
    │     3 Projects · Due Dec 31  │
    └──────────────────────────────┘

Display:

- Goal icon
- Goal title
- Progress
- Number of projects
- Target date when available
- Navigation indicator

Cards should be visually consistent with the existing Productivity OS design system.

---

# 5. Goal Details

Selecting a goal opens a detail screen.

Display:

- Goal title
- Goal icon
- Description
- Overall progress
- Target date
- Number of projects
- Projects belonging to this goal

Example:

    Goal Details

    🎯
    Build the best version
    of Productivity OS

    75% complete

    ━━━━━━━━━━━━━━━━━━━━━

    About this goal
    Create a world-class productivity
    system that helps people focus...

    Target       Projects
    Dec 31       3

    PROJECTS

    ┌──────────────────────────────┐
    │  iOS App                 ›   │
    │  ━━━━━━━━━━━━━━━       80%  │
    │  12 tasks · In Progress     │
    └──────────────────────────────┘

---

# 6. Project Details

Selecting a project opens a read-only project detail view.

Display:

- Project title
- Description
- Progress
- Status
- Task count
- Target date
- Parent goal

No editing controls.

The user should understand how the project contributes to the selected goal.

---

# 7. Data

Use the existing Productivity OS API.

Do not create duplicate backend models or mock production APIs.

Use existing API contracts wherever available.

Expected goal information:

- id
- title
- description
- progress
- target date
- created date

Expected project information:

- id
- title
- description
- progress
- status
- task count
- target date
- goal id

If the existing API uses different field names or structures, follow the actual API contract rather than inventing a new one.

---

# 8. States

The Goals experience must support:

### Loading

Use the existing loading/skeleton pattern.

### Normal

Show goals and their progress.

### Empty

Example:

    🎯

    No goals yet

    Your goals will appear here once
    they are created.

Do not show create buttons because this feature is read-only.

### Error

Provide a clear error message and Retry action.

### Refreshing

Support pull-to-refresh where appropriate.

---

# 9. Visual Design

Follow:

`design/references/goals-projects-reference.png`

The provided visual defines the visual direction.

Do not copy exact dimensions.

Use the existing:

- AppColors
- AppTypography
- AppSpacing
- AppMotion
- AppCard
- AppButton
- existing navigation components

The experience should feel like it belongs to the same application as Today and Focus.

---

# 10. Design Principles

The Goals experience should answer:

> "What am I working toward?"

The hierarchy is:

    Goal
      ↓
    Project
      ↓
    Progress

Avoid turning the screen into a dense project-management dashboard.

The experience should remain calm, readable, and glanceable.

---

# 11. Animation

Use the existing AppMotion system.

Recommended:

- Goals screen entrance: standard
- Goal card appearance: subtle
- Navigation: native SwiftUI transition
- Progress presentation: subtle
- Pull-to-refresh: system behavior

Do not add decorative animation that does not communicate state.

Respect Reduce Motion.

---

# 12. Accessibility

Support:

- VoiceOver
- Dynamic Type
- sufficient contrast
- meaningful accessibility labels
- clear navigation labels

Progress should be understandable through VoiceOver.

Example:

`Build the best version of Productivity OS, 75 percent complete, 3 projects.`

Decorative icons must not become unnecessary accessibility elements.

---

# 13. Architecture

Follow the existing SwiftUI architecture.

Recommended structure:

    Features/
      Goals/
        GoalsView.swift
        GoalsViewModel.swift
        GoalDetailsView.swift
        ProjectDetailsView.swift

Use existing:

- APIClient
- Endpoint
- Authentication
- DesignSystem
- shared models where appropriate

Do not duplicate networking infrastructure.

Keep ViewModels responsible for feature state and API orchestration.

Keep Views focused on presentation.

---

# 14. Testing

Add tests for:

- Goals loading
- Successful goals response
- Empty state
- Error state
- Retry
- Goal selection/navigation
- Project selection/navigation
- Progress presentation
- Read-only behavior

Ensure existing Focus and Today tests continue passing.

---

# 15. Out of Scope

Do not implement:

- goal creation
- goal editing
- goal deletion
- project creation
- project editing
- project deletion
- task editing
- project reordering
- advanced analytics

This feature is strictly **view-only**.

---

# 16. Success Criteria

The feature is complete when:

- User can open Goals from the iOS app.
- User can see all available goals.
- User can understand goal progress.
- User can open a goal.
- User can see projects belonging to that goal.
- User can open a project.
- User can understand project progress and status.
- Data comes from the real API.
- Loading/empty/error states work.
- The UI matches the approved visual direction.
- No goal/project mutation is possible.
- Accessibility works.
- Tests pass.
- iOS build succeeds.
