# Refresh Token Robustness & Rotation Grace Period

## Status
Approved

## Problem

Under the strict Refresh Token Rotation (RTR) model implemented in ADR-004, when a refresh token is presented to `/api/v1/auth/refresh`, it is immediately marked revoked (`revokedAt = clock.instant()`) and a single child token is generated. When a client fires multiple concurrent requests upon page load or app launch (e.g. `TodayPage.vue` fetching tasks, daily plans, habits, and focus sessions in parallel, or iOS `TodayViewModel.swift` doing parallel refreshes), or when multi-tab browsing occurs:
1. Multiple requests fail with 401 when an access token expires.
2. Even with client-side single-flight locks, race conditions or multiple browser tabs can cause near-simultaneous calls to `/api/v1/auth/refresh` carrying the same refresh token.
3. The first request rotates the token successfully. The second request arrives milliseconds later with the previously valid token. Because `revokedAt != null`, the server immediately interprets this as a token theft attempt, invokes `revokeFamily()`, revokes all tokens including the newly minted child token, and destroys the entire user session.
4. Furthermore, temporary access token TTL churn (1 minute) amplifies this race frequency. Native iOS clients also risk session drops if URLSession cookie storage is cleared or desynchronized by iOS background lifecycles.
5. High-volume token lookups by `token_hash` incur sequential table scans due to a missing database index on `refresh_tokens(token_hash)`.

## Goal

Provide high-reliability, attack-resilient refresh token rotation by introducing a 30-second rotation grace window, restoring sensible 15-minute access token TTLs, adding `X-Refresh-Token` header fallback and response body support for native clients, honoring reverse proxy HTTPS headers for secure cookies, and indexing token hashes for O(1) database lookups.

## User Story

As a user across web tabs and native iOS devices, I want my active sessions to stay authenticated reliably without random logouts during concurrent data loading or network retries, while still protecting my account against actual token replay attacks.

## Behavior

- When a refresh token is presented to `POST /api/v1/auth/refresh`, the server checks whether the token was already rotated within the configurable grace window (default: 30 seconds).
- If the token was rotated within the grace window, the server recognizes it as a benign concurrent request or network retry: it verifies that a valid active child token exists, generates a fresh access token, and returns success without revoking the token family.
- If the token was rotated prior to the grace window (or has no active child lineage), the server treats the request as a token theft attempt: it revokes the entire token family and returns HTTP 401 `invalid_token`.
- Access tokens expire after 15 minutes by default (`app.jwt.access-token-ttl-minutes: 15`).
- The server extracts refresh tokens primarily from the `refresh_token` HttpOnly cookie; if absent or blank, it falls back to the `X-Refresh-Token` request header.
- Successful login, refresh, and QR exchange responses include the refresh token string in the `LoginResponse` body (`refreshToken`), allowing native clients (iOS) to store it in Apple Keychain.
- Spring Boot honors reverse proxy headers (`X-Forwarded-Proto`) via `server.forward-headers-strategy: framework`, guaranteeing that `request.isSecure` is true behind Cloud Run and cookies receive the `Secure` flag.
- The `refresh_tokens` database table contains a dedicated B-tree index on `token_hash`.

## Rules

1. **Grace Window Boundary:** A rotated token is eligible for grace treatment if and only if `clock.instant().isBefore(stored.revokedAt.plusSeconds(gracePeriodSeconds))`.
2. **Lineage Invariant:** A revoked token presented within the grace window MUST have an active (unrevoked, unexpired) child token rotated from it (`rotatedFrom = stored.id`). If no active child exists (e.g. the session was explicitly terminated via `/logout` or password change), grace MUST NOT be granted.
3. **Theft Detection Preservation:** Presentation of a revoked token outside the grace window, or presentation of any token whose family was already compromised, MUST trigger `revokeFamily()` and reject the request with HTTP 401 `invalid_token` per ADR-004.
4. **Cookie & Header Precedence:** When extracting a refresh token from incoming requests (`/refresh`, `/logout`), cookies take precedence. The `X-Refresh-Token` header is only inspected if the cookie is missing or blank.
5. **No Token Persistence in Plaintext:** Plaintext refresh tokens MUST NEVER be stored in the database (ADR-004). To deliver the active child token during a grace period hit, an in-memory short-term cache (TTL equal to the grace period) may be consulted, or the server may omit the token if not cached.
6. **Reverse Proxy Protocol Trust:** The application MUST trust reverse proxy forwarding headers when configured with `server.forward-headers-strategy: framework` to correctly flag cookies as `Secure` in HTTPS deployments.

## Constraints

