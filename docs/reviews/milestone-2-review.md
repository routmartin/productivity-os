# Milestone 2 Review — Auth/User Vertical Slice (Plan 001 Steps 3–6)

**Date:** 2026-08-11
**Scope:** Plan 001, Steps 3–6 (User persistence, password hashing, registration, login)
**Mode:** Static review only — no build/test runs (plan-mode constraints; known Docker/Testcontainers issues are out of scope per the review request).

## Source of truth consulted

- `AGENTS.md`
- `docs/architecture/system.md`
- `docs/architecture/domain.md`
- `docs/decisions/ADR-002-technology-stack.md`
- `docs/decisions/ADR-003-database-persistence.md`
- `docs/decisions/ADR-004-authentication-user-isolation.md`
- `docs/decisions/ADR-005-api-architecture.md`
- `docs/decisions/ADR-006-time-and-timezone.md`
- `docs/specs/users/user-management.md`
- `docs/plans/001-auth-task-vertical-slice.md`
- Actual implementation source, migrations, config, build files, and tests under `apps/api/`.

A note on scope: the repository does not use the term "Milestone 2"; from the focus areas
and "Plan 001 Steps 3–6," this review treats **Milestone 2 = Plan 001 Steps 3–6**
(User persistence, password hashing, registration, login). Steps 7–9 (JWT auth filter,
refresh rotation/logout, Spring Security wiring/rate limiting) are explicitly later steps,
so their absence is treated as "deferred / out of scope," not as defects — except where
the Step 6 login already touches refresh-token issuance/hashing, which is reviewed.

One security-critical claim was verified directly from Spring Security's source
(`Argon2PasswordEncoder` uses `Argon2Parameters.ARGON2_id` with constant-time comparison),
so the Argon2id choice is confirmed correct.

---

## Scope alignment

- Implemented: `User`/`RefreshToken` entities + repositories, `V2__users.sql`, Argon2id
  encoder, `AuthController` (`/register`, `/login`), `RegistrationService`, `LoginService`,
  `TokenService`, `AuthExceptionHandler`, request/response models, `HealthController`,
  ArchUnit skeleton, context-load test.
- Not yet present (expected — Steps 7–9): JWT auth filter / `SecurityConfig`, refresh
  endpoint + rotation/reuse-detection, logout, rate limiting, current-user accessor,
  generated OpenAPI, shared error model infra (Step 17).

---

## 🔴 CRITICAL

### C1 — `RefreshToken` is built with a nullable `UUID?` where a non-null `UUID` is required (compile-blocking / null-safety defect)

**File:** `apps/api/src/main/kotlin/com/productivityos/user/LoginService.kt:39-44`

```kotlin
val persisted = RefreshToken(
    userId = user.id,        // user.id is UUID? (User.kt:17), RefreshToken.userId is UUID (RefreshToken.kt:20)
    ...
```

`User.id` is declared `val id: UUID? = null` (`User.kt:17`). `RefreshToken.userId` is
non-null `UUID` (`RefreshToken.kt:20`). Passing `UUID?` to a non-null parameter is a
Kotlin compile error ("Type mismatch: inferred type is UUID? but UUID was expected").
Note the inconsistency: line 35 uses `user.id!!` for the access token, but line 40 omits
`!!`. This means the milestone as committed should not compile. (Static analysis — no
build was run per plan-mode constraints, but the mismatch is unambiguous.)

**Recommended fix:** `userId = user.id!!` (short term). Better long term: make `User.id`
non-null after persistence (e.g., a persisted-entity type or an internal factory) so `!!`
disappears entirely.

---

## 🟠 HIGH

### H1 — Login has a timing side-channel that reveals whether an email is registered

**Files:** `LoginService.kt:28-33`

```kotlin
val user = userRepository.findByEmailIgnoreCase(request.email)
    ?: throw AuthenticationException("invalid_credentials")
if (!passwordEncoder.matches(request.password, user.passwordHash)) {
    throw AuthenticationException("invalid_credentials")
}
```

