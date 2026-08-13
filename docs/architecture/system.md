# System Architecture

## Status

Proposed

## Purpose

Define the high-level architecture of the Personal Productivity OS as
established by the architecture decision records (ADR-001 through ADR-006) and
`docs/architecture/domain.md`, without prematurely locking implementation
details. This document describes structure and boundaries; schemas, endpoints,
and package layouts belong to implementation plans.

---

## System Purpose and Boundaries

The system is a multi-user, server-persisted, multi-device Personal
Productivity OS. It helps a user know what matters, plan ahead, decide what to
do next, focus, and review progress (product vision).

Inside the system boundary:

- Vue 3 + TypeScript single-page application (client)
- Spring Boot + Kotlin modular monolith (backend)
- PostgreSQL (single system of record)

Outside the system boundary:

- AI/LLM capabilities — an external intelligence service behind an explicit
  boundary; the product works entirely without it
- External identity providers — not in V1 (password authentication only)

---

## High-Level Architecture

```text
Vue 3 SPA (TypeScript)
    |  HTTPS, JSON, /api/v1, Bearer JWT (ADR-004, ADR-005)
    v
Spring Boot Modular Monolith (ADR-002)
    |
    |-- API layer: thin controllers, boundary validation, error mapping
    |-- Application services: use cases, orchestration, transactions
    |-- Domain modules: business rules and invariants
    |-- Persistence: Spring Data JPA repositories (ADR-003)
    |
    v
PostgreSQL (single system of record; Flyway-managed schema)

AI Service (external)
    ^-- domain read models flow out; recommendations flow in;
        the user decides (ADR-002, domain.md)
```

---

## Request Flow (Frontend → API → Backend → Database)

1. The SPA sends an HTTPS JSON request to `/api/v1/...` with a Bearer access
   token.
2. The authentication filter validates the JWT and populates the security
   context; identity is derived only from authenticated credentials (ADR-004).
3. A thin controller performs boundary validation and calls exactly one
   application service (ADR-005).
4. The application service orchestrates the use case: loads aggregates through
   user-scoped repositories, invokes domain rules, and commits one transaction
   (ADR-003).
5. Domain modules enforce invariants (lifecycle transitions, eligibility,
   ordering); violations surface as typed errors mapped to structured error
   responses with appropriate HTTP status codes (ADR-005).
6. All recorded time comes from the server clock, interpreted against the
   user's configured timezone (ADR-006).

---

## Modular Monolith Structure

The backend is one deployable unit with explicit internal module boundaries
(ADR-002). Modules are enforced mechanically from the start. Each feature is
implemented end-to-end as a small vertical slice that respects these
boundaries; AI agents must not cross module boundaries without an approved
plan.

---

## Core Domain Modules

Derived from `docs/architecture/domain.md`:

- **User** — identity, credentials, and profile (including the configured IANA
  timezone). Owns all other user data.
- **Goal** — meaningful outcomes; contains projects. (Spec drafted.)
- **Project** — bodies of work; zero-or-one goal; contains tasks. (Spec
  drafted.)
- **Task** — actionable work with a controlled lifecycle, soft delete, and
  restore. Specified: `docs/specs/tasks/task-management.md`.
- **Planning** — daily plans: intended work per calendar date. (Spec drafted.)
- **Daily Top 3** — the daily prioritization relationship (user, date, task,
  position). Specified: `docs/specs/planning/daily-top-three.md`.
- **Focus** — focus sessions associated with tasks. (Future specification.)
- **Weekly Review** — reflection over productivity data. (Future
  specification.)
- **AI** — not a domain module; an external capability producing
  recommendations that never silently modify user data.

---

## Authentication and User-Isolation Boundary

Per ADR-004: Spring Security with password authentication, stateless
short-lived JWT access tokens, and server-side rotating per-device refresh
tokens. User identity is resolved from the authenticated security context on
every request — never from client-supplied identifiers. Every query is scoped
to the authenticated user; cross-user access is rejected without disclosing
resource existence. No anonymous access to domain data; no OAuth/social login
in V1.

