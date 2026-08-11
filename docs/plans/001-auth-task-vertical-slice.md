# Plan: Authentication + Basic Task Management (Vertical Slice 1)

## Status

Proposed — plan only. No implementation has been approved or started.

## Specification

Primary behavioral source of truth:

- `docs/specs/tasks/task-management.md` (Draft)

Acceptance criteria in scope for this slice:

- AC-001 create minimal task (Inbox state, no project, owned)
- AC-002 create with optional attributes (partially — see Deferrals)
- AC-003 tasks always have an owner
- AC-007 / AC-008 cross-user view/modify rejected
- AC-009 Inbox → Planned, AC-010 Planned → In Progress (see Gap G1)
- AC-011 In Progress → Completed, AC-012 completion time recorded
- AC-017 Completed is final
- AC-018 / AC-019 invalid transitions rejected
- AC-021 active-state definition
- AC-024 persistence across sessions
- AC-025–AC-030 soft delete, history preservation, restore, deleted-task
  exclusions

Explicitly not in this slice: projects (AC-004–006), cancellation and reopening
(AC-013–016, AC-020), AI constraints (AC-022–023), Daily Top 3.

**Gap G0 — no User/Auth specification exists.** Registration, login, profile,
and timezone-capture behavior are defined only by ADR-004 and ADR-006, not by a
product specification. See Pre-Implementation Decisions, D1.

## Architecture

- ADR-002 stack: Spring Boot + Kotlin modular monolith, Vue 3 + TS (frontend
  not in this slice), PostgreSQL, REST.
- ADR-003 persistence: JPA/Hibernate, Flyway, UUID IDs, `timestamptz`, soft
  delete, optimistic versioning, one transaction per use case.
- ADR-004 auth: Spring Security, JWT access tokens, rotating refresh tokens,
  Argon2id, security-context identity, user-scoped queries.
- ADR-005 API: `/api/v1`, thin controllers, structured errors, ISO-8601,
  pagination.
- ADR-006 time: server clock via injectable `Clock`, `Instant`/`LocalDate`,
  user IANA timezone.

Modules introduced: `user` (identity, credentials, profile), `task` (task
aggregate and lifecycle). Cross-module references by ID only.

## Step 1 — Project/bootstrap setup

- Files/modules: `settings.gradle.kts`, `build.gradle.kts`, `apps/api/` (Spring
  Boot application), `docker-compose.yml` (PostgreSQL), Gradle wrapper,
  `.gitignore` updates, ArchUnit test skeleton for module boundaries.
- Spec/AC: none (ADR-002).
- Dependencies: none.
- DB changes: none (empty Flyway baseline).
- API changes: `GET /api/v1/health` (public).
- Tests: application context loads; ArchUnit boundary rules pass on empty
  modules.
- Risks/ambiguities: monorepo layout convention (`apps/api`, future
  `apps/web`, `packages/*`) is not yet decided — see D7.

## Step 2 — PostgreSQL + Flyway

- Files/modules: `docker-compose.yml`, `application.yml`, `db/migration/`
  directory, Flyway configuration (`ddl-auto=validate`).
- Spec/AC: none (ADR-003).
- Dependencies: Step 1.
- DB changes: `V1__baseline.sql` (extensions if needed, e.g. pgcrypto).
- API changes: none.
- Tests: Testcontainers PostgreSQL boots; migrations apply cleanly.
- Risks/ambiguities: none significant.

## Step 3 — User persistence

- Files/modules: `user` module — `User` entity, `UserRepository`,
  `refresh_tokens` persistence, user profile fields.
- Spec/AC: enables TM AC-003; identity model per ADR-004.
- Dependencies: Steps 1–2.
- DB changes: `V2__users.sql` — `users` (id UUID PK, email UNIQUE
  case-insensitive, password_hash, timezone IANA id, created_at timestamptz,
  version); `refresh_tokens` (id UUID PK, user_id FK, token_hash, device label,
  created_at, expires_at, rotated_from, revoked_at).
- API changes: none.
- Tests: repository round-trip; email uniqueness constraint.
- Risks/ambiguities: timezone capture/default at registration is unspecified —
  see D8.

## Step 4 — Password hashing

- Files/modules: `user` module — password encoder bean (Argon2id via
  `Argon2PasswordEncoder`, BouncyCastle dependency).
