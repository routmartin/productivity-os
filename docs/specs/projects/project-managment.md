# Project Management

## Status

Draft

## Purpose

Define the behavior and lifecycle of Projects in the Productivity OS.

A Project represents a body of work intended to produce a meaningful outcome.

---

## Problem

Users need a way to organize related Tasks into a meaningful body of work,
track its lifecycle, and understand whether the work is still active.

---

## Goal

Provide a predictable Project lifecycle that supports:

- preparing future work
- actively executing work
- completing meaningful outcomes
- preserving completed work as historical records

---

## User Story

As a user,

I want to organize related Tasks into Projects,

so that I can manage larger bodies of work toward meaningful outcomes.

---

# Ownership

Every Project belongs to exactly one User.

A user cannot access or modify another user's Projects.

---

# Goal Relationship

A Project may optionally belong to one Goal.

A Project can exist without a Goal.

### Rules

1. A Project belongs to exactly one User.
2. A Project belongs to zero or one Goal.
3. A Goal may contain multiple Projects.
4. A Project cannot belong to multiple Goals.
5. A Project and its Goal must belong to the same User.

---

# Project Lifecycle

A Project follows this lifecycle:

```text
Draft
  ↓
Active
  ↓
Completed
  ↓
Archived
```

### Lifecycle rules

- Draft → Active is allowed.
- Active → Completed is allowed only when all Project Tasks are completed or otherwise resolved.
- Completed → Archived is allowed.
- Completed is final.
- A Completed Project cannot return to Active.
- An Archived Project cannot be reactivated.

---

# Draft

A Draft Project represents work that has been defined but has not yet started.

A Draft Project may contain Tasks.

This allows the user to prepare project work before activation.

Draft Projects are not considered active work.

---

# Active

An Active Project represents work that the user is currently pursuing.

Tasks within an Active Project may be planned and executed.

---

# Completed

A Completed Project represents a finished outcome.

A Project cannot become Completed while it contains unresolved incomplete Tasks.

Once Completed:

- the Project remains available as historical data
- its completion timestamp is recorded
- the Project cannot be reopened

---

# Archived

An Archived Project represents a completed Project that has been moved out
of active visibility.

Archiving does not delete the Project or its historical data.

An Archived Project cannot be reactivated.

### Archived Project Tasks

Existing Tasks remain available as historical records.

Incomplete Tasks belonging to an Archived Project:

- cannot be newly selected for Daily Top 3
- cannot be newly planned
- remain available for historical reporting

The exact task behavior should remain consistent with the Task specification.

---

# Project Tasks

A Project may contain zero or more Tasks.

A Task belongs to at most one Project.

A Project may contain Tasks in any lifecycle state permitted by the Task specification.

### Draft Projects

Draft Projects may contain Tasks.

### Active Projects

Active Projects may contain and execute Tasks.

### Completed Projects

A Project cannot become Completed while unresolved incomplete Tasks remain.

### Archived Projects

Tasks remain historically associated with the Project.

---

# Project Completion

When a Project is completed:

- its completion timestamp is recorded
- its lifecycle state becomes Completed
- it cannot be reopened

A Project cannot be completed if unresolved incomplete Tasks remain.

The system must provide clear feedback explaining why completion is prevented.

---

# Project Archiving

Only a Completed Project can be archived.

Archiving:

- removes the Project from active project views
- preserves the Project
- preserves its Tasks
- preserves historical records
- prevents reactivation

---

# Project Deadline

A Project may optionally have a deadline.

The deadline represents the date by which the Project is intended to be completed.

The exact behavior for overdue Projects will be defined by the Planning
specification.

---

# Standalone Projects

A Project does not require a Goal.

Example:

```text
Standalone Project
└── Home maintenance
    ├── Fix leaking tap
    └── Replace light
```

A Project may later be associated with a Goal if the product allows that
relationship.

---

# Project Progress

Project progress should primarily be derived from its Tasks and meaningful
execution data.

The Project should not require manually entered percentage progress.

Exact progress calculation rules will be defined by the Progress specification.

---

# Relationship With Tasks

```text
Project
 └── Tasks
```

A Task may exist without a Project and is then considered an Inbox Task.

Assigning an Inbox Task to a Project does not change its lifecycle state unless
the Task specification explicitly requires it.

---

# Relationship With Goals

```text
Goal
 └── Projects
```

A Project may exist independently of a Goal.

A Goal may contain multiple Projects.

---

# Relationship With Daily Planning

Projects provide organizational context for Tasks.

Daily Planning operates primarily on Tasks rather than Projects.

A Project deadline may influence future planning, but exact prioritization
behavior belongs to the Planning specification.

---

# Edge Cases

## Project with no Tasks

A Draft or Active Project may contain zero Tasks.

A Project with no Tasks cannot be considered Completed unless the product
explicitly treats it as resolved.

