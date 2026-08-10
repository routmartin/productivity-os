# Daily Planning

## Status

Draft

## Purpose

Define how users plan Tasks for specific calendar days, manage realistic daily
capacity, and handle unfinished planned work.

Daily Planning represents the user's intended work for a day.

It is distinct from Task lifecycle and Daily Top 3 prioritization.

---

## Product Principle

Daily Planning should help users plan according to **actual available
capacity**, rather than theoretical free time.

The system should make unrealistic plans visible without silently changing the
user's decisions.

---

## User Story

As a user,

I want to plan Tasks for specific days and understand whether my planned work
fits my available capacity,

so that I can make realistic commitments and plan ahead.

---

# Ownership

Every Daily Plan belongs to exactly one User.

A user cannot access or modify another user's Daily Plans.

---

# Calendar Day

A Daily Plan represents one calendar date in the user's configured timezone.

The calendar day runs from:

`00:00:00 → 23:59:59`

The user's timezone follows the same calendar-day rules defined by Daily Top 3.

---

# Task Planning

A Task can be planned for multiple different calendar dates.

Example:

```text
Task: Build authentication

Planned:
Aug 10
Aug 12
Aug 15
```

Each date represents a separate planning occurrence.

A Task may appear at most once in the plan for a given calendar date.

---

# Planning Record

A planning occurrence represents:

- User
- Task
- Calendar date
- Planning state
- Optional remark
- Rollover information when applicable

The planning occurrence is historical data and should not be silently removed
when the Task's state changes.

---

# Date Rules

### Past

Past dates are view-only.

Users cannot newly plan or reschedule Tasks into a past date.

Existing planning history remains available.

### Today

Today is editable.

Users may add, remove, or reschedule planned Tasks for today.

### Future

Future dates are editable.

Users may intentionally plan Tasks for future dates.

---

# One Task Per Day

A Task can appear at most once in a Daily Plan for the same calendar date.

If the user changes the planning details for that date, the existing planning
occurrence is updated rather than creating a duplicate.

Planning history must preserve meaningful changes.

---

# Manual Rescheduling

Users may manually reschedule a planned Task to another future date.

Manual rescheduling:

- is an intentional user action
- does not count toward automatic rollover limits
- creates/updates the appropriate planning occurrence
- preserves the previous planning history
- cannot target a past date

Manual rescheduling is unlimited.

---

# Automatic Rollover

If a planned Task remains incomplete when its planned calendar day ends, the
system automatically plans it for the next calendar day.

The new planning occurrence records that it was automatically carried over.

Example:

```text
Aug 10
Fix API bug
Status: incomplete

        ↓ automatic rollover

Aug 11
Fix API bug
Remark: Carried over from Aug 10
```

The original Aug 10 planning occurrence remains historical data.

---

# Automatic Rollover Limit

A Task may be automatically rolled over a maximum of **3 times** within the
same rollover chain.

Example:

```text
Aug 10
Original plan

Aug 11
Carried over #1

Aug 12
Carried over #2

Aug 13
Carried over #3

STOP
```

After the third automatic rollover:

- the system does not automatically plan the Task again
- the Task becomes unplanned
- the planning history remains available
- the user must intentionally plan the Task again

The system should show a warning explaining that the automatic rollover limit
has been reached.

---

# Rollover Remark

An automatically rolled-over planning occurrence must indicate that it was
carried over.

The remark should identify the previous planned date.

Example:

> Carried over from Aug 10

The exact presentation is a UI concern, but the underlying planning record
must preserve the rollover relationship.

---

# Completed Task

If a Task is completed before one or more future planned dates:

- the Task is removed from those future active plans
- the future planning occurrences are no longer active
- the planning history is preserved

Example:

```text
Aug 10
Task planned

Aug 12
Task planned

Task completed Aug 10

→ Aug 12 active plan removed
→ Aug 12 planning history preserved
```

---

# Cancelled Task

If a Task is cancelled:

- it is removed from future active plans
- its planning history is preserved

Cancelled Tasks are not automatically rolled over.

---

# Capacity

Each calendar day has an available work capacity.

Capacity is measured in hours in the initial version.

The user has a default daily capacity.

Example:

```text
Default capacity: 6h/day
```

The user can override the capacity for a specific date.

Example:

```text
Monday:    6h
Tuesday:   6h
Wednesday: 3h
Thursday:  6h
Friday:    4h
```

---

# Task Estimated Duration

A Task may have an estimated duration.

If a planned Task has an estimated duration, that duration contributes to the
planned workload for the day.

