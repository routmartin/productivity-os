# ADR-007: Package and Module Layout

## Status

Proposed

## Context

The stack is a Spring Boot + Kotlin modular monolith (ADR-002) with
feature modules for users, tasks, projects, goals, focus, daily planning, and
the daily top three. ADR-005 requires thin controllers, application services,
and a domain layer, and ADR-002 requires mechanically enforced module
boundaries. The code had not caught up with that intent: every feature module
was one flat package mixing controllers, services, repositories, entities,
DTOs, exceptions, and security plumbing. The `user` module was the worst case:
29 files mixing authentication flow, JWT/security infrastructure, profile
behavior, and persistence with no internal structure. Entity naming was also
inconsistent (`User` had no `Entity` suffix and no domain mapping, while other
modules had pure domain types plus `*Entity` JPA classes), and the ArchUnit
skeleton had no rules.

## Decision Drivers

- Modular-monolith boundaries must be visible and mechanically enforced.
- Every vertical slice should be structurally identical and reviewable
  (ADR-005).
- Authentication is a cross-cutting concern, not a user-profile concern.
- Avoid package cycles between modules.
- Keep API contracts unchanged; this is a structural refactor.

## Options

### Module packaging

- Option A — feature modules with layer sub-packages
- Option B — top-level layer packages (controller/, service/, ...) with feature
  sub-packages
- Option C — per-use-case vertical slices inside each module
- Option D — hexagonal (domain/application/infrastructure/interfaces)

### Authentication placement

- Option A — dedicated `auth` module
- Option B — keep auth inside `user`
- Option C — split only the security plumbing into `config`

## Decision

1. **Feature modules with layer sub-packages** inside
   `com.productivityos`:
   `controller/`, `service/`, `domain/`, `persistence/`, `dto/`,
   `exception/` (`auth` additionally has `security/`).
2. **A dedicated `auth` module** owns login, registration, refresh tokens,
   JWT/security infrastructure, and the password-change use case. The `user`
   module keeps profile concerns (timezone, user profile, persistence).
3. **JPA entities use the `Entity` suffix** and expose `toDomain()`; pure
   domain data classes hold behavior. Requests/responses live in `dto`;
   module-local exceptions in `exception`; repositories with entities in
   `persistence`.
4. **Shared packages**: `api` (web/error/identity-access cross-cutting) and
   `config` (bean configuration) may be used by any module.
5. **Allowed cross-module dependencies** (everything else is forbidden):
   - `auth` → `user`
   - `focus` → `task`
   - `dailyplan` → `task`, `user`
   - `topthree` → `task`, `project`, `user`
   - `project` → `goal` (consumes goal lifecycle events for cross-module
     cleanup; the goal module itself stays isolated)
   - `task` ↔ `project` (known cycle, frozen in ArchUnit; resolve via events
     in a follow-up)
6. **Enforcement**: real ArchUnit rules in `ArchitectureTest` (module
   isolation, thin controllers, pure domain).

## Reasoning

Layer sub-packages inside feature modules mirror the web app's
`features/*` folders, keep each module self-contained, and make every
vertical slice reviewable without the indirection of hexagonal packaging.
A separate `auth` module removes the biggest flat-package offender and gives
identity a clear ownership boundary. `CurrentUser` lives in the shared `api`
package so both `user` and `auth` can read the security context without a
package cycle. DTOs such as `UserResponse` are allowed to cross the `auth` →
`user` edge.

## Consequences

### Positive

- Predictable structure: any feature's controller/service/domain/persistence
  is discoverable in seconds.
- Module boundaries are compile-time-meaningful and enforced by ArchUnit.
- The `user` module shrinks from 29 flat files to a focused profile module.

### Negative

- Moving files touches many paths in one refactor; review noise is high but
  behavior-neutral.
- The frozen `task` ↔ `project` cycle remains until a follow-up refactor.

## Rejected Alternatives

- **Top-level layer packages:** weakens module cohesion and matches neither
  the domain architecture nor the web app layout.
- **Per-use-case vertical slices:** too many small folders for the current
  codebase size.
- **Hexagonal:** strongest isolation but heavier structure than the current
  scope warrants.
- **Auth inside `user`:** leaves the largest, most confusing module intact.

## Related Specifications and ADRs

- `docs/decisions/ADR-002-technology-stack.md`
- `docs/decisions/ADR-004-authentication-user-isolation.md`
- `docs/decisions/ADR-005-api-architecture.md`
- `docs/architecture/system.md`
- `docs/architecture/domain.md`
