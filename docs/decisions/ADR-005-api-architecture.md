# ADR-005: API Architecture

## Status

Proposed

## Context

The stack is established: Spring Boot + Kotlin backend, Vue 3 + TypeScript
frontend, REST, modular monolith (ADR-002); PostgreSQL persistence with
transactional domain operations (ADR-003); stateless JWT authentication with
security-context-derived identity (ADR-004).

The architecture requires that business behavior lives in domain/application
services rather than UI or transport code (system.md, "domain-first behavior"),
and that AI stays behind an explicit service boundary. The specifications
repeatedly require rejections with "clear feedback" (Daily Top 3 Rules 13–14;
Task Management Rule 8), so the API needs a consistent, structured error model.

This ADR fixes the API conventions so that every vertical slice is built the
same way and remains reviewable.

## Decision Drivers

- Thin transport layer: controllers must not contain domain behavior.
- Uniformity: every module exposes resources the same way (reviewability).
- Contract clarity for the TypeScript frontend (typed, documented, stable).
- Error responses that can carry the specifications' "clear feedback"
  requirement.
- Compatibility with JWT authentication and user scoping from ADR-004.
- Minimal V1 complexity; room to evolve without breaking clients.

## Options

### API style

- Option A — REST over HTTP with JSON
- Option B — GraphQL
- Option C — RPC (tRPC / gRPC)

### Versioning

- Option A — URI prefix (`/api/v1`)
- Option B — Header-based versioning
- Option C — No explicit versioning

### Error format

- Option A — Consistent structured error body for all errors
- Option B — Spring default error responses per exception

### Documentation

- Option A — OpenAPI specification generated from the API
- Option B — Hand-written documentation

## Decision

1. **REST over HTTP** with **JSON** request/response bodies.
2. **URI prefix `/api/v1`** for all endpoints.
3. **Resource-oriented endpoints** using plural nouns (for example
   `/api/v1/tasks`, `/api/v1/projects`, `/api/v1/daily-top-three`); domain
   operations that are not simple CRUD are exposed as explicit sub-resources or
   action endpoints rather than overloaded verbs.
4. **Controllers are thin adapters:** they parse requests, invoke boundary
   validation, call exactly one application service, and map results/errors to
   HTTP. No domain logic in controllers.
5. **Application services** (use cases) contain orchestration and transaction
   boundaries (per ADR-003). The **domain layer** contains business rules and
   invariants (lifecycle transitions, eligibility, ordering).
6. **Consistent structured error responses** for every error, with
   domain/application errors mapped to appropriate HTTP status codes.
7. **Request validation at the API boundary** (format, required fields, value
   shapes); domain invariants are still enforced in the domain layer.
8. **ISO-8601** for all timestamps and dates in API contracts (UTC instants for
   timestamps, per ADR-003; calendar dates where the specification speaks of
   dates).
9. **Pagination** on all potentially large collection endpoints.
10. **OpenAPI documentation** generated from the API and kept current.
11. **No GraphQL or tRPC in V1.**

## Request Flow

1. Authentication filter validates the JWT and populates the security context
   (ADR-004).
2. Controller receives the request, performs boundary validation, and extracts
   parameters. Client-supplied user identifiers are ignored; identity comes
   from the security context.
3. Controller calls one application service (use case).
4. The application service orchestrates: loads aggregates through
   user-scoped repositories, invokes domain rules, and commits one transaction.
5. Domain objects enforce invariants; violations surface as typed
   domain/application errors.
6. The controller maps the result to a response, or the error to the structured
   error model with the appropriate status code.

## Resource and Endpoint Conventions

- Plural resource names; hierarchical paths only where ownership is intrinsic
  (for example, tasks within projects).
- Entity IDs in paths refer to the addressed resource only — never to users
  (ADR-004).
- Lifecycle and domain operations are explicit endpoints rather than generic
  update calls, so invalid transitions can be rejected distinctly (for example,
  a completion or cancellation operation instead of a free-form state field).