Tasks without an estimated duration do not contribute to capacity calculations.

---

# Capacity Calculation

For a given day:

```text
Planned Work = sum of estimated durations
               for active planned Tasks
               that have estimates

Available Capacity = user's configured capacity
                     for that date
```

If:

```text
Planned Work > Available Capacity
```

the system shows a capacity warning.

Example:

```text
Available: 4h
Planned:   5.5h

⚠️ Over capacity by 1.5h
```

---

# Capacity Warning

Capacity warnings are informational.

The system must not automatically:

- remove Tasks
- reschedule Tasks
- change priorities
- change Top 3
- reduce estimated durations

The user decides how to resolve an over-capacity day.

---

# Daily Capacity Override

The user may override the default daily capacity for an individual date.

The override applies only to that date.

Changing the default capacity does not retroactively overwrite existing
per-day overrides.

---

# Capacity and History

Capacity configuration for a date should be preserved sufficiently to support
historical planning analysis.

Future architecture will define whether this is represented as an explicit
daily record or a derived value.

---

# Relationship With Daily Top 3

Daily Planning and Daily Top 3 are separate concepts.

Daily Planning answers:

> What work do I intend to do on this day?

Top 3 answers:

> Which three tasks matter most today?

A Task may be planned for a day without being in Top 3.

A Top 3 Task should normally be part of that day's planned work.

Top 3 has its own rules and does not automatically carry unfinished priorities
to the next day.

The detailed Top 3 behavior is defined by:

`docs/specs/planning/daily-top-three.md`

---

# Relationship With Task Lifecycle

Task lifecycle and Daily Planning are independent.

A Task can exist without a Daily Plan.

Planning a Task does not automatically change its lifecycle state unless
explicitly defined by the Task specification.

Task lifecycle is defined by:

`docs/specs/tasks/task-management.md`

---

# Relationship With Projects

Daily Planning operates on Tasks.

Projects provide organizational context but are not themselves planned as
Daily Plan items.

A Project's deadline may influence future planning recommendations, but exact
prioritization behavior is outside this specification.

---

# Relationship With Goals

Goals provide strategic context.

Daily Planning does not directly plan Goals.

Goals influence planning indirectly through their Projects and Tasks.

---

# Edge Cases

## Task planned for multiple dates

A Task may have planning occurrences on multiple different dates.

Each date has at most one active planning occurrence for that Task.

## Task completed early

Future active planning occurrences are removed, while historical planning
records remain available.

## Task cancelled

Future active planning occurrences are removed, while historical planning
records remain available.

## Three automatic rollovers reached

The Task stops automatically rolling over and becomes unplanned.

The user must manually plan it again.

## Manual rescheduling after rollover limit

The user may manually plan the Task for a future date even after the automatic
rollover limit has been reached.

## No estimated duration

The Task remains part of the day's plan but does not contribute to the
capacity calculation.

## Over capacity

The system warns the user but does not automatically change the plan.

## No tasks planned

The Daily Plan remains valid and represents an empty planned day.

---

# Acceptance Criteria

### AC-001 — Plan Task

Given an authenticated user,

when the user plans a Task for an editable calendar date,

then a planning occurrence is created for that date.

### AC-002 — Multiple Dates

Given a Task belongs to the user,

when the user plans it for multiple different dates,

then each date has its own planning occurrence.

### AC-003 — No Duplicate Same Day

Given a Task is already planned for a calendar date,

when the user attempts to create another planning occurrence for the same
Task and date,

then the system prevents a duplicate occurrence.

### AC-004 — Past Date Protection

Given a calendar date is in the past,

when the user attempts to newly plan or reschedule a Task to that date,

then the operation is rejected.

### AC-005 — Today Editable

Given the calendar date is today,

when the user plans or reschedules a Task,

then the operation succeeds if other requirements are satisfied.

### AC-006 — Future Date Editable

Given the calendar date is in the future,

when the user plans or reschedules a Task,

then the operation succeeds if other requirements are satisfied.

### AC-007 — Manual Reschedule

Given a Task has an active planning occurrence,

when the user manually reschedules it to another future date,

then the new planning occurrence is created and the previous planning record
is preserved in history.

### AC-008 — Manual Reschedule Does Not Consume Rollover

Given a Task has an automatic rollover count,

when the user manually reschedules the Task,

then its automatic rollover count is unchanged.

### AC-009 — Automatic Rollover

Given a planned Task remains incomplete at the end of its planned day,

when the calendar day ends,

then the system creates a planning occurrence for the next calendar day and
records the rollover relationship.

