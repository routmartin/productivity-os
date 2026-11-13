# Implementation Plans

Plans describe how an approved specification will be implemented at a particular
point in time.

A plan is not the source of truth for product behavior.

## Plan Template

```md
# Plan: Feature Name

## Status
Draft / Approved / Completed

## Specification
- Primary behavioral source of truth links
- Acceptance criteria in scope

## Architectural Decisions
- D1: Key architectural or product decision

## Agent Delegation Matrix

| Agent | Target Slice | Owned Files / Scope | Verification Command | Dispatch Brief |
| :--- | :--- | :--- | :--- | :--- |
| `@backend` | Slice 1 | `apps/api/**` | `./gradlew :apps:api:test` | Implement domain/service/endpoints per contract |
| `@frontend` | Slice 2 | `apps/web/**` | `pnpm typecheck && pnpm lint` | Implement UI components, stores, and views |
| `@ios-engineer` | Slice 3 | `apps/ios/**` | `swift test --package-path apps/ios` | Implement iOS platform screens and cache |
| `@code-reviewer` | Slice 4 | `git diff` | `./scripts/agent-review.sh` | Independent audit against specs and ADRs |

## Concurrent Implementation Slices

### Slice 1: Name
- **Assigned Agent:** `@backend` | `@frontend` | `@ios-engineer`
- **Files/Modules:** ...
- **Acceptance Criteria:** ...
- **Dispatch Brief:** Exact instructions for the assigned subagent
- **Verification Command:** ...

## Tests & QA Matrix

## Completion Checklist
```

Plans may become obsolete when implementation or architecture changes.