- Dates in paths or queries use ISO-8601 calendar dates; timestamps in bodies
  and responses are ISO-8601 UTC instants.
- Responses use a consistent representation per resource; write responses
  return the affected resource representation.

## Error Model

Every error response has one structured body:

- `code` — stable machine-readable identifier (for example
  `TOP3_FULL`, `INVALID_LIFECYCLE_TRANSITION`).
- `message` — human-readable explanation (carries the specifications' "clear
  feedback").
- `details` — optional structured context (for example, field-level validation
  failures).
- `traceId` — correlation identifier for support and log lookup.

Status mapping:

- `400` — malformed or invalid request input (boundary validation).
- `401` — missing or invalid authentication.
- `403` — authenticated but not permitted.
- `404` — resource not found, including cross-user access attempts (existence
  is not disclosed, per ADR-004).
- `409` — domain conflict: invalid lifecycle transition, Top 3 full, duplicate
  selection, optimistic-version conflict.
- `422` — well-formed request violating domain rules that are not conflicts
  (used sparingly; `409` preferred for state conflicts).
- `500` — unexpected server error (generic body; no internals leaked).

## Validation

- Boundary validation (annotations/constraints on request models) checks shape
  and required fields before any service call.
- Domain validation (transitions, eligibility, uniqueness, positions) happens
  only in the domain/application layer and is never duplicated into
  controllers.
- Validation failures return `400` with per-field `details`.

## Pagination

- Collection endpoints that can grow unbounded accept `page` (0-based) and
  `size` (default and maximum capped server-side).
- Responses include the items plus pagination metadata (`page`, `size`,
  `totalElements`, `totalPages`).
- Collections have a documented, stable default sort so pagination is
  deterministic.
- Cursor-based pagination may replace offset pagination later if data volumes
  require it; that is a non-breaking contract change to be decided then.

## Versioning

- The URI prefix `/api/v1` is the compatibility contract.
- Additive, backward-compatible changes (new fields, new endpoints) occur
  within `/api/v1`.
- Breaking changes (removed/renamed fields, changed semantics) require
  `/api/v2`; `/api/v1` remains supported until clients migrate.

## Consequences

### Positive

- Uniform conventions make every vertical slice structurally identical and
  easy to review — aligned with the SDD workflow.
- The structured error model directly implements the specifications' "clear
  feedback" rules and gives the Vue client a stable contract.
- Thin controllers keep domain behavior where the architecture requires it,
  preserving testability without an LLM.
- OpenAPI generation keeps frontend types and documentation in sync with the
  implementation.

### Negative

- Explicit operation endpoints proliferate compared to generic CRUD.
- Maintaining the error-code catalog and OpenAPI accuracy requires ongoing
  discipline.
- Offset pagination is less stable under concurrent writes than cursors;
  accepted for V1 scale.
- Resource-oriented REST may need purpose-built read endpoints for dashboard
  aggregation rather than pure resource shapes.

## Rejected Alternatives

- **GraphQL:** flexible reads, but adds schema/tooling complexity and weakens
  the simple status-code error model; unnecessary for current read shapes.
- **tRPC / gRPC:** tRPC presumes a TypeScript backend; gRPC adds protocol
  machinery without a V1 need.
- **Header-based versioning:** keeps URIs clean but is less visible and harder
  to test/document than a URI prefix.
- **No versioning:** makes future breaking changes needlessly expensive.
- **Spring default error responses:** inconsistent shapes cannot carry stable
  error codes for client feedback.
- **Hand-written API docs:** drifts from the implementation; generated OpenAPI
  stays synchronized.

## Related Specifications and ADRs

- `docs/decisions/ADR-001-sdd-workflow.md`
- `docs/decisions/ADR-002-technology-stack.md`
- `docs/decisions/ADR-003-database-persistence.md`
- `docs/decisions/ADR-004-authentication-user-isolation.md`
- `docs/architecture/system.md`
- `docs/architecture/domain.md`
- `docs/specs/tasks/task-management.md`
- `docs/specs/planning/daily-top-three.md`