- Spec/AC: ADR-004 (password security section).
- Dependencies: Step 1.
- DB changes: none.
- API changes: none.
- Tests: hash/verify round-trip; encoded hash carries algorithm parameters;
  constant-time verification path.
- Risks/ambiguities: exact Argon2 parameters need an OWASP-aligned choice
  (implementation detail, not product behavior).

## Step 5 — Registration

- Files/modules: `user` module — `AuthController`, `RegistrationService`,
  request/response models.
- Spec/AC: none (Gap G0 — no user spec); behavior per ADR-004 flow.
- Dependencies: Steps 3–4.
- DB changes: none (uses Step 3 schema).
- API changes: `POST /api/v1/auth/register` → `201` with user representation
  (id, email, timezone); no token issuance at registration unless decided
  (see D2).
- Tests: successful registration; duplicate email rejected; invalid email and
  weak password → `400` with structured error (ADR-005).
- Risks/ambiguities: duplicate-email response policy — generic vs specific
  `409 EMAIL_TAKEN` (D3); password policy undefined (D4).

## Step 6 — Login

- Files/modules: `user` module — `LoginService`, credential verification.
- Spec/AC: none (Gap G0); ADR-004 flow.
- Dependencies: Steps 3–5.
- DB changes: none.
- API changes: `POST /api/v1/auth/login` → `200` with access token and refresh
  cookie (HttpOnly, Secure, SameSite=Strict); generic `401` on failure.
- Tests: valid login issues both tokens; wrong password and unknown email
  return identical generic `401`; application-level rate limiting triggers.
- Risks/ambiguities: rate-limit parameters are an operational choice.

## Step 7 — JWT access token

- Files/modules: `user` module — JWT issuer/validator (signing key from
  environment), security filter wiring, token claims (`sub` = user UUID,
  `exp`, `iss`).
- Spec/AC: ADR-004 token strategy.
- Dependencies: Step 6.
- DB changes: none.
- API changes: all protected endpoints now require `Authorization: Bearer`.
- Tests: expired token → `401`; tampered signature → `401`; valid token
  populates the security context.
- Risks/ambiguities: key rotation strategy is documented but not exercised in
  V1.

## Step 8 — Refresh token

- Files/modules: `user` module — `RefreshTokenService` (issue, rotate, revoke,
  reuse detection with family revocation).
- Spec/AC: ADR-004 token strategy.
- Dependencies: Steps 3, 6–7.
- DB changes: none (uses Step 3 schema).
- API changes: `POST /api/v1/auth/refresh` (cookie) → new token pair;
  `POST /api/v1/auth/logout` → revoke device token.
- Tests: rotation invalidates the presented token; reuse of a rotated token
  revokes the family; logout blocks further refresh; expiry enforced.
- Risks/ambiguities: clock skew handling on expiry checks (small tolerance is
  standard practice).

## Step 9 — Spring Security authentication wiring

- Files/modules: `SecurityConfig` (stateless filter chain), current-user
  accessor for application services.
- Spec/AC: ADR-004; enforces TM Rules 1, 6, 7 at the boundary.
- Dependencies: Steps 7–8.
- DB changes: none.
- API changes: `401` for unauthenticated access to any protected endpoint;
  `/api/v1/auth/**` and health remain public.
- Tests: unauthenticated request → `401`; authenticated request reaches the
  service layer with the correct user identity; client-supplied user
  identifiers are ignored (ADR-004 invariant).
- Risks/ambiguities: none significant.

## Step 10 — Task domain model

- Files/modules: `task` module — `Task` aggregate (id, ownerId, title,
  optional fields per Deferrals, lifecycle state, completedAt, deletedAt,
  timestamps, version), lifecycle transition guard implementing the allowed
  transition set with terminal Completed.
- Spec/AC: TM Rules 1–5, 8–13, 15–19.
- Dependencies: Step 1.
- DB changes: none (pure domain).
- API changes: none.
- Tests: unit tests for every allowed transition (AC-009–011, AC-016) and
  every rejected one (AC-017–019, AC-030); Completed terminal; transition
  guard exhaustive.
- Risks/ambiguities: none — the lifecycle is fully specified.

## Step 11 — Task persistence

- Files/modules: `task` module — `TaskEntity`, `TaskRepository` with
  soft-delete-aware queries, optimistic `version`.
