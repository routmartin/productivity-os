# Domain Architecture

## Status

Proposed

## Purpose

Define the core domain concepts and their relationships for the Personal
Productivity OS.

This document describes product/domain behavior, not database tables or
framework-specific implementation.

---

## Core Domain

The core domain consists of:

- User
- Goal
- Project
- Task
- Daily Plan
- Daily Priority
- Focus Session
- Weekly Review

AI is an external intelligence capability that operates on domain information
and produces recommendations. It is not part of the core domain model.

---

## User

A User owns and controls their personal productivity data.

Every user-owned domain object must be associated with exactly one user.

Users cannot access another user's private productivity data.

### User owns

- Goals
- Projects
- Tasks
- Daily Plans
- Focus Sessions
- Weekly Reviews

---

## Goal

A Goal represents a meaningful outcome the user wants to achieve.

A Goal answers:

> Where am I trying to go?

Examples:

- Become proficient in Spring Boot
- Launch the Productivity OS
- Save a specific amount of money

A Goal may contain multiple Projects.

A Goal does not directly own Tasks.

### Relationship

```text
User
 └── Goal
      └── Projects
```

---

## Project

A Project represents a body of work intended to produce a meaningful outcome.

A Project may optionally belong to one Goal.

A Project may exist without a Goal.

Examples:

- Build Productivity OS MVP
- Deploy backend infrastructure
- Home maintenance

### Rules

- A Project belongs to exactly one User.
- A Project may belong to zero or one Goal.
- A Goal may contain many Projects.
- A Project contains zero or more Tasks.

---

## Task

A Task represents an actionable unit of work that the user can start and
complete.

A Task answers:

> What can I actually do?

Examples:

- Create authentication endpoint
- Write integration tests
- Research Spring Security

### Rules

- A Task belongs to exactly one User.
- A Task may belong to zero or one Project.
- A Task cannot belong to multiple Projects.
- A Task may exist without a Project.
- A Task without a Project is considered an Inbox task.
- A Task can be moved from Inbox into a Project later.

### Important distinction

A Task is not a Goal.

A Task is not a Project.

A Task represents actionable work.

---

## Inbox

Inbox is the conceptual collection of Tasks that do not currently belong to
a Project.

Inbox is not necessarily a separate domain entity.

```text
User
 ├── Project A
 │    ├── Task 1
 │    └── Task 2
 │
 └── Inbox
      ├── Task 3
      └── Task 4
```

The user can later assign an Inbox task to a Project.

---

## Daily Plan

A Daily Plan represents the user's intended work for a specific calendar day.

A Daily Plan answers:

> What do I intend to accomplish on this day?

A Daily Plan belongs to exactly one User and one calendar date.

A Task may be included in a Daily Plan without becoming a different kind of Task.

The Daily Plan is used to compare planned work against actual work.

---

## Daily Priority / Top 3

Top 3 represents the user's highest-priority tasks for a specific day.

Top 3 is not a separate Task type or entity.

It is a daily prioritization relationship between:

- User
- Calendar date
- Task
- Position

Positions are:

1. Highest priority
2. Second priority
3. Third priority

A day may contain zero to three Top 3 tasks.

### Rules

- A Task can appear in Top 3 for multiple different dates.
- A Task cannot appear more than once in Top 3 for the same date.
- A Task's Top 3 position is specific to a calendar date.
- Completed tasks already in Top 3 remain in that day's Top 3.
- Removing a Top 3 task shifts remaining tasks upward.
- Top 3 does not automatically carry unfinished tasks into another date.

The detailed behavior is defined by:

`docs/specs/planning/daily-top-three.md`

---

## Focus Session

A Focus Session represents a period during which the user intentionally
works on a Task.

Example:

```text
Task:
Implement referral system

Focus Session:
09:30 → 10:17
```

A Focus Session belongs to one User and is associated with a Task.

Focus Sessions provide the basis for measuring actual focused effort.

Future capabilities may include:

- duration
- interruptions
- notes
- focus quality

These details are not yet part of the approved domain scope.

---

## Weekly Review

A Weekly Review represents a period of reflection over the user's work.

It can analyze:

- Goals
- Projects
- Tasks
- Daily Plans
- Focus Sessions

A Weekly Review should help answer:

- What went well?
- What did not go as planned?
- Where did time go?
- What blocked progress?
- What should change next week?

The exact Weekly Review behavior will be defined by a future specification.

---

## Progress

Progress is primarily a derived concept.

The system should avoid treating arbitrary percentage values as the primary
source of truth.

Meaningful progress can be derived from:

```text
Goals
  ↓
Projects
  ↓
Tasks
  ↓
Completed work
  ↓
Actual execution
```

The exact progress calculation rules will be defined later.

---

## AI Capability

AI is not part of the core domain model.

AI operates as an external capability:

```text
Domain Data
    ↓
AI Service
    ↓
Recommendation
    ↓
User Decision
```

Examples:

- Recommend today's priorities
- Break a project into tasks
- Suggest the next action
- Analyze weekly progress

AI recommendations should not silently modify important user data.

The user should remain in control.

---

## Domain Relationship Summary

```text
User
 │
 ├── Goals
 │    └── Projects
 │         └── Tasks
 │
 ├── Inbox Tasks
 │
 ├── Daily Plans
 │    └── Daily Priorities / Top 3
 │         └── Tasks
 │
 ├── Focus Sessions
 │    └── Tasks
 │
 └── Weekly Reviews
      └── analyzes productivity data
```

---

## Architectural Boundaries

This document intentionally does not define:

- database tables
- JPA entities
- REST endpoints
- controllers
- frontend components
- Spring Boot packages
- Kotlin implementation details

Those belong to later architecture and implementation stages.

---

## Related Specifications

- `docs/specs/planning/daily-top-three.md`

Future specifications will define:

- Goal Management
- Project Management
- Task Management
- Daily Planning
- Focus Sessions
- Progress
- Weekly Review
- AI Recommendations