When the email is unknown, `passwordEncoder.matches(...)` is never called, so the response
returns in milliseconds. When the email exists but the password is wrong, Argon2id runs
(memory-hard, ~tens to hundreds of ms). The response bodies are identical (good), but the
**timing difference** discloses registration status. This directly violates:

- User Management spec, Behavior: *"Failed logins receive a generic error that does not
  reveal whether the email is registered."*
- ADR-004, Security Considerations: *"Authentication failures return generic responses
  that do not reveal whether an email is registered."*
- Plan 001 Step 6 test: *"wrong password and unknown email return identical generic 401."*

**Recommended fix:** When the user is not found, run a dummy
`passwordEncoder.matches(request.password, <precomputed-argon2id-hash>)` against a
constant throwaway hash to equalize timing, then throw the same `AuthenticationException`.

### H2 — Invalid timezone at registration surfaces as `500`, not a structured `400` (AC-013 broken)

**Files:** `RegistrationService.kt:20-23`; `AuthExceptionHandler.kt` (no handler)

```kotlin
val timezone = request.timezone?.let { zone ->
    ZoneId.of(zone)   // throws ZoneRulesException / DateTimeException for unknown IDs
    zone
} ?: "UTC"
```

`ZoneId.of(...)` throws `java.time.zone.ZoneRulesException` (a `DateTimeException`) for
unknown identifiers. `AuthExceptionHandler` only handles `AuthenticationException` and
`IllegalArgumentException`, so this propagates to Spring's default handler → **HTTP 500**.
AC-013 requires an invalid identifier to be **rejected** (a 4xx), and ADR-005 requires a
structured error body. A 500 for a client-supplied bad value is a defect.

**Recommended fix:** Add an `@ExceptionHandler(DateTimeException::class)` (or a narrower
`ZoneRulesException`) in `AuthExceptionHandler` returning `400` with
`code = "INVALID_TIMEZONE"`. Optionally validate at the boundary in `RegisterRequest`
with a custom IANA validator.

### H3 — Bean-validation failures (`@Valid`) are not mapped to the ADR-005 structured error model

**Files:** `AuthExceptionHandler.kt` (no `MethodArgumentNotValidException`/
`ConstraintViolationException` handlers); `AuthController.kt:20,33` use `@Valid`.

Plan 001 Step 5 explicitly requires: *"invalid email and weak password → 400 with
structured error (ADR-005),"* and ADR-005 mandates a consistent body (`code`, `message`,
`details`, `traceId`) with *"Validation failures return 400 with per-field details."*
Currently a blank email or a <12-char password throws `MethodArgumentNotValidException`,
which has no handler and falls through to Spring Boot's default `ProblemDetail` body — a
400 in status, but **not** the project's structured error contract (no stable `code`, no
per-field `details`, no `traceId`).

**Recommended fix:** Add a `@ExceptionHandler(MethodArgumentNotValidException::class)`
that returns `400` with `{code:"VALIDATION_ERROR", message, details:[{field,message}]}`.
(The full shared model/trace-id filter is Step 17, but the Step 5 minimum — a conforming
400 with `code`/`message`/`details` — should exist now.)

### H4 — Duplicate-email under concurrency returns `500` (DB constraint exception is unmapped)

**Files:** `RegistrationService.kt:16-18` (check-then-act); `V2__users.sql:13` (unique
index is the real backstop); `AuthExceptionHandler.kt` (no
`DataIntegrityViolationException` handler).

```kotlin
require(!userRepository.existsByEmail(request.email)) { "EMAIL_TAKEN" }
...
return userRepository.save(user)
```

