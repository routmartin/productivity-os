# Goal Management

## Status

Proposed

## Purpose

Define the behavior and lifecycle of Goals in the Productivity OS.

A Goal represents a meaningful outcome the user wants to achieve.

---

## Problem

Users need a way to define meaningful outcomes, organize Projects toward those
outcomes, and reflect on whether they are moving toward what matters.

---

## Goal

Provide a predictable Goal lifecycle that supports:

- defining desired outcomes
- organizing Projects around outcomes
- completing meaningful outcomes
- preserving historical outcomes
- reopening completed Goals intentionally when circumstances change

---

## User Story

As a user,

I want to define meaningful Goals and organize Projects around them,

so that I can focus my work on outcomes that matter.

---

# Ownership

Every Goal belongs to exactly one User.

A user cannot access or modify another user's Goals.

---

# Project Relationship

A Goal may contain zero or more Projects.

A Project may belong to zero or one Goal.

### Rules

1. A Goal belongs to exactly one User.
2. A Goal may contain zero or more Projects.
3. A Project belongs to zero or one Goal.
4. A Goal cannot contain a Project owned by another User.
5. A Goal can exist independently without any Projects.

---

# Goal Lifecycle

A Goal follows this lifecycle:

```text
Draft
  ↓
Active
  ↓
Completed
  ↓
Archived
```

A completed Goal may be reopened:

```text
Completed
    ↓
Active
```

An Archived Goal cannot be reopened.

An Active Goal may return to Draft:

```text
Active
    ↓
Draft
```

---

# Draft

A Draft Goal represents an outcome that has been defined but is not yet
actively being pursued.

A Draft Goal may have Projects.

Draft Goals are not considered active goals.

---

# Active

An Active Goal represents an outcome the user is currently pursuing.

Its Projects may be actively worked on according to their own lifecycle.

---

# Completed

A Completed Goal represents an achieved outcome.

### Completion rules

A Goal may be completed when:

- it has no Projects, or
- every associated Project is either `Completed` or `Cancelled`.

Projects in `Draft` or `Active` state prevent Goal completion.

When a Goal becomes Completed:

- its completion timestamp is recorded
- the Goal becomes part of historical data
- all associated Projects are automatically moved to `Archived`

Goal completion is not permanently terminal because a Completed Goal may be
reopened.

---

# Reopening a Completed Goal

A Completed Goal may be reopened and returns to `Active`.

When reopening:

1. The system presents the Goal's previously archived Projects.
2. The user chooses which Projects to reactivate.
3. Selected Projects are reactivated according to the Project lifecycle rules.
4. Projects not selected remain Archived.

The system must not automatically reactivate every Project.

This makes reopening an intentional planning decision.

---

# Archived

An Archived Goal represents a completed Goal that has been moved out of active
visibility.

An Archived Goal:

- remains available as historical data
- cannot be reopened
- cannot contain newly active work

---

# Project Archiving During Goal Completion

When a Goal is completed, all associated Projects are automatically archived.

This includes Projects that were:

- Completed
- Cancelled

A Project's historical state before Goal completion must remain available for
historical reporting.

The exact historical representation of automatic archiving will be defined
during architecture.

---

# Project Reactivation During Goal Reopening

When a Completed Goal is reopened:

- the Goal becomes Active
- the user is shown previously archived Projects associated with the Goal
- the user chooses which Projects to reactivate
- selected Projects become Active
- unselected Projects remain Archived

A Project that was previously Cancelled may require special handling when
selected for reactivation. The exact rule must remain consistent with the
Project specification.

---

# Standalone Goals

A Goal may exist without Projects.

Example:

```text
Goal
└── Improve my health
```

The user may complete such a Goal directly.

---

# Goal Title

A Goal must have a non-empty title.

The title should describe a meaningful desired outcome rather than an
individual action.

Example:

Good:

> Become proficient in Spring Boot

Not a Goal:

> Read Spring Boot documentation

The latter is better represented as a Task.

---

# Goal Description

A Goal may contain additional context describing:

- why the Goal matters
- what success means
- relevant constraints

The exact structure of this information will be refined during design.

---

# Goal Deadline

A Goal may optionally have a target/deadline date.

The deadline represents when the user intends to achieve the Goal.

The exact behavior for overdue Goals will be defined by the Planning
specification.

---

# Goal Progress

Goal progress should primarily be derived from its Projects and meaningful
execution data.

The system should avoid requiring users to manually maintain arbitrary
percentage values.

Exact progress calculation will be defined by the Progress specification.

---

# Relationship With Projects

```text
Goal
 └── Projects
      └── Tasks
```

A Goal does not directly own Tasks.

Tasks belong to Projects or remain as Inbox Tasks.

---

# Relationship With Daily Planning

Daily Planning operates primarily on Tasks.

Goals provide strategic context for planning but are not directly selected
as Daily Top 3 items.

A future planning system may use Goal alignment when recommending work.

---

# Relationship With Weekly Review

Weekly Review may analyze:

- Goal progress
- completed Projects
- cancelled Projects
- completed Tasks
- Focus Sessions
- planned versus actual work

The exact Weekly Review behavior will be defined by a future specification.

---

# Edge Cases

## Goal with no Projects

A Goal without Projects is valid and may be completed directly.

## Goal with Active Project

An Active Project prevents Goal completion.

## Goal with Draft Project

A Draft Project prevents Goal completion.

## Goal with Completed Project

A Completed Project satisfies the Goal completion requirement.

## Goal with Cancelled Project

A Cancelled Project satisfies the Goal completion requirement.

## Goal with mixed Projects

