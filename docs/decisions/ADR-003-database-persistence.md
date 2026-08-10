# ADR-003: Database and Persistence Architecture

## Status

Proposed

## Context

ADR-002 (technology stack) selected Spring Boot + Kotlin, PostgreSQL, a modular
monolith, and REST. This ADR defines how domain data is persisted within that
stack.

The approved specifications impose concrete persistence requirements:

- Durable, user-scoped data with strict isolation between users (Task Management
  Constraints 1–2).
- Soft deletion with restore and preserved history (Task Management Rules
  15–18); permanent deletion is out of scope.
- Completion timestamps recorded as absolute instants, with calendar-day
  attribution in the user's configured timezone (Task Management Constraint 3;
  Daily Top 3 Constraint 1).
- An ordered Top 3 per user and date with positions 1–3, uniqueness per date,
  and transactional shift-up on removal or deletion (Daily Top 3 Rules 1–4,
  8, 10).
- Historical views frozen at the end of each calendar day (Daily Top 3 Rule 15).
- Multi-device synchronization resolved by last-write-wins based on server
  receipt time (Daily Top 3 Constraint 3, Known Limitations).
- Deterministic domain behavior testable without an LLM; business behavior lives
  in domain/application services, not scattered across layers (system.md).

## Decision Drivers

- Data integrity for specification invariants (lifecycle states, ownership,
  Top 3 uniqueness and ordering).
- Correct time handling across timezones and historical boundaries.
- Simple, reviewable schema evolution in an SDD workflow.
- Transactional consistency for multi-step operations (shift-up, delete/restore).
- Minimal operational footprint for V1; no premature scale-out machinery.

## Options

### Persistence layer

- Option A — Spring Data JPA / Hibernate
- Option B — jOOQ or Kotlin Exposed (SQL-centric)
- Option C — Raw JDBC / MyBatis

### Schema migrations

- Option A — Flyway
- Option B — Liquibase
- Option C — Hibernate `ddl-auto` schema generation

### Identifiers

- Option A — UUID primary keys
- Option B — BIGSERIAL / identity columns
- Option C — Composite natural keys

### Timestamps

- Option A — `timestamptz`, storing UTC instants; user timezone applied at the
  domain layer
- Option B — `timestamp` without timezone, storing user-local time
- Option C — Store both instant and precomputed calendar date

### Deletion

- Option A — Soft delete (deleted marker plus timestamp) where required by
  specifications
- Option B — Hard delete with audit tables
- Option C — Event sourcing as the history mechanism

### Concurrency control

- Option A — Optimistic concurrency (version columns) where required
- Option B — Pessimistic locking
- Option C — No concurrency control

### Additional infrastructure

- Option A — None for V1 (no Redis, MongoDB, CQRS, event sourcing, sharding, or
  read replicas)
- Option B — Introduce caching / read replicas / event-driven projections now

## Decision

1. **PostgreSQL** is the single system of record for all domain data.
2. **Spring Data JPA / Hibernate** is the persistence layer, accessed through
   repositories from application services. Domain behavior remains in
   domain/application services, consistent with the domain-first principle.
3. **Flyway** manages all schema changes via versioned migrations.
4. **UUID** identifiers for all domain entities.
5. **`timestamptz` / UTC instants** for every persisted timestamp. The user's
   configured timezone is applied at the domain/application layer to interpret
   calendar days (00:00:00–23:59:59); user-local times are never persisted as
   bare timestamps.
6. **Soft deletion** (deleted marker plus deletion timestamp) wherever
   specifications require history preservation or restore — tasks per Task
   Management Rules 15–18, and Top 3 historical selections per Daily Top 3
   Rule 10.
7. **Transactional domain operations:** each specification-level operation
   (state transition, Top 3 select/remove with shift-up, delete, restore)
   executes as a single database transaction.
8. **Optimistic concurrency** via version columns on aggregates that accept
   multi-device writes (initially: Task, Top 3 selections).
9. **V1 exclusions:** no Redis, MongoDB, CQRS, event sourcing, sharding, or read
   replicas.

## Reasoning

- The specifications are relational in nature: ownership foreign keys, a unique
  ordered triple (user, date, position), and lifecycle states map naturally to
  constraints and transactions rather than to documents or events.
- JPA/Hibernate is the path of least resistance in Spring Boot and sufficient
  for the current query shapes; repositories keep persistence behind the
  application-service boundary required by system.md.
- Flyway gives deterministic, reviewable, diff-able schema history — a good fit
  for spec-driven change control.
- UUIDs avoid leaking sequence information, simplify client-generated
  identifiers for offline-capable sync, and remove sequence contention.
