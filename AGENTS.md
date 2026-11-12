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

### Team Roles

The AI engineering team consists of specialized autonomous agents:

- **Coordinator**: The primary orchestrator and pair-programming partner to the human. Manages user requests, schedules subagents or Native Swarms, enforces human approval gates, and reports outcomes.
- **SDD Planner (`sdd-planner`)**: Specialist for specification authoring and implementation planning. Authors specs in `docs/specs/`, writes plans in `docs/plans/`, validates backend endpoint contracts, and manages spec drift via `spec-sync`. Does not modify production code during planning.
- **Backend Specialist (`backend`)**: Specialist for Kotlin, Spring Boot 3, Spring Data JPA, Flyway migrations, and PostgreSQL in `apps/api`.
- **Frontend Specialist (`frontend`)**: Specialist for Vue 3, TypeScript, Pinia, and Vite in `apps/web`.
- **iOS Specialist (`ios-engineer`)**: Specialist for Swift 5.9+, SwiftUI, APICache, and Apple platform features in `apps/ios`.
- **Full-Stack Engineer (`full-stack`)**: Specialist for cross-cutting vertical slices spanning both `apps/api` and `apps/web`.
- **Code Reviewer (`code-reviewer` / `Cline`)**: Independent reviewer verifying changes against specifications, architecture docs, and ADRs. Does not modify application source code.

### 4-Phase Orchestration Lifecycle

Complex vertical slices follow a structured 4-phase lifecycle:

1. **Phase 1: Planning (`sdd-planner`)**
   - The coordinator invokes `sdd-planner` to analyze requirements and existing code.
   - Enforces the **Endpoint Contract Rule**: inspects Kotlin controllers, DTOs, and exception handlers before documenting endpoints.
   - Outputs: testable specification in `docs/specs/` (`AC-001` format) and actionable plan in `docs/plans/` with target slice breakdowns.

2. **Phase 2: Human Approval Gate (Mandatory Stop)**
   - The coordinator presents the plan summary, ACs, and open decisions to the user and halts execution.
   - Implementation MUST NOT proceed without explicit human confirmation (`"Approved"`).

3. **Phase 3: Concurrent Implementation (Native Swarm / Subagents)**
   - When multiple targets (`backend`, `frontend`, `ios`) can be developed simultaneously, the coordinator launches a Native Swarm with `workspace: "share"` to give each specialist an isolated working copy and prevent git/build collisions.
   - Specialists build against locked contracts and verify their work using target tests:
     - Backend: `./gradlew :apps:api:test`
     - Frontend: `pnpm run typecheck && pnpm run lint`
     - iOS: `swift test --package-path apps/ios`

4. **Phase 4: Independent Verification (`code-reviewer`)**
   - The coordinator dispatches `code-reviewer` (or runs `scripts/agent-review.sh`).
   - Verifies compliance against Source-of-Truth priority: correctness, security (ADR-004), architecture (ADR-007), database migrations (ADR-003), and timezones (ADR-006).

### Review loop

After completing a logical implementation milestone:

1. The implementing agent reviews its own diff.
2. The coordinator runs `scripts/agent-review.sh` or invokes the `code-reviewer` subagent.
3. If **PASS**, the milestone is review-complete.
4. If **CHANGES_REQUIRED**, the issues are routed back to the responsible specialist agent to fix (maximum two review/fix cycles).
5. If still blocked after two cycles, stop and escalate to the human.

Testing environment problems (Docker, Testcontainers, etc.) should not block implementation unless the current task explicitly requires test verification.

### Human authority

Product decisions and significant architecture decisions remain human-controlled. Agents must stop rather than silently invent decisions.