A Goal containing only Completed and Cancelled Projects may be completed.

A Goal containing any Draft or Active Project cannot be completed.

## Reopening Goal

Reopening requires the user to choose which archived Projects should become
Active.

## Archived Goal

An Archived Goal cannot be reopened.

---

# Acceptance Criteria

### AC-001 — Goal Creation

Given an authenticated user,

when the user creates a valid Goal,

then the Goal is created in `Draft`.

### AC-002 — Goal Ownership

Given a Goal belongs to User A,

when User B attempts to access or modify it,

then the operation is rejected.

### AC-003 — Draft to Active

Given a Goal is `Draft`,

when the user activates it,

then the Goal becomes `Active`.

### AC-004 — Goal Without Projects

Given a Goal has no Projects,

when the user completes the Goal,

then the Goal becomes `Completed`.

### AC-005 — Prevent Completion With Active Project

Given a Goal contains an `Active` Project,

when the user attempts to complete the Goal,

then completion is rejected.

### AC-006 — Prevent Completion With Draft Project

Given a Goal contains a `Draft` Project,

when the user attempts to complete the Goal,

then completion is rejected.

### AC-007 — Complete With Resolved Projects

Given all Projects belonging to a Goal are `Completed` or `Cancelled`,

when the user completes the Goal,

then the Goal becomes `Completed`.

### AC-008 — Automatic Project Archiving

Given a Goal is successfully completed,

when completion succeeds,

then all associated Projects become `Archived`.

### AC-009 — Completion Timestamp

Given a Goal transitions to `Completed`,

when the transition succeeds,

then the system records the completion timestamp.

### AC-010 — Reopen Completed Goal

Given a Goal is `Completed`,

when the user chooses to reopen it,

then the Goal becomes `Active`.

### AC-011 — Reopening Requires Project Selection

Given a Completed Goal has archived Projects,

when the user reopens the Goal,

then the system presents those Projects for reactivation selection.

### AC-012 — Select Projects to Reactivate

Given a user reopens a Completed Goal,

when the user selects specific archived Projects,

then the selected Projects become `Active`.

### AC-013 — Unselected Projects Remain Archived

Given a user reopens a Completed Goal,

when the user does not select certain archived Projects,

then those Projects remain `Archived`.

### AC-014 — Archived Goal Cannot Reopen

Given a Goal is `Archived`,

when the user attempts to reopen it,

then the operation is rejected.

### AC-015 — Standalone Goal

Given a Goal has no Projects,

when the user views the Goal,

then it remains valid and usable.

### AC-016 — Goal Deadline

Given a Goal has a deadline,

when the user views the Goal,

then the deadline is available as part of the Goal information.

### AC-017 — Goal Ownership of Projects

Given a Goal belongs to User A,

when User B attempts to associate a Project with that Goal,

then the operation is rejected.

### AC-018 — Goal With Mixed Project States

Given a Goal contains at least one Draft or Active Project,

when the user attempts to complete the Goal,

then completion is rejected.

### AC-019 — Goal With Completed and Cancelled Projects

Given every Project belonging to a Goal is either Completed or Cancelled,

when the user completes the Goal,

then the Goal becomes Completed and its Projects become Archived.

---

# Constraints

1. Every Goal belongs to exactly one User.
2. A Goal may contain zero or more Projects.
3. A Project belongs to zero or one Goal.
4. A Project and Goal must belong to the same User.
5. Draft and Active Projects prevent Goal completion.
6. Completed and Cancelled Projects satisfy Goal completion requirements.
7. Completing a Goal automatically archives its Projects.
8. Completed Goals may be reopened.
9. Reopening requires explicit Project reactivation selection.
10. Archived Goals cannot be reopened.
11. AI must not silently change Goal lifecycle state.

---

# Out of Scope

- Goal collaboration
- Goal sharing
- Multiple owners
- Goal templates
- Goal recurrence
- Goal dependencies
- Goal automation
- AI-generated Goals
- AI-generated Goal plans
- Detailed progress calculations
- Calendar integration
- Notifications
- Social features

---

# Dependencies

- User Management
- Project Management
- Task Management
- Daily Planning
- Progress
- Weekly Review

---

# Resolved Questions

1. **Goal priority?** None for V1. Priority emerges from Daily Top 3 and Daily Planning.
2. **Success criteria?** None for V1. Success is determined by project completion. Progress spec will define this later.
3. **Deadline when reopened?** Stays as-is. User updates manually if needed.
4. **Add projects to reopened goal?** Yes. After reopen, the goal is Active — works like any Active goal.
5. **Project independently archived while goal Active?** It is resolved and stays archived. Does not block completion.
6. **Cancelled project during goal reopen?** N/A in V1. Projects do not have a CANCELLED state. Revisit if added later.
7. **Draft → Completed directly?** No. Must go Draft → Active → Completed.
8. **Active → Draft?** Yes. Returns a goal to planning. Added to lifecycle.
9. **Change projects while Active?** Yes. Add/remove freely while Draft or Active.
10. **Confirmation for goal completion?** UI concern. API performs the action; frontend confirms.
11. **Projects when Active Goal archived?** Cannot happen. Only Completed goals can be archived. Moot.


---

# Change History

- Resolved all 11 open questions: no V1 priority/success criteria, deadline stays on reopen,
  projects can be added after reopen, independently archived projects are resolved, no
  CANCELLED state for projects in V1, no Draft→Completed shortcut, Active→Draft allowed,
  projects changeable while Active, confirmation is UI concern, Active goal archival not
  possible. Added Active→Draft to lifecycle. Status changed to Proposed.