- UTC instants plus a domain-layer timezone rule are the only reliable way to
  honor "calendar day in the user's configured timezone" while keeping stored
  data absolute and comparable, and while supporting frozen end-of-day history
  even if the user later changes timezone (Daily Top 3 Constraint 1).
- Soft delete is mandated by the specifications, not optional: restore semantics
  and historical views depend on it.

## Consequences

### Positive

- Database constraints act as a backstop for specification invariants, beneath
  domain-layer enforcement.
- One database, one migration tool, one persistence framework: small surface
  area for review and for the SDD experiment's traceability goals.
- Soft delete and UTC instants make historical views and restore behavior
  straightforward to implement and test.
- No additional infrastructure to operate in V1.

### Negative

- JPA/Hibernate mapping complexity and lazy-loading pitfalls require team
  discipline and review attention.
- Soft delete requires consistent filtering in every query of active data;
  unique constraints must be soft-delete-aware (partial indexes) — a data-model
  concern to be handled in the implementation plan.
- UUID primary keys are larger and less index-local than sequential IDs;
  acceptable at V1 scale.
- Optimistic versioning interacts with last-write-wins semantics (see
  Concurrency Implications).
- Introducing caching, replicas, or projections later requires a new ADR
  superseding parts of this one.

## Data Integrity and Invariant Enforcement

- The domain layer is the primary enforcer of behavior (lifecycle transitions,
  eligibility rules); the database provides backstop constraints:
  - Foreign keys enforcing that every entity belongs to exactly one user and
    tasks reference at most one same-user project.
  - NOT NULL constraints on required fields (title, lifecycle state).
  - CHECK constraints for the lifecycle state set and Top 3 positions 1–3.
  - A uniqueness constraint on Top 3 (user, date, position) for active
    selections, implemented soft-delete-aware so historical records do not
    collide with active ones.
- Multi-step invariants (Top 3 shift-up on removal/deletion, slot occupancy by
  completed tasks, delete/restore) execute within single transactions.
- Invariant tests run against real PostgreSQL via Testcontainers, mapped to the
  specifications' acceptance criteria for traceability.

## Migration Strategy

- All schema changes are Flyway versioned migrations (`V<version>__<name>.sql`),
  applied forward-only; rollbacks are handled by new compensating migrations.
- Hibernate `ddl-auto` is disabled for schema creation (`validate` at most);
  the schema of record is the migration set.
- Migrations run automatically at application startup and are exercised in CI
  against Testcontainers PostgreSQL.
- Destructive schema changes require a corresponding specification change first,
  preserving specification traceability.

## Concurrency Implications

- Last-write-wins per Daily Top 3 Constraint 3 is implemented by server-assigned
  receipt timestamps: the write most recently received by the server wins.
- Optimistic version columns protect API-level concurrent updates from silent
  lost updates. Interplay to be resolved in the implementation plan: a version
  conflict rejects the stale write, so converging to last-write-wins requires
  the client to re-read and retry; this must not silently violate the
  specification's LWW promise.
- Default READ COMMITTED isolation is sufficient; critical multi-step operations
  rely on transactions plus the uniqueness backstop rather than pessimistic
  locks.
- Single-user, multi-device scope means no cross-user concurrency concerns;
  cross-user access is rejected before any data access.

## Rejected Alternatives

- **jOOQ / Exposed / raw JDBC / MyBatis:** more control, but more mapping
  boilerplate and slower iteration than JPA for the current query shapes.
- **Liquibase:** capable, but Flyway's plain-SQL versioned migrations are
  simpler to review in an SDD workflow.
- **Hibernate `ddl-auto`:** unsafe, non-reviewable schema drift; incompatible
  with specification traceability.
- **BIGSERIAL identifiers:** simpler and smaller, but leak ordering, complicate
  client-generated IDs for sync, and were traded away deliberately.
- **User-local `timestamp`:** corrupts under timezone changes and travel;
  violates the calendar-day constraints.
- **Hard delete with audit tables / event sourcing:** contradicts the approved
  soft-delete semantics; event sourcing is disproportionate for V1.
- **Pessimistic locking:** unnecessary contention for a single-user,
  multi-device product.
- **Redis / MongoDB / CQRS / sharding / read replicas:** premature for V1 scale
  and reviewability goals.

## Related Specifications and ADRs

- `docs/decisions/ADR-001-sdd-workflow.md`
- `docs/decisions/ADR-002-technology-stack.md`
- `docs/architecture/system.md`
- `docs/architecture/domain.md`
- `docs/specs/tasks/task-management.md`
- `docs/specs/planning/daily-top-three.md`