This is a TOCTOU race: two concurrent registrations with the same email can both pass
`existsByEmail`, then the second `save` fails the DB unique index with
`DataIntegrityViolationException`. That exception is not handled → **500** instead of the
intended `409 EMAIL_TAKEN` (AC-002). The DB constraint is the correct backstop, but its
failure path is unhandled.

**Recommended fix:** Either (a) catch `DataIntegrityViolationException` in
`AuthExceptionHandler` and map to `409 EMAIL_TAKEN`, relying on the DB constraint as the
source of truth; or (b) keep the app check but also map the constraint violation. Prefer
(a) — let the DB be authoritative and remove the racy pre-check, or keep the pre-check
only as a fast-path.

### H5 — No injectable `Clock`; all time access uses `Instant.now()` directly (ADR-006 violation)

**Files:** `TokenService.kt:25,41`; `User.kt:30`; `RefreshToken.kt:29,32`; (also
`RegistrationService`/`LoginService` indirectly).

ADR-006 is explicit: *"All time access goes through an injectable `java.time.Clock`, so
time-dependent acceptance criteria can be tested deterministically,"* and *"The server
clock is the sole authority for … all other recorded instants."* Token
`issuedAt`/`expiration`, `refreshTokenExpiry()`, `createdAt`, and `expiresAt` all call
`Instant.now()` directly. There is no `Clock` bean anywhere (confirmed via search). This
makes token-expiry and timestamp behavior non-deterministic in tests and will directly
block Step 8's *"expiry enforced"* test and Step 18's *"injectable Clock fixed per test."*

**Recommended fix:** Add `@Bean fun clock(): Clock = Clock.systemUTC()` (or
`Clock.system(zone)`), and inject `Clock` into `TokenService`, `User`/`RefreshToken`
creation, and any service that records instants. Establish the pattern now so later
modules inherit it.

---

## 🟡 MEDIUM

### M1 — `@Version` is declared on an immutable `val` (Kotlin/JPA optimistic-locking hazard)

**File:** `User.kt:32-33`

```kotlin
@Version
val version: Long = 0
```

Hibernate must mutate the version column on every update. A Kotlin `val` (final field)
makes that update unreliable/fragile (Hibernate writes managed fields via reflection;
final-field writes are not guaranteed and are a well-known Kotlin+JPA gotcha). No `User`
update occurs in Milestone 2 (only inserts), so it's latent — but it will surface on the
first `User` update (AC-011 password change, AC-014 timezone change), which are upcoming.

**Recommended fix:** `@Version var version: Long = 0` (keep all other fields `val`).
Verify with a concurrent-update test once updates exist.

### M2 — Business conflict surfaced via `IllegalArgumentException` + string-matched message (fragile control flow)

**Files:** `RegistrationService.kt:16-18`; `AuthExceptionHandler.kt:17-25`

```kotlin
require(!userRepository.existsByEmail(request.email)) { "EMAIL_TAKEN" }
...
if (ex.message == "EMAIL_TAKEN") { ... 409 ... }
```

`require{}` is for precondition violations, not domain conflicts, and routing a 409 vs 400
by string-equality on an exception message is brittle (any other
`IllegalArgumentException("EMAIL_TAKEN")` would mis-map; a renamed message silently
downgrades to 400). ADR-005 wants domain errors mapped to typed errors/status codes.

**Recommended fix:** Introduce a typed `DuplicateEmailException` (domain exception) thrown
from `RegistrationService`, mapped to `409 EMAIL_TAKEN` in the handler. Reserve
`IllegalArgumentException`/`require` for true precondition bugs.

### M3 — Duplicate-registration discloses that the email is registered, contrary to ADR-004's stated preference (unresolved decision D3 implemented without sign-off)

**Files:** `RegistrationService.kt:16-18`; `AuthExceptionHandler.kt:19-21` →
`409 EMAIL_TAKEN` *"An account with this email already exists."*