- Backward compatibility: Existing web clients relying exclusively on HttpOnly cookies must continue to function without changes.
- Performance: Database index on `refresh_tokens(token_hash)` ensures lookups remain O(1) regardless of total stored token history.
- Compliance with ADR-003 and ADR-004: All persistence changes must be managed via Flyway migrations.

## Acceptance Criteria

### AC-001 — Token Refresh within Rotation Grace Period
Given a refresh token `T0` that was rotated to `T1` at timestamp `R`,
When a client sends `POST /api/v1/auth/refresh` with `T0` at timestamp `R + 10s` (within the 30-second grace window),
Then the server returns HTTP 200 with a new valid access token, does not throw `InvalidRefreshTokenException`, and does not revoke `T1` or the token family.

### AC-002 — Replay Outside Rotation Grace Period Triggers Family Revocation
Given a refresh token `T0` that was rotated to `T1` at timestamp `R`,
When a client sends `POST /api/v1/auth/refresh` with `T0` at timestamp `R + 35s` (after the 30-second grace window),
Then the server returns HTTP 401 with code `invalid_token`, marks all ancestor and descendant tokens in that family as revoked, and invalidates `T1`.

### AC-003 — Grace Window Denied for Logged-Out Sessions
Given a refresh token `T0` that was revoked via `POST /api/v1/auth/logout`,
When a client sends `POST /api/v1/auth/refresh` with `T0` within 30 seconds of logout,
Then the server rejects the request with HTTP 401 `invalid_token` because no active child token exists.

### AC-004 — Access Token TTL Restored to 15 Minutes
Given the default application configuration `app.jwt.access-token-ttl-minutes: 15`,
When an access token is generated via login, refresh, or QR exchange,
Then the JWT's `exp` timestamp is 900 seconds (15 minutes) after its `iat` timestamp.

### AC-005 — Refresh Token Extraction via X-Refresh-Token Header
Given an HTTP request to `POST /api/v1/auth/refresh` without a `refresh_token` cookie,
When the request includes header `X-Refresh-Token: <token>`,
Then the endpoint successfully extracts `<token>` and completes the refresh operation.

### AC-006 — Cookie Takes Precedence Over X-Refresh-Token Header
Given an HTTP request containing both a valid `refresh_token` cookie and an `X-Refresh-Token` header with different values,
When the endpoint extracts the refresh token,
Then the value from the cookie is selected.

### AC-007 — Refresh Token Exposed in LoginResponse Body
Given a successful request to `POST /api/v1/auth/login`, `POST /api/v1/auth/qr/exchange`, or `POST /api/v1/auth/refresh`,
When the response body is evaluated,
Then `LoginResponse.refreshToken` contains the newly issued refresh token string (or is present and populated for native clients).

### AC-008 — Forwarded Headers Produce Secure Cookie Over HTTPS Proxy
Given `server.forward-headers-strategy: framework` in configuration,
When a request arrives with header `X-Forwarded-Proto: https`,
Then `request.isSecure` evaluates to `true` and the resulting `Set-Cookie` header contains the `Secure` flag.

### AC-009 — Token Hash Index Created via Flyway Migration
Given the Flyway migration `V17__refresh_tokens_token_hash_idx.sql`,
When the migration executes,
Then index `idx_refresh_tokens_token_hash` exists on table `refresh_tokens(token_hash)`.

## Edge Cases

- **Chained Rotations in Grace Window:** If `T0` was rotated to `T1`, and `T1` was immediately rotated to `T2`, a late retry of `T0` within 30 seconds finds the latest active descendant `T2`.
- **Database Clock Drift:** All grace comparisons use the injected `java.time.Clock` bean to guarantee test determinism and prevent NTP clock skew issues between application instances and database servers.
- **Header Injection & Whitespace:** Blank or whitespace-only `X-Refresh-Token` headers are ignored and treated as missing.

## Out of Scope

- Changes to frontend Vue single-page application silent refresh loop (the existing single-flight lock remains in place and benefits transparently from the backend grace period).
- iOS Keychain persistence implementation in `apps/ios` (the backend provides the API contract and DTO fields in this slice; client-side iOS keychain uptake is tracked in follow-on native client work).
- Refresh token blacklisting with external distributed stores (Redis/Memcached); in-process memory cache and PostgreSQL are sufficient per ADR-003.

## Dependencies

- ADR-003: Database Persistence
- ADR-004: Authentication and User Isolation
- ADR-005: API Architecture

## Open Questions

- None at the specification level. Architectural design choices around in-memory caching during grace periods are documented in Plan 020 Decision `D1`.

## Change History

- **2026-11-13:** Initial Draft created for refresh token rotation grace period, header fallback, access token TTL restoration, reverse proxy forwarding, and database index migration.