## Timezone and Date Handling Boundary

Per ADR-006: all timestamps are UTC instants (`timestamptz`, `Instant`);
date-only concepts use `LocalDate` interpreted in the user's configured IANA
timezone; calendar days are 00:00:00–23:59:59 local; attributed dates are
immutable across timezone changes; server receipt time is authoritative; all
conversions are centralized and no custom timezone arithmetic exists anywhere.

## Persistence Boundary

Per ADR-003: PostgreSQL is the single system of record. Spring Data
JPA/Hibernate repositories are accessed only from application services. Flyway
owns all schema change. UUID identifiers. Soft deletion where specifications
require it. Each use case commits as a single transaction. Optimistic
versioning on multi-device aggregates. No Redis, MongoDB, CQRS, event
sourcing, sharding, or read replicas in V1.

## AI Service Boundary

AI is an external capability, not part of the core domain (domain.md). Domain
data flows out to the AI service; recommendations flow back; the user decides.
Deterministic product behavior is fully testable without an LLM, and AI must
never silently change user data (Task Management Rule 14).

## API Boundary

Per ADR-005: REST over HTTP with JSON under `/api/v1`; resource-oriented
endpoints with explicit operation endpoints for domain actions; thin
controllers; boundary validation; a consistent structured error model carrying
the specifications' "clear feedback"; ISO-8601 timestamps and dates;
pagination on large collections; generated OpenAPI documentation. No GraphQL
or tRPC in V1.

---

## Dependency Direction Between Modules

Dependencies point inward, toward the domain:

```text
API layer → Application services → Domain modules
Domain modules → Domain primitives only (never outward)
```

Cross-module rules:

- Modules never reach into each other's persistence or internals; interaction
  happens through application services.
- Cross-module references use identifiers (for example, Daily Top 3 references
  a Task by ID), not object graphs.
- Planning and Daily Top 3 may read Task state; Task does not depend on
  Planning or Daily Top 3.
- The User module provides identity to all modules; no module depends on AI.

---

## Development Principles

Carried forward, and extended by the ADRs:

- **Domain-first behavior** — business rules live in domain/application
  services, never in controllers or UI code.
- **Clear AI boundary** — deterministic behavior remains testable without an
  LLM.
- **Specification traceability** — behavioral changes trace from specification
  to tests to implementation; specification before implementation (AGENTS.md,
  ADR-001).
- **Small vertical slices** — features are implemented end-to-end in small,
  reviewable slices.
- **One transaction per use case** (ADR-003).
- **Centralized time handling** — no custom timezone arithmetic (ADR-006).
- **Enforced module boundaries** — verified mechanically (ADR-002).

---

## References

- [ ] Architecture Decision Records

* `docs/decisions/ADR-001-sdd-workflow.md` — specification-first workflow
  (Accepted)
* `docs/decisions/ADR-002-technology-stack.md` — Spring Boot/Kotlin, Vue 3/TS,
  PostgreSQL, modular monolith, REST
* `docs/decisions/ADR-003-database-persistence.md` — persistence, migrations,
  soft delete, concurrency
* `docs/decisions/ADR-004-authentication-user-isolation.md` — authentication
  and user isolation
* `docs/decisions/ADR-005-api-architecture.md` — REST conventions, error
  model, versioning
* `docs/decisions/ADR-006-time-and-timezone.md` — time and timezone handling

### Architecture

- `docs/architecture/domain.md` — domain concepts and relationships

### Specifications

- `docs/specs/tasks/task-management.md`
- `docs/specs/planning/daily-top-three.md`
- Drafted: `docs/specs/goals/goal-management.md`,
  `docs/specs/projects/project-managment.md`,
  `docs/specs/planning/daily-planning.md`
- Future: Focus Sessions, Weekly Review, Progress, AI Recommendations

## Change History

- Initial high-level architecture (pre-stack).
- Rewritten to reflect ADR-001 through ADR-006, the domain architecture, and
  the current specification suite; status changed from Initial to Proposed.