The User Management spec lists this as an **Open Question**: *"Confirm that duplicate
registration returns 'email unavailable' feedback, accepting the account-enumeration
trade-off (ADR-004 prefers non-disclosure for authentication failures)."* Plan 001 D3
also flags it as unresolved. The implementation chose disclosure. That is a defensible
product choice, but it was made without the spec/ADR being updated, and it runs against
ADR-004's non-disclosure stance. Per AGENTS.md ("Do not silently change requirements /
source of truth priority"), this needs an explicit decision recorded.

**Recommended fix:** Resolve D3 explicitly — either (a) keep `409 EMAIL_TAKEN` and update
the spec's Open Question + ADR-004 to record the accepted enumeration trade-off, or (b)
return a generic response consistent with ADR-004. Do not leave it as an implementer's
silent choice.

### M4 — `refresh_tokens.token_hash` has no unique constraint and no lookup index (schema gap for Step 8)

**File:** `V2__users.sql:15-26`

The schema (created in Milestone 2, Step 3) has an index on `user_id` but none on
`token_hash`. Step 8 refresh rotation must look up a token by its hash and must guarantee
one row per token. Without a `UNIQUE` constraint on `token_hash`, a bug in rotation could
create duplicate token rows silently; without an index, refresh lookups scan the table.

**Recommended fix:** Add
`CREATE UNIQUE INDEX idx_refresh_tokens_token_hash ON refresh_tokens (token_hash);`
(and consider indexes on `rotated_from` and `expires_at` for family revocation and
cleanup). Since `V2` is already applied, do this via a new forward migration
(ADR-003: forward-only) rather than editing `V2`.

### M5 — No layer separation within the `user` module; ArchUnit only checks cycles

**Files:** all `com.productivityos.user.*` (controllers, services, JPA entities,
repositories in one package); `ArchitectureTest.kt:16-20` (cycle rule only).

ADR-005/system.md prescribe a dependency direction *API layer → application services →
domain → persistence*, with controllers thin and persistence separated. Currently
controller/service/entity/repository coexist in a single package with no sub-package
boundaries, and the ArchUnit test enforces only "free of cycles" — not the layering rules
(e.g., controllers must not call repositories directly; services must not depend on
controllers; persistence must not be referenced from the API layer). ADR-002 says module
boundaries must be *"enforced mechanically from the start."*

**Recommended fix:** Introduce sub-packages (`user/api`, `user/app`/`user/service`,
`user/domain`, `user/persistence`) and add ArchUnit rules for the dependency direction and
"controllers call services only." The test's own comment says rules will grow — start
growing them now while the module is tiny.

---

## 🟢 LOW

### L1 — `RefreshToken.userId` has a sentinel default `UUID(0,0)`

**File:** `RefreshToken.kt:20` — `val userId: UUID = UUID(0,0)`. A "zero UUID" default can
mask a missing assignment and persist a bogus `user_id`. **Fix:** remove the default so
the constructor requires `userId` (fail-fast). (Once C1 is fixed with `user.id!!`, the
default is never used anyway.)

### L2 — `RefreshToken.expiresAt` defaults to `Instant.now()` (immediate-expiry footgun)

**File:** `RefreshToken.kt:32`. If a caller forgets to set `expiresAt`, the token is born
expired. `LoginService` always sets it, but the default is dangerous. **Fix:** require
`expiresAt` in the constructor (no default), or default to a sentinel that fails
validation.

### L3 — JWT signing key derived with default charset; no `iss`/`aud` claims; dev secret hardcoded with no prod guard

**File:** `TokenService.kt:20` (`jwtSecret.toByteArray()` — should be `Charsets.UTF_8`);
`TokenService.kt:26-31` (no `iss`/`aud` — Plan Step 7 lists `iss` as a required claim);
`application.yml:26` (default `JWT_SECRET` baked in). **Fix:** `toByteArray(Charsets.UTF_8)`;
add `.issuer(...)`/`.audience(...)` (Step 7 will formalize); fail-fast in production if
`JWT_SECRET` equals the dev default or is unset.