- Spec/AC: TM AC-024; ADR-003.
- Dependencies: Steps 2–3, 10.
- DB changes: `V3__tasks.sql` — `tasks` (id UUID PK, user_id FK NOT NULL,
  title NOT NULL, description, due_date, lifecycle_state CHECK constraint,
  completed_at, deleted_at, created_at, updated_at, version).
- API changes: none.
- Tests: persistence round-trip; user FK enforcement; CHECK constraint on
  state set; version increments.
- Risks/ambiguities: deferred attribute columns — see D5.

## Step 12 — Create Task

- Files/modules: `task` module — `TaskController`, `CreateTaskService`,
  request/response models.
- Spec/AC: AC-001, AC-002 (partial), AC-003.
- Dependencies: Steps 9–11.
- DB changes: none.
- API changes: `POST /api/v1/tasks` `{title, description?, dueDate?}` → `201`
  with task representation (state `INBOX`).
- Tests: minimal create (title only) → Inbox state, owned by caller; optional
  fields stored; missing/blank title → `400`; response contains ISO-8601
  fields (ADR-005/006).
- Risks/ambiguities: V1 create does not include priority, energy level, or
  estimated duration (open spec questions) — see D5; tasks are always Inbox
  tasks in this slice (no projects module).

## Step 13 — List current user's Tasks

- Files/modules: `task` module — `ListTasksService`, paginated query.
- Spec/AC: AC-021, AC-025, AC-029; isolation AC-007; pagination per ADR-005.
- Dependencies: Step 12.
- DB changes: none (index on `(user_id, deleted_at)` advisable).
- API changes: `GET /api/v1/tasks?page=&size=` → paginated envelope.
- Tests: returns only caller's tasks; excludes deleted (AC-025/029); excludes
  Completed/Cancelled from the active default (AC-021 — see D6); pagination
  metadata correct; user B sees none of user A's tasks.
- Risks/ambiguities: whether the default list is active-only or all
  non-deleted — see D6.

## Step 14 — Complete Task

- Files/modules: `task` module — `CompleteTaskService`, operation endpoint.
- Spec/AC: AC-011, AC-012, AC-017; depends on AC-009/AC-010 (Gap G1).
- Dependencies: Step 12, plus the two transition endpoints from D1/G1.
- DB changes: none.
- API changes: `POST /api/v1/tasks/{id}/completion` → `200` with task
  (state `COMPLETED`, `completedAt` set from server clock);
  `POST /api/v1/tasks/{id}/plan` and `POST /api/v1/tasks/{id}/start` if G1 is
  resolved by adding them.
- Tests: In Progress → Completed with recorded completion instant; completing
  from Inbox/Planned → `409` (AC-018); re-completing → `409` (AC-017);
  completion timestamp uses the injected clock (ADR-006).
- Risks/ambiguities: **G1 — the slice as scoped cannot reach In Progress.**
  New tasks start in Inbox; only In Progress → Completed is allowed. The
  transition endpoints (AC-009/AC-010) must be added or Complete cannot be
  exercised end-to-end. See D1.

## Step 15 — Soft-delete Task

- Files/modules: `task` module — `DeleteTaskService`, delete endpoint.
- Spec/AC: AC-025, AC-026, AC-029, AC-030; Rule 15.
- Dependencies: Step 12.
- DB changes: none (uses `deleted_at`).
- API changes: `DELETE /api/v1/tasks/{id}` → `204`; subsequent reads of the
  task → `404` (hidden from active work).
- Tests: deleted task absent from list (AC-025/029); record retained with
  `deleted_at` set (AC-026); any transition on a deleted task → `409`
  (AC-030); deleting another user's task → `404`.
- Risks/ambiguities: none — soft delete is fully specified.

## Step 16 — Restore Task

- Files/modules: `task` module — `RestoreTaskService`, restore endpoint.
- Spec/AC: AC-027, AC-028; Rules 16–17.
- Dependencies: Step 15.
- DB changes: none.
- API changes: `POST /api/v1/tasks/{id}/restoration` → `200` with task
  restored to its pre-deletion lifecycle state.
- Tests: restore returns exact previous state (AC-027); deleted Completed task
  restores as Completed with unchanged completion timestamp (AC-028);
  restoring a non-deleted task → `409` or `404` (decide mapping — see D9).
- Risks/ambiguities: none significant.

## Step 17 — REST error model

