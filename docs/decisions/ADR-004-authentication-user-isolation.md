# ADR-004: Authentication and User Isolation

## Status

Proposed

## Context

The system is multi-user. `docs/architecture/domain.md` establishes that every
user-owned domain object belongs to exactly one User and that users cannot
access another user's private productivity data. Task Management encodes this
as Rules 1, 6, and 7 with acceptance criteria AC-003 and AC-006–008; Daily Top 3
associates every selection with a user and a date (Constraint 2) and requires
multi-device synchronization (Constraint 3).

The stack comes from ADR-002 (Spring Boot + Kotlin backend, Vue 3 + TypeScript
frontend, REST API) and ADR-003 (PostgreSQL, user-scoped foreign keys).

A central security invariant follows from the specifications: **user identity
must be derived from authenticated credentials, never from a client-supplied
userId.** If any request could name the user it acts for, the isolation
acceptance criteria would be unenforceable.

Authentication and authorization are part of the deterministic core: they must
work without any AI component (system.md).

## Decision Drivers

- Enforce user isolation at every layer, as mandated by the specifications.
- Support one user on multiple devices with independent sessions.
- Stateless request authentication suitable for a REST API consumed by a Vue
  single-page application.
- Current best practice for password storage (memory-hard hashing).
- Minimal V1 surface area: no external identity dependencies.
- Full testability of isolation behavior as acceptance criteria.

## Options

### Authentication mechanism

- Option A — Spring Security, password authentication, stateless JWT access
  tokens with server-side rotating refresh tokens
- Option B — Spring Security with stateful server-side sessions (session cookie)
- Option C — External identity provider (Auth0, Keycloak) or social login via
  OAuth2/OIDC

### Token strategy (for Option A)

- Short-lived signed JWT access tokens + opaque rotating refresh tokens
- Long-lived JWT only
- Opaque access tokens validated against the database on every request

### Password hashing

- Option A — Argon2id
- Option B — BCrypt
- Option C — PBKDF2

### Identity propagation

- Option A — Resolve user identity from the authenticated security context on
  every request
- Option B — Accept a userId from request parameters or bodies

### Isolation enforcement

- Option A — Application-service/repository scoping: every query is constrained
  to the authenticated user
- Option B — Controller-level ownership checks only
- Option C — PostgreSQL row-level security

## Decision

1. **Spring Security** provides authentication and authorization.
2. **Stateless, short-lived JWT access tokens** authenticate API requests.
3. **Server-side rotating refresh tokens** provide multi-device sessions: one
   refresh token per device, persisted server-side (hashed), rotated on every
   use, with reuse detection.
4. **Password authentication** (email + password) is the only V1 login method.
5. **Argon2id** is the password hashing algorithm, via Spring Security's
   `Argon2PasswordEncoder`. No Spring-specific blocker exists (the encoder ships
   in `spring-security-crypto` and requires the BouncyCastle dependency), so
   BCrypt is not substituted.
6. **User identity is resolved from the authenticated security context** on
   every request. Client-supplied user identifiers in paths, parameters, or
   bodies are never used to establish identity or ownership.
7. **Every repository/application-service query is scoped to the authenticated
   user.** There is no code path that fetches or mutates domain data without a
   user constraint.
8. **No OAuth/social login in V1.** The identity model (internal User +
   credentials) is designed so OAuth2/OIDC can be added later without changing
   domain isolation.
9. **No anonymous access to protected domain data.** Only authentication
   endpoints and operational health endpoints are public.

## Authentication Flow

- **Registration:** the user provides an email and password; the password is
  hashed with Argon2id (per-user salt) and stored; never logged or returned.
- **Login:** credentials are verified against the stored hash. On success the
  server issues a short-lived JWT access token and a new opaque refresh token
  registered to that device.
- **Authenticated requests:** the client sends `Authorization: Bearer <jwt>`.
  A Spring Security filter validates the signature and expiry and populates the
  security context with the authenticated user. All downstream code reads
  identity exclusively from this context.
- **Refresh:** the client presents its refresh token; the server validates it,
  rotates it (the presented token is invalidated and a new one issued), and
  returns a new access token. Presentation of an already-rotated token is
  treated as token theft: the entire token family for that device is revoked.
- **Logout:** the device's refresh token is revoked. Password change revokes
  all refresh tokens for the user.
- **Frontend storage:** the access token lives in memory; the refresh token is
  transported via an HttpOnly, Secure, SameSite cookie so it is never exposed
  to JavaScript.

## Authorization and User Isolation

- V1 has a single authorization rule: an authenticated user may access exactly
  their own data.