### L4 — `Argon2PasswordEncoder` injected as the concrete class, not the `PasswordEncoder` interface

**Files:** `RegistrationService.kt:12`, `LoginService.kt:17`
(`private val passwordEncoder: Argon2PasswordEncoder`). **Fix:** type as `PasswordEncoder`
for idiomatic Spring and easier swapping/mocking.

### L5 — `existsByEmail` loads the whole entity to check existence; `email` has no length cap

**Files:** `UserRepository.kt:12-14` (default method calls `findByEmailIgnoreCase`);
`RegisterRequest.kt:9-10` (`@Email` with no `@Size(max=...)`). A >255-char email passes
`@Email` but fails the `VARCHAR(255)` column → unmapped `DataIntegrityViolationException`
→ 500. **Fix:** use a `SELECT count`/`EXISTS` query for `existsByEmail`; add
`@Size(max=254)` (RFC 5321 practical max) to `email`.

### L6 — `ZoneId.of` accepts non-IANA zones (offsets like `+02:00`, `Z`)

**File:** `RegistrationService.kt:21`. The spec says *"IANA timezone identifier."*
`ZoneId.of("+02:00")` is accepted (an offset zone), which isn't an IANA id and would break
DST handling later. **Fix:** validate with `ZoneId.of(zone).getId()` and reject
`ZoneOffset` instances, or use a strict IANA whitelist/regex (`^[A-Za-z_]+/[A-Za-z_]+$`
style, plus `UTC`).

### L7 — `AuthenticationException` uses `message` as the error `code`

**File:** `AuthExceptionHandler.kt:13` — `mapOf("code" to (ex.message ?: "invalid_credentials"), ...)`.
The wire `code` becomes whatever string was passed to the exception. **Fix:** give
`AuthenticationException` a stable `code` property distinct from the human message.

### L8 — `spring-boot-starter-security` not yet a dependency / no `SecurityConfig`

**File:** `apps/api/build.gradle.kts` (only `spring-security-crypto` present). This is
**expected** for Milestone 2 (full security wiring is Step 9), and adding the starter now
would auto-secure all endpoints and break public health/register/login until configured.
Noting only so it's tracked for Step 9. Also: no `springdoc-openapi` (ADR-005 §10 requires
generated OpenAPI) — schedule for a later step.

### L9 — `ApplicationContextTest` comment under-describes the migration set

**File:** `ApplicationContextTest.kt:35` — comment says *"Flyway applied V1__baseline.sql
cleanly"* but `V2__users.sql` also applies. Cosmetic; not an implementation defect.

---

## ✅ What is correct (verified against source of truth)

- **Argon2id** via `Argon2PasswordEncoder.defaultsForSpringSecurity_v5_8()` — confirmed
  from Spring Security source (`Argon2Parameters.ARGON2_id`) with **constant-time**
  comparison (`constantTimeArrayEquals`). Meets ADR-004 §5. BouncyCastle dependency
  present (`bcprov-jdk18on`). OWASP-aligned params (16 KB? no — 1<<14 KB = ~16 MiB,
  2 iterations, parallelism 1, 16-byte salt, 32-byte hash). — `PasswordEncoderConfig.kt:11`,
  `build.gradle.kts`.
- **Email case-insensitive uniqueness** at the DB (`UNIQUE INDEX … (lower(email))`,
  `V2__users.sql:13`) + app-level `findByEmailIgnoreCase` + lowercase storage
  (`RegistrationService.kt:26`). Satisfies Rule 1 / AC-002 (the backstop is correct; only
  the exception mapping is wrong — see H4).
- **Password policy** `@Size(min = 12)` with no composition rules and no rotation — matches
  Rule 2 / AC-003 (`RegisterRequest.kt:13`).
