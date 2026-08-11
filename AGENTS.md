# AGENTS.md

## Project

This repository contains a Personal Productivity OS and is also an experimental
laboratory for Spec-Driven Development (SDD) with AI.

The product helps users:
- define meaningful goals
- plan ahead
- decide what to do next
- focus on meaningful work
- measure real progress
- learn from their behavior
- improve planning over time

## Core Development Principle

Specification before implementation.

No significant feature should be implemented without an approved specification.

## Source of Truth

When implementing behavior, use this priority:
1. Approved specification
2. Architecture documentation
3. Architecture Decision Records
4. Existing code
5. Tests
6. Agent assumptions

If these conflict, stop and report the conflict. Do not silently choose an interpretation.

## Before Coding

The agent MUST:
1. Read the relevant specification.
2. Read relevant architecture documentation.
3. Inspect existing implementation.
4. Identify dependencies and affected areas.
5. Produce an implementation plan.
6. Wait for approval when the workflow requires it.

Do not modify code during analysis/planning.

## Implementation Rules

- Implement only the approved scope.
- Do not add unrelated improvements.
- Do not change requirements.
- Prefer existing project patterns.
- Keep changes small and reviewable.
- Add or update tests for behavioral changes.
- Do not introduce dependencies without justification.
- Do not perform unrelated refactoring.

## Architecture Changes

If implementation requires a significant architectural change, STOP and propose an ADR before implementation.

## Testing

Every behavioral requirement should have verification.

Before reporting completion:
1. Run relevant tests.
2. Run static analysis.
3. Verify acceptance criteria.
4. Check for regressions.

Never remove or weaken tests simply to make them pass.

## Completion Report

Every implementation must report:
- Summary
- Specification
- Files Changed
- Acceptance Criteria: PASS / FAIL / NOT VERIFIED
- Tests
- Deviations
- Risks
- Follow-ups

## AI Team Workflow

### OpenCode

OpenCode is the primary engineer and orchestrator. It may:

- implement code
- modify tests
- modify migrations
- run commands
- fix implementation issues
- invoke the Cline reviewer

It must not silently change product requirements, specifications, ADRs, or
architecture decisions.

### Cline

Cline is the independent code reviewer. It:

- reviews implementation against the repository source of truth
- checks correctness, security, architecture, API, database, and specification
  compliance
- does not modify application source code during review
- reports findings with severity (Critical, High, Medium, Low)
- does not invent product decisions

### Review loop

After completing a logical implementation milestone:

1. OpenCode reviews its own diff.
2. OpenCode runs `scripts/agent-review.sh`.
3. OpenCode reads `docs/reviews/current-review.md`.
4. If **PASS**, the milestone is review-complete.
5. If **CHANGES_REQUIRED**, OpenCode fixes the valid issues and reruns the
   reviewer (maximum two review/fix cycles).
6. If still blocked after two cycles, stop and ask the human.

Testing environment problems (Docker, Testcontainers, etc.) should not block
implementation unless the current task explicitly requires test verification.

### Human authority

Product decisions and significant architecture decisions remain
human-controlled. Agents must stop rather than silently invent decisions.
