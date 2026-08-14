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

- **Verified** — every acceptance criterion has passed against the
  implementation; the spec and code agree.
- **Deprecated** — the spec is superseded or the feature no longer exists.

## Amendments (keeping specs in sync with implementation)

Approved specs stay living documents. Implementation drifts from them
(human-driven changes, vibe-coded UI, ACs that prove impractical), and the
spec must be updated to stay the truthful source of behavior:

- Every mismatch is classified: **defect** (fix the code, never the spec)
  or **intended change** (amend the spec with human approval, never revert
  working code). Ambiguous cases stop and ask the human.
- Amendments keep AC IDs stable; changed ACs are marked `*(amended)*` and
  recorded in the spec's Change History with the reason.
- The governing plan tracks each AC's status (`PASS` / `FAIL` /
  `NOT VERIFIED` / `AMENDED`) as work proceeds.
- Spec changes are human-approved. Agents never self-approve amendments and
  never change specs to make a review pass.
- Agents use the `/spec-sync` command to run this workflow.

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