- **Refresh token stored hashed** (SHA-256, Base64) not plaintext, and **delivered only via
  cookie** (`HttpOnly + Secure + SameSite=Strict`, `path=/api/v1/auth`, 30-day maxAge); the
  refresh token is **not** returned in the JSON body (only the access token is). Satisfies
  ADR-004 §3 and Security Considerations. — `LoginService.kt:54-58`, `AuthController.kt:35-54`,
  `LoginResponse.kt`.
- **Login returns an identical generic 401 body** for unknown-email and wrong-password
  (`LoginService.kt:29,32`; `AuthExceptionHandler.kt:11-15`). Body-level non-disclosure is
  correct (timing is not — see H1).
- **Registration does not auto-issue tokens** — matches Plan Step 5 default / Open Question
  D2 (`AuthController.kt:19-30` returns `201` + user only).
- **Timezone defaults to UTC** and is validated via `ZoneId.of` (`RegistrationService.kt:20-23`;
  `V2__users.sql:8` default `'UTC'`). Logic for AC-012 is correct; AC-013 validation runs
  but its error mapping is wrong (H2).
- **Persistence per ADR-003:** Flyway versioned migrations, `ddl-auto: validate`,
  `open-in-view: false`, UUID PKs (`gen_random_uuid()`), `timestamptz` timestamps,
  `@Version` optimistic locking on `User`, FKs (`refresh_tokens.user_id → users`, self-FK
  `rotated_from → refresh_tokens`), index on `user_id`. — `application.yml:9-15`,
  `V1__baseline.sql`, `V2__users.sql`, `User.kt`.
- **kotlin-jpa plugin applied** so entities with all-defaulted props get the required
  no-arg constructor — `build.gradle.kts`, `User.kt`, `RefreshToken.kt`.
- **Controllers are thin** and call exactly one application service each; `@Transactional`
  on services (one tx per use case, ADR-003); `/api/v1` prefix and resource-oriented auth
  endpoints (ADR-005). — `AuthController.kt`, `RegistrationService.kt`, `LoginService.kt`.
- **No client-supplied userId** is used to establish identity in register/login (ADR-004
  invariant respected within this scope; enforcement for domain endpoints arrives in
  Step 9).
- **ArchUnit skeleton present** and application-context/migration test present (Plan Steps
  1–2). — `ArchitectureTest.kt`, `ApplicationContextTest.kt`.

---

## Missing AC coverage (User Management spec)

ACs the spec defines, mapped to this milestone's scope:

| AC | Status | Note |
|---|---|---|
| AC-001 registration creates account | ✅ Implemented (error-handling gaps: H2/H3) | |
| AC-002 duplicate email rejected (case-insensitive) | ⚠️ Partial | Logic/index correct; concurrency→500 (H4) |
| AC-003 password ≥12, no composition | ✅ Rule correct | Validation error not structured (H3) |
| AC-004 Argon2id memory-hard | ✅ Correct | |
| AC-005 passwords never plaintext in logs/errors | ✅ No leakage found | |
| AC-006 login establishes session | ⚠️ Partial | Rotation/reuse-detection deferred (Step 8) |
| AC-007 multiple devices, independent sessions | ✅ Within scope | One refresh row per login |
| AC-008 session persists across restarts | ⚠️ Partial | Refresh endpoint deferred (Step 8) |
| AC-009 logout ends current device | ❌ Not implemented | Deferred — Step 8 |
| AC-010 post-logout session rejected | ❌ Not implemented | Deferred — Step 8 |
| AC-011 password change revokes all sessions | ❌ Not implemented | No password-change endpoint; deferred |
| AC-012 default timezone UTC | ✅ Correct | |
| AC-013 valid IANA set / invalid rejected | ⚠️ Partial | Validation runs but rejects with 500 (H2) |
| AC-014 timezone change is prospective | ❌ Not implemented | No timezone-change endpoint; deferred |
| AC-015 identity from session, not client-supplied | ⚠️ N/A in scope | No authenticated domain endpoints yet; enforcement is Step 9. Register/login correctly avoid client-supplied identity. |
| AC-016 no anonymous access to domain data | ❌ Not enforced | No `SecurityConfig` yet; also no domain endpoints yet — Step 9 |
| AC-017 repeated failures rate-limited | ❌ Not implemented | Deferred — Step 9 |
| Spec Behavior: login generic error doesn't reveal registration | ⚠️ Body ok, **timing leaks** | H1 |