- Files/modules: shared API infrastructure — `@ControllerAdvice` error
  handler, error body model (`code`, `message`, `details`, `traceId`),
  trace-id MDC filter.
- Spec/AC: ADR-005 error model; implements "clear feedback" requirements
  (TM Rule 8).
- Dependencies: Steps 5–16 (retrofitted uniformly).
- DB changes: none.
- API changes: all errors return the structured body; mapping per ADR-005
  (400/401/403/404/409/422/500).
- Tests: representative error per status class returns the exact structured
  shape; domain conflicts map to `409`; cross-user access maps to `404`.
- Risks/ambiguities: error-code catalog needs to be seeded (implementation
  detail, not product behavior).

## Step 18 — Basic integration tests

- Files/modules: `apps/api/src/test/` — `@SpringBootTest` suite with
  Testcontainers PostgreSQL, injectable `Clock` fixed per test (ADR-006).
- Spec/AC: the full in-scope AC set (see Specification section).
- Dependencies: all previous steps.
- DB changes: none.
- API changes: none.
- Tests: HTTP-level end-to-end: register → login → refresh → create → list →
  plan → start → complete → delete → restore; isolation (user B gets `404`
  for user A's task); invalid transitions → `409`; deleted hidden; restore
  semantics; session persistence (AC-024).
- Risks/ambiguities: test runtime with Testcontainers; acceptable.

## Tests

Traceability matrix: every in-scope AC maps to at least one automated test:

- AC-001/002/003 → create-task integration tests (Step 12)
- AC-007/008 → cross-user isolation tests (Steps 13–16)
- AC-009/010/011/012/017/018/019 → transition tests (Steps 10, 14)
- AC-021/025/029 → list-filtering tests (Step 13)
- AC-024 → persistence/reload test (Step 18)
- AC-026/027/028/030 → delete/restore tests (Steps 15–16)
- ADR-004 flows → auth integration tests (Steps 5–9)

## Verification

Before reporting completion (per AGENTS.md):

1. All in-scope acceptance criteria pass as automated tests.
2. Static analysis/build passes; ArchUnit module boundaries verified.
3. No unrelated changes introduced (diff review).
4. Completion report includes: summary, specification references, files
   changed, AC pass/fail evidence, deviations, risks, follow-ups.

## Pre-Implementation Decisions (must be resolved first)

- **D1 / Gap G1 (blocking):** the slice includes Complete Task but not the
  transitions that reach In Progress. Add `plan` (AC-009) and `start`
  (AC-010) endpoints to the slice — recommended — or Complete is untestable.
- **D2 / Gap G0 (blocking):** no User/Auth specification exists. Either write
  a minimal user-management specification (registration, login, profile,
  timezone) or explicitly approve ADR-004/006 plus this plan as the
  behavioral definition for V1 auth.
- **D3:** duplicate-email registration response — specific `409 EMAIL_TAKEN`
  vs generic response (ADR-004 favors non-disclosure for auth failures).
- **D4:** password policy (minimum length, strength rules) is undefined.
- **D5:** priority, energy level, and estimated-duration value domains are
  open questions in the Task specification — excluded from this slice.
  Confirm exclusion or decide values.
- **D6:** "List current user's Tasks" semantics — active-only per AC-021
  (recommended) vs all non-deleted; also pagination defaults/max.
- **D7:** monorepo layout convention (`apps/api`, `apps/web`, `packages/*`)
  is not yet decided.
- **D8:** timezone capture at registration — client-supplied, or default
  (e.g., UTC) with later profile editing (no profile spec exists).
- **D9:** restore-on-non-deleted-task error mapping (`404` vs `409`).
- **D10:** Task Management is still **Draft**, and ADR-003/004/005/006 are
  still **Proposed**. Implementation against them requires at least Proposed
  specification status and Accepted ADRs (or explicit human approval to
  proceed otherwise).

## Out of Scope for This Slice

- Projects module and task-project membership (AC-004–006).
- Cancellation and reopening of cancelled tasks (AC-013–016, AC-020).
- AI rules (AC-022–023) and any AI integration.
- Daily Top 3 and Daily Planning.
- Frontend application (Vue client) — API only in this slice.
- Priority, energy level, estimated-duration attributes (D5).

## Change History

- Initial plan created against Task Management (Draft), Daily Top 3
  (Proposed), and ADR-001–006.
