# ADR-002: Technology Stack — Spring Boot/Kotlin, Vue 3/TypeScript, PostgreSQL, Modular Monolith, REST

## Status

Accepted

## Context

The SDD foundation is complete and the first specifications exist: Daily Top 3
(Proposed) and Task Management (Draft), with Goal, Project, and Daily Planning
specifications drafted. No application code exists yet.

`docs/architecture/system.md` deliberately mandates no framework and requires
technology choices to be captured in ADRs. A stack must now be chosen before the
first implementation slice.

The specifications impose concrete technical demands:

- Server-persisted, user-scoped data with strict isolation between users.
- Multi-device synchronization with last-write-wins based on server receipt time.
- A controlled task lifecycle (state machine with a terminal Completed state,
  soft delete, and restore).
- Calendar-day semantics (00:00:00–23:59:59) in the user's configured timezone,
  with completion timestamps and frozen historical views.
- An ordered, uniqueness-constrained Top 3 per user and date.
- Deterministic domain behavior that remains testable without an LLM, with AI
  behind an explicit service boundary.

This project is also an SDD experiment: changes must stay small, reviewable, and
traceable from specification to tests.

## Decision Drivers

- Strong, explicit domain modeling (lifecycle state machine, invariants).
- Testability of deterministic behavior without an LLM.
- Data integrity: user isolation, transactional multi-step updates (Top 3 slot
  shifts, soft delete/restore), timezone-correct timestamps.
- Operational simplicity for a single developer working with AI agents.
- Small, reviewable vertical slices; fast local iteration.
- Mature ecosystem, documentation, and learning resources.
- Fits the existing monorepo layout (`apps/`, `packages/`).

## Options

### Backend

- Option A — Spring Boot + Kotlin
- Option B — Node.js + TypeScript (NestJS or Express)
- Option C — Django (Python) or Rails (Ruby)

### Frontend

- Option A — Vue 3 + TypeScript
- Option B — React + TypeScript
- Option C — Svelte/SvelteKit

### Database

- Option A — PostgreSQL
- Option B — MySQL
- Option C — SQLite or a document store (MongoDB)

### Architecture style

- Option A — Modular monolith
- Option B — Microservices
- Option C — Serverless functions

### API style

- Option A — REST
- Option B — GraphQL
- Option C — RPC (tRPC/gRPC)

## Decision

Adopt:

- **Backend:** Spring Boot + Kotlin
- **Frontend:** Vue 3 + TypeScript
- **Database:** PostgreSQL
- **Architecture:** Modular monolith
- **API style:** REST

## Reasoning

### Why this stack fits this project

- **Spring Boot + Kotlin** maps directly onto the specification style: the task
  lifecycle is a state machine with a terminal state and rejected invalid
  transitions, which Kotlin models precisely (sealed/enum states, exhaustive
  `when`). Spring provides transaction boundaries for multi-step invariants
  (Top 3 shift-up, soft delete/restore, slot occupancy), and `java.time` handles
  the timezone-correct day boundaries and completion timestamps the specs
  require. JUnit 5 + Testcontainers give a mature path to
  acceptance-criteria-level tests against real PostgreSQL.
- **Vue 3 + TypeScript** fits a dashboard-centric product: single-file components
  and the Composition API keep the daily dashboard, Top 3 ordering, and historical
  views straightforward, with end-to-end type safety against the REST API. Its
  gentle learning curve suits a learning-oriented project.
- **PostgreSQL** matches the data shape: relational integrity for user-scoped
  ownership, a natural uniqueness constraint for Top 3 (user, date, position),
  reliable `timestamptz` handling, and JSONB headroom for future AI metadata.
- **Modular monolith** matches the "small vertical slices" principle and the
  single-developer + AI-agent workflow: one deployable, explicit internal module
  boundaries (users, tasks, projects, planning), no distributed-systems overhead.
  Modules can be extracted later if ever justified.
- **REST** is sufficient for the resource shape (tasks, projects, daily plans,
  daily-top-three), has ubiquitous tooling, and supports a simple, consistent
  error model — which the specifications need ("rejected with clear feedback").

## Consequences

### Positive

- Deterministic core remains fully testable without an LLM, preserving the AI
  service boundary required by the architecture.
- Strong compile-time and database-level enforcement of specification
  invariants (lifecycle transitions, user isolation, Top 3 uniqueness).
- One backend deployable and one database: simple local development and CI,
  fast iteration for the SDD experiment.
- Clear module seams for AI agents to work within, keeping changes small and
  reviewable.

### Negative

- Two languages (Kotlin, TypeScript): context-switching cost.
- JVM build and startup are heavier than Node.js alternatives.
- Modular monolith boundaries require active discipline (package rules, e.g.
  ArchUnit) or they erode.
- REST may require purpose-built aggregation endpoints (e.g., dashboard views)
  that GraphQL would make more flexible.
- Learning curve where the stack is unfamiliar (see below).

## Development and Learning Implications

- Learning investment needed: Kotlin idioms (null-safety, coroutines), Spring
  Boot (Web, Data/JPA, Security), Vue 3 Composition API, PostgreSQL
  timezone/type behavior. This is accepted as part of the project's learning
  goals.
- Local environment: current JDK, Node LTS + pnpm, Dockerized PostgreSQL;
  Gradle build for the backend, Vite for the frontend.
- Module boundaries (users, tasks, projects, planning) should be enforced
  mechanically from the start.
- AI agents must implement one vertical slice at a time and must not cross
  module boundaries without an approved plan.
- If a module is ever extracted into a separate service, that requires a new
  ADR superseding parts of this one.

## Rejected Alternatives

- **Node.js + TypeScript backend:** one language across the stack, but weaker
  compile-time domain invariants and a less integrated
  persistence/transaction story for the specification's state-machine and
  integrity needs.
- **Django/Rails:** productive, but further from the chosen type-safe, explicit
  domain-modeling style.
- **React:** larger ecosystem, but more decision fatigue and boilerplate than
  Vue for this project's scope and learning goals.
- **Microservices / serverless:** premature distribution; operational overhead
  conflicts with small reviewable slices and a single-operator workflow.
- **SQLite / MongoDB:** SQLite does not fit a server with multi-device sync;
  MongoDB trades away the relational integrity the domain relies on.
- **GraphQL / tRPC:** added complexity without a current need; tRPC would also
  presume a TypeScript backend.

## Related Specifications

- `docs/architecture/system.md`
- `docs/architecture/domain.md`
- `docs/specs/planning/daily-top-three.md`
- `docs/specs/tasks/task-management.md`