### AC-010 — Rollover Remark

Given a Task is automatically rolled over,

when the new planning occurrence is created,

then it contains a remark identifying the previous planned date.

### AC-011 — Maximum Three Rollovers

Given a Task has been automatically rolled over three times,

when its current planned date ends while the Task remains incomplete,

then the system does not automatically plan it again.

### AC-012 — Rollover Limit Warning

Given a Task reaches the automatic rollover limit,

when automatic rollover stops,

then the user receives clear feedback that manual planning is required.

### AC-013 — Completed Early

Given a Task has future active planning occurrences,

when the Task becomes Completed before those dates,

then those future active planning occurrences are removed and their history
is preserved.

### AC-014 — Cancelled Task

Given a Task has future active planning occurrences,

when the Task becomes Cancelled,

then those future active planning occurrences are removed and their history
is preserved.

### AC-015 — Capacity

Given a user has configured daily capacity,

when the system calculates a day's plan,

then it calculates planned workload from estimated durations.

### AC-016 — Unknown Duration

Given a planned Task has no estimated duration,

when the system calculates planned workload,

then that Task contributes zero hours to the capacity calculation.

### AC-017 — Over Capacity

Given planned workload exceeds available capacity,

when the system calculates the day's plan,

then the system displays a capacity warning.

### AC-018 — No Automatic Capacity Changes

Given planned workload exceeds available capacity,

when the capacity warning is displayed,

then the system does not automatically remove, reschedule, reprioritize, or
modify Tasks.

### AC-019 — Default Capacity

Given the user has configured a default daily capacity,

when a date has no specific override,

then the default capacity applies.

### AC-020 — Daily Capacity Override

Given a user specifies a capacity override for a date,

when that date's plan is evaluated,

then the override is used instead of the default capacity.

### AC-021 — Override Persistence

Given a date has a capacity override,

when the user's default capacity changes,

then the existing date-specific override remains unchanged.

### AC-022 — Empty Daily Plan

Given no Tasks are planned for a date,

when the user views the Daily Plan,

then the day remains valid and shows no planned work.

### AC-023 — Planning History

Given a Task has been planned, rescheduled, rolled over, completed, or
cancelled,

when the user or system evaluates historical planning,

then the relevant planning history remains available.

---

# Constraints

1. Every Daily Plan belongs to exactly one User.
2. A Task can be planned for multiple dates.
3. A Task may have at most one active planning occurrence per calendar date.
4. Past dates are view-only.
5. Today and future dates are editable.
6. Automatic rollover is limited to three occurrences within a rollover chain.
7. Manual rescheduling does not consume automatic rollover allowance.
8. Capacity warnings do not automatically modify user plans.
9. Planning history must remain available for meaningful historical analysis.
10. AI must not silently create, remove, or reschedule Daily Plans.

---

# Out of Scope

- Calendar provider integration
- Calendar events
- Recurring planning rules
- Automatic priority selection
- Automatic Top 3 selection
- AI-generated plans
- AI-generated capacity estimates
- Notifications
- Time blocking
- Meeting scheduling
- Focus sessions
- Detailed progress calculations
- Weekly Review
- Team planning

---

# Dependencies

- User Management
- Task Management
- Project Management
- Goal Management
- Daily Top 3
- Progress
- Weekly Review

---

# Open Questions

1. What exactly constitutes the end-of-day trigger for automatic rollover in
   the backend?
2. What happens if a Task is completed/cancelled at exactly the calendar-day
   boundary?
3. How should multiple manual reschedules be represented in history?
4. Can users manually remove a Task from a future Daily Plan without
   rescheduling it?
5. Can a user manually disable automatic rollover for a specific Task?
6. Should capacity be measured only in hours, or eventually support minutes?
7. Should weekends have a default capacity of zero or inherit the default?
8. Should estimated duration be required for Tasks intended for Top 3?
9. What happens when an archived Project contains a future planned Task?
10. How should timezone changes affect existing Daily Plan dates?

---

# Change History

- Initial Daily Planning specification created during the SDD domain phase.
- Multi-date Task planning approved.
- Automatic rollover approved with a maximum of three rollovers.
- Rollover remarks approved.
- Manual rescheduling approved as unlimited and independent of rollover count.
- Completed and cancelled Tasks approved to be removed from future active plans
  while preserving planning history.
- Past dates approved as view-only.
- One active planning occurrence per Task per calendar date approved.
- Daily capacity approved with default capacity and per-day overrides.
- Capacity warnings approved as informational only.