**Also deferred (Step 8 / ADR-004 token strategy):** refresh-token rotation on every use,
reuse detection with family revocation, logout revoking the device token, expiry
enforcement with clock-skew tolerance.

---

## Recommended fixes (consolidated, exact references)

1. **C1** `LoginService.kt:40` — `userId = user.id!!` (then refactor `User.id` to a
   non-null post-persistence model).
2. **H1** `LoginService.kt:28-33` — perform a dummy `passwordEncoder.matches(...)` against
   a constant hash when the user is absent, to equalize timing.
3. **H2** `AuthExceptionHandler.kt` — add `@ExceptionHandler(DateTimeException::class)` →
   `400 {code:"INVALID_TIMEZONE"}`.
4. **H3** `AuthExceptionHandler.kt` — add
   `@ExceptionHandler(MethodArgumentNotValidException::class)` →
   `400 {code:"VALIDATION_ERROR", details:[…]}`.
5. **H4** `AuthExceptionHandler.kt` — add
   `@ExceptionHandler(DataIntegrityViolationException::class)` →
   `409 {code:"EMAIL_TAKEN"}`; treat the DB unique index as authoritative.
6. **H5** add a `Clock` `@Bean` and inject it into `TokenService` (`k:25,41`),
   `User`/`RefreshToken` creation, and `RegistrationService`/`LoginService`.
7. **M1** `User.kt:32-33` — `@Version var version: Long = 0`.
8. **M2** `RegistrationService.kt:16-18` + `AuthExceptionHandler.kt:17-25` — replace
   `require{}`+string-match with a typed `DuplicateEmailException` → `409`.
9. **M3** resolve Plan D3 / spec Open Question; update the spec or ADR-004 to match the
   chosen behavior.
10. **M4** new forward migration: `CREATE UNIQUE INDEX … ON refresh_tokens (token_hash)`
    (+ indexes on `rotated_from`, `expires_at`).
11. **M5** split `user` into `api/app/domain/persistence` sub-packages; add ArchUnit layer
    rules.
12. **L1-L7** as above (remove sentinel defaults, `Charsets.UTF_8`, `@Size(max=254)` on
    email, strict IANA validation, `PasswordEncoder` interface, stable error codes).
13. **L8** schedule `spring-boot-starter-security` + `SecurityConfig` (Step 9) and
    `springdoc-openapi` (ADR-005 §10).

---

## Summary

The Milestone 2 **structure** matches Plan 001 Steps 3–6 and the persistence/security
*choices* (Argon2id, case-insensitive email uniqueness, hashed refresh tokens in scoped
HttpOnly cookies, UUID/`timestamptz`/`@Version`/Flyway) are largely **correct and
traceable to the ADRs**. However, there is one **CRITICAL** compile-blocking null-safety
bug (C1), four **HIGH** issues spanning a login timing oracle (H1), wrong HTTP status for
invalid timezone (H2), non-conforming validation errors (H3), unmapped duplicate-email
constraint violations (H4), and a systemic **ADR-006 `Clock` violation** (H5). The
error-handling layer (`AuthExceptionHandler`) is the weakest spot: it covers only two
exception types and string-matches messages, so several client-error paths leak as `500`.
None of these are test-execution artifacts; they are present in the source. Steps 7–9
features (JWT filter, refresh rotation/logout, security wiring, rate limiting) are
correctly absent for this milestone and listed only as deferred AC coverage.