## Project with incomplete Tasks

An Active Project with incomplete Tasks cannot be completed.

## Project with cancelled Tasks

Cancelled Tasks are not considered incomplete work for Project completion,
unless future requirements define otherwise.

## Archived Project with incomplete Tasks

The Project remains archived and its incomplete Tasks remain historical data,
but they cannot be newly planned or selected as Top 3.

## Standalone Project

A Project without a Goal is valid.

## Completed Project

A Completed Project cannot be reopened.

## Archived Project

An Archived Project cannot be reactivated.

---

# Acceptance Criteria

### AC-001 — Project Creation

Given an authenticated user,

when the user creates a valid Project,

then the Project is created in `Draft`.

### AC-002 — Project Ownership

Given a Project belongs to User A,

when User B attempts to access or modify it,

then the operation is rejected.

### AC-003 — Draft to Active

Given a Project is in `Draft`,

when the user activates it,

then the Project becomes `Active`.

### AC-004 — Draft Can Contain Tasks

Given a Project is in `Draft`,

when the user assigns Tasks to it,

then the Tasks become associated with the Project.

### AC-005 — Active Project

Given a Project is `Active`,

when the user views it,

then its associated Tasks are available according to their own lifecycle.

### AC-006 — Prevent Completion With Incomplete Tasks

Given an Active Project contains unresolved incomplete Tasks,

when the user attempts to complete the Project,

then completion is rejected and the user receives clear feedback.

### AC-007 — Complete Project

Given an Active Project has no unresolved incomplete Tasks,

when the user completes the Project,

then it becomes `Completed` and its completion timestamp is recorded.

### AC-008 — Completed Is Final

Given a Project is `Completed`,

when the user attempts to reactivate or otherwise reopen it,

then the transition is rejected.

### AC-009 — Complete to Archived

Given a Project is `Completed`,

when the user archives it,

then the Project becomes `Archived`.

### AC-010 — Archived Cannot Reactivate

Given a Project is `Archived`,

when the user attempts to reactivate it,

then the transition is rejected.

### AC-011 — Archived Data Preservation

Given a Project is Archived,

when the user views historical data,

then the Project and its associated historical Tasks remain available.

### AC-012 — Archived Project Planning Protection

Given a Project is Archived,

when the user attempts to newly plan one of its incomplete Tasks,

then the operation is rejected.

### AC-013 — Archived Project Top 3 Protection

Given a Project is Archived,

when the user attempts to newly select one of its incomplete Tasks as Top 3,

then the operation is rejected.

### AC-014 — Standalone Project

Given a user creates a Project without a Goal,

when the Project is saved,

then the Project remains valid without a Goal.

### AC-015 — Project Deadline

Given a Project has a deadline,

when the user views the Project,

then the deadline is available as part of the Project information.

### AC-016 — Project With No Tasks

Given a Project has no Tasks,

when the user views the Project,

then the Project remains valid.

### AC-017 — Cancelled Tasks

Given a Project contains only Completed or Cancelled Tasks,

when the user completes the Project,

then the Project may become `Completed`.

### AC-018 — Completion Timestamp

Given a Project transitions to Completed,

when the transition succeeds,

then the system records the completion timestamp.

---

# Constraints

1. Every Project belongs to exactly one User.
2. A Project belongs to zero or one Goal.
3. A Goal may contain multiple Projects.
4. A Project cannot belong to multiple Goals.
5. A Project cannot be Completed while unresolved incomplete Tasks remain.
6. Completed Projects cannot be reopened.
7. Archived Projects cannot be reactivated.
8. Archiving does not delete Project or Task history.
9. AI must not silently change Project lifecycle state.

---

# Out of Scope

- Project collaboration
- Project sharing
- Multiple owners
- Project templates
- Project recurrence
- Project dependencies
- Project automation
- AI-generated Projects
- AI-generated project plans
- Detailed progress calculations
- Calendar integration
- Notifications
- Project deletion
- Team permissions

---

# Dependencies

- User Management
- Goal Management
- Task Management
- Daily Planning
- Daily Top 3
- Progress

---

# Open Questions

1. Can a Project move directly from Draft to Completed if it has no Tasks?
2. Can an Active Project return to Draft?
3. Can a Project's Goal be changed after work has started?
4. What exactly counts as an "unresolved" Task?
5. What happens to an incomplete Task when its Project is archived?
6. Can a completed Project be archived automatically?
7. What happens if a Project deadline is changed after activation?
8. What happens to a Project when its Goal is archived or completed?

---

# Change History

- Initial Project Management specification created during the SDD domain phase.
- Lifecycle approved as Draft → Active → Completed → Archived.
- Standalone Projects approved.
- Project completion defined as final.
- Draft Projects approved to contain Tasks.
- Completed Projects require all work to be resolved.
- Archived Projects preserve historical data and cannot be reactivated.
