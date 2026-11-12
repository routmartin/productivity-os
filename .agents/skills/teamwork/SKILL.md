---
name: teamwork
description: "Orchestrate multi-agent workflows in Productivity OS: coordinates sdd-planner, Human Approval Gate, concurrent implementation (backend, frontend, ios via Swarm share), and independent code-reviewer."
---

# Teamwork — Multi-Agent SDD Orchestration

This skill guides the coordinator agent in managing end-to-end multi-agent execution across the Productivity OS stack (`apps/api`, `apps/web`, `apps/ios`).

## 4-Phase Lifecycle

```
[Feature Request]
       │
       ▼
Phase 1: Planning (sdd-planner)
       │
       ▼
Phase 2: Human Approval Gate (MANDATORY STOP)
       │ (Confirmed "Approved")
       ▼
Phase 3: Concurrent Execution (Swarm with workspace: "share")
       │
       ▼
Phase 4: Independent Verification (code-reviewer)
```

---

## Phase 1: Planning (`sdd-planner`)

- **Role**: `sdd-planner` subagent.
- **Action**:
  1. Inspect existing specs in `docs/specs/` and plans in `docs/plans/`.
  2. Enforce the **Endpoint Contract Rule**: Grep Kotlin controllers, DTOs, and exception handlers in `apps/api` before documenting endpoints.
  3. Author the spec (`docs/specs/<domain>/<feature>.md`) with testable Acceptance Criteria (`AC-001` in Given/When/Then).
  4. Author the vertical slice plan (`docs/plans/<number>-<feature>.md`) decomposing work across:
     - `Backend` (`apps/api`: Kotlin, Flyway, Spring Boot 3)
     - `Frontend` (`apps/web`: Vue 3, Pinia, TypeScript)
     - `iOS` (`apps/ios`: Swift, SwiftUI)
  5. List open design/product questions (`D1`, `D2`).

---

## Phase 2: Human Approval Gate (MANDATORY)

- In strict adherence to `AGENTS.md` ("Never self-approve a spec; human authority is preserved").
- **Coordinator Action**:
  1. Present the plan summary, ACs, and open decisions to the user.
  2. **Halt execution and yield turn.**
  3. Wait for the user to explicitly confirm: `"Approved"` (or provide adjustments).
  4. Never start coding before approval is given.

---

## Phase 3: Concurrent Execution (Native Swarm)

- **Isolation Requirement**: Always pass `workspace: "share"` so each worker gets its own isolated working copy, preventing git index collisions and build cache locks.
- **Swarm Setup**:
  ```json
  swarm({
    "action": "title",
    "title": "<Feature Name>"
  })
  ```
  ```json
  swarm({
    "action": "add",
    "name": "backend",
    "workspace": "share",
    "brief": "Own apps/api implementation per Plan Step 1. Run ./gradlew :apps:api:test."
  })
  ```
  ```json
  swarm({
    "action": "add",
    "name": "frontend",
    "workspace": "share",
    "brief": "Own apps/web implementation per Plan Step 2. Run pnpm run typecheck && pnpm run lint."
  })
  ```
  ```json
  swarm({
    "action": "add",
    "name": "ios",
    "workspace": "share",
    "brief": "Own apps/ios implementation per Plan Step 3. Run swift test --package-path apps/ios."
  })
  ```
- **Handoff & Notifications**: Specialists can notify peers over the board: `@frontend endpoint contracts finalized at /api/v1/...`.
- **Target Verification**: Each specialist verifies their own target before reporting done.

---

## Phase 4: Independent Verification (`code-reviewer`)

- Coordinator dispatches `code-reviewer` subagent:
  ```json
  invoke_subagent({
    "TypeName": "code-reviewer",
    "Role": "Independent Code Reviewer",
    "Prompt": "Review the current git working tree changes against AGENTS.md, docs/specs/, docs/plans/, and ADRs."
  })
  ```
- Reviewer checks:
  1. Spec adherence and Acceptance Criteria verification.
  2. Security & user isolation (ADR-004: JWT scoping).
  3. Architecture and module layering (ADR-002, ADR-007).
  4. Flyway database migrations and transactional boundaries (ADR-003).
  5. Timezone compliance (ADR-006).
- If `CHANGES_REQUIRED`: route issues to the responsible specialist agent (max 2 cycles).
- If `PASS`: present completion report to user.