- Isolation is enforced at the application-service/repository layer: every
  query includes the authenticated user from the security context. Controllers
  perform no ownership decisions and trust no client-supplied identifiers.
- Cross-user access attempts are rejected without confirming whether the target
  resource exists, satisfying Task Management AC-006–008.
- User-scoped foreign keys from ADR-003 remain the database-level backstop;
  authorization does not rely on them as the primary mechanism.
- AI-facing read access (future) will pass through the same user-scoped
  services, preserving this isolation.

## Token Strategy

- **Access tokens:** signed JWTs with a short lifetime (minutes). They carry
  the user identity and no sensitive claims. Access tokens are not revoked;
  their short TTL bounds exposure.
- **Refresh tokens:** opaque, cryptographically random strings; only their
  hashes are persisted (ADR-003 database). Each is bound to one device session,
  rotated on every use, and subject to reuse detection with family revocation.
- **Multi-device:** each device holds an independent refresh token, so one
  device can be revoked without affecting others — matching the multi-device
  synchronization requirement in Daily Top 3 Constraint 3.
- **Signing keys:** server-side only, injected via environment, rotatable
  without client changes.

## Password Security

- Argon2id hashing with per-user salts via `Argon2PasswordEncoder`
  (BouncyCastle dependency), with parameters tuned to current OWASP guidance
  and revisited periodically.
- Login and registration endpoints are rate-limited to slow credential attacks
  (V1: application-level limiting; no additional infrastructure per ADR-003).
- Authentication failures return generic responses that do not reveal whether
  an email is registered. (The specifications' "clear feedback" rules apply to
  domain operations, not to authentication failures.)
- Password verification uses constant-time comparison as provided by the
  encoder.

## Consequences

### Positive

- Stateless access-token validation keeps request handling simple and scalable.
- Independent per-device refresh sessions make multi-device use and revocation
  clean and testable.
- Isolation is enforced next to the data, not at controller discretion, making
  the Task Management isolation acceptance criteria directly testable.
- No external identity dependency in V1; full deterministic test coverage is
  possible without mocks of third-party services.

### Negative

- Access tokens cannot be revoked instantly; exposure is bounded only by the
  short TTL.
- Refresh-token persistence and rotation add a table, hashing, and
  reuse-detection logic.
- Argon2id introduces the BouncyCastle dependency.
- The frontend must implement silent token refresh, adding client complexity.
- Application-level rate limiting is weaker than dedicated infrastructure;
  acceptable for V1, revisit if abuse appears.

## Security Considerations

- HTTPS is required everywhere; refresh tokens travel only via Secure, HttpOnly,
  SameSite cookies.
- Client-supplied user identifiers are ignored by design; any code path that
  used one would be a defect against this ADR and the specifications.
- Tokens and passwords are never written to logs or error responses.
- JWT signing keys are environment-injected and rotatable; key rotation must
  not invalidate persisted data.
- Refresh-token reuse is treated as compromise and revokes the device family.
- Adding OAuth2/OIDC later must not bypass user-scoped services; external
  identities map to internal users before any domain access.

## Rejected Alternatives

- **Stateful server-side sessions:** simpler revocation, but per-request session
  storage and cookie coupling to the browser fit the stateless REST + multi-
  device target less well than JWT + refresh rotation.
- **External IdP / social login (OAuth2/OIDC):** removes password handling but
  adds an external dependency and configuration burden disproportionate to V1;
  the identity model leaves room to add it later.
- **Long-lived JWT only or DB-validated opaque access tokens:** the former
  worsens token-theft exposure; the latter reintroduces per-request database
  lookups without a V1 need.
- **BCrypt / PBKDF2:** acceptable fallbacks, but Argon2id is the current
  memory-hard best practice and Spring Security supports it directly.
- **Client-supplied userId for scoping:** categorically rejected — it would
  void the isolation invariant and its acceptance criteria.
- **PostgreSQL row-level security:** a strong backstop, but it couples
  authentication to database roles and complicates JPA usage; application-layer
  scoping plus foreign-key backstops is sufficient for V1.

## Related Specifications and ADRs

- `docs/decisions/ADR-001-sdd-workflow.md`
- `docs/decisions/ADR-002-technology-stack.md`
- `docs/decisions/ADR-003-database-persistence.md`
- `docs/architecture/system.md`
- `docs/architecture/domain.md`
- `docs/specs/tasks/task-management.md` (Rules 1, 6, 7; AC-003, AC-006–008)
- `docs/specs/planning/daily-top-three.md` (Constraints 2–3)
