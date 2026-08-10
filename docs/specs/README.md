# Specifications

Specifications are the source of truth for product behavior.

## Lifecycle

```text
Draft
  -> Proposed
  -> Approved
  -> Implementing
  -> Verified
  -> Deprecated
```

## Specification Template

```md
# Feature Name

## Status
Draft

## Problem

## Goal

## User Story

## Behavior

## Rules

## Constraints

## Acceptance Criteria

### AC-001

Given ...
When ...
Then ...

## Edge Cases

## Out of Scope

## Dependencies

## Open Questions

## Change History
```

## Rules

- Keep specifications focused on behavior and intent.
- Do not prescribe implementation details unless they are a real constraint.
- Make acceptance criteria testable.
- Explicitly document out-of-scope behavior.
- Resolve important ambiguity before implementation.
