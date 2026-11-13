# Plan 020: Refresh Token Robustness & Rotation Grace Period

## Status

Approved

---

## Specification

### Primary Behavioral Source of Truth

- [refresh-token-robustness.md](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/specs/auth/refresh-token-robustness.md) (Draft)
- [ADR-003: Database Persistence](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/decisions/ADR-003-database-persistence.md) (Accepted)
- [ADR-004: Authentication and User Isolation](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/decisions/ADR-004-authentication-user-isolation.md) (Proposed)
- [ADR-005: API Architecture](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/decisions/ADR-005-api-architecture.md) (Accepted)

### Acceptance Criteria in Scope

- **AC-001:** Token Refresh within Rotation Grace Period Succeeds (`RefreshTokenService`)
- **AC-002:** Replay Outside Rotation Grace Period Triggers Family Revocation (`RefreshTokenService`)
- **AC-003:** Grace Window Denied for Logged-Out Sessions (`RefreshTokenService`)
- **AC-004:** Access Token TTL Restored to 15 Minutes (`application.yml`, `TokenService`)
- **AC-005:** Refresh Token Extraction via `X-Refresh-Token` Header (`AuthController`)
- **AC-006:** Cookie Takes Precedence Over `X-Refresh-Token` Header (`AuthController`)
- **AC-007:** Refresh Token Exposed in `LoginResponse` Body (`LoginResponse`, `AuthController`)
- **AC-008:** Forwarded Headers Produce Secure Cookie Over HTTPS Proxy (`application.yml`)
- **AC-009:** Token Hash Index Created via Flyway Migration (`V17__refresh_tokens_token_hash_idx.sql`)

---

## Pre-Implementation Decisions

### D1: Raw Child Token Delivery During Grace Period Window

- **Context:** ADR-004 mandates that refresh tokens are stored in PostgreSQL exclusively as cryptographic SHA-256 hashes (`token_hash`). When a rotated token `T0` is presented again within the 30-second grace window, the database record for child token `T1` contains only `T1`'s hash. The server cannot reverse `T1`'s hash to plaintext.
- **Options Evaluated:**
  - **Option A (In-Memory Cache with Null Fallback — Recommended):** In `RefreshTokenService`, keep a lightweight, thread-safe, time-bounded in-memory cache (e.g., `ConcurrentHashMap<String, CachedToken>` pruned at 30 seconds) mapping `oldTokenHash -> rawNewRefreshToken`.
    - When rotating `T0 -> T1`, record `T0_hash -> T1_raw`.
    - If `T0` is re-presented within 30 seconds, retrieve `T1_raw` from the cache. The endpoint returns `T1_raw` in the response body and `Set-Cookie`.
    - If the cache misses (due to app restart or multi-instance load balancing), the service safely returns `TokenPair(accessToken = newAccessToken, refreshToken = null)`. The client receives a valid new access token, and `AuthController` omits `Set-Cookie`, preserving the client's existing cookie jar.
  - **Option B (Stateless Grace — Access Token Only):** Never store raw tokens in memory. On grace hit, always return `refreshToken = null` and do not emit `Set-Cookie`.
    - *Drawback:* If the client's original HTTP response containing `T1` was dropped on the wire, the client will not receive `T1` on retry.
  - **Option C (Secondary Rotation):** Rotate again and generate token `T2` branched from `T0`.
    - *Drawback:* Violates strict linear lineage and can spawn unbounded branching child tokens if concurrent requests spike.
- **Decision:** **Option A**. Implement an in-memory short-term rotation cache (30-second TTL) in `RefreshTokenService` with graceful fallback to `refreshToken = null` on cache miss. This delivers the exact same child token to concurrent callers without storing plaintext tokens in PostgreSQL.

### D2: Backward Compatibility for Web and Mobile Clients

- **Context:** The web application (`apps/web`) expects an HttpOnly cookie and does not look for `refreshToken` in the response body. iOS (`apps/ios`) benefits from having `refreshToken` in `LoginResponse` so it can persist it in Apple Keychain as a fallback to URLSession cookie storage.
- **Decision:** Include `val refreshToken: String? = null` in `LoginResponse.kt`. Set it during login, QR exchange, and regular refresh. In `refresh()`, only emit `Set-Cookie` if `pair.refreshToken != null`.

---

## Agent Delegation Matrix

| Agent | Target Slice | Owned Files / Scope | Verification Command | Dispatch Brief |
| :--- | :--- | :--- | :--- | :--- |
| `@backend` | Slice 1 | `apps/api/**` (Flyway migration, config, DTOs, service, controller, unit/slice tests) | `./gradlew :apps:api:test` | Implement grace period, config restoration, header fallback, response body token, and index migration |
| `@code-reviewer` | Slice 2 | `git diff apps/api/` | `bash scripts/agent-review.sh` | Independent audit against ADR-003, ADR-004, ADR-005, and AC-001 through AC-009 |

---

## Implementation Slices

### Slice 1: Database Migration for Token Hash Index

**Status:** completed

- **Assigned Agent:** `@backend`
- **Files/Modules:**
  - `apps/api/src/main/resources/db/migration/V17__refresh_tokens_token_hash_idx.sql`
- **Acceptance Criteria:** `AC-009`
- **Behavior:**
  - Create index `idx_refresh_tokens_token_hash` on `refresh_tokens(token_hash)`.
  - Ensures O(1) B-tree lookup for `refreshTokenRepository.findByTokenHash()`.
- **Verification Command:**
  - `./gradlew :apps:api:test` (runs Flyway migration validation during context startup).

---

### Slice 2: Configuration & Access Token TTL Restoration

**Status:** completed

- **Assigned Agent:** `@backend`
- **Files/Modules:**
  - `apps/api/src/main/resources/application.yml`
- **Acceptance Criteria:** `AC-004`, `AC-008`
- **Behavior:**
  - Restore `app.jwt.access-token-ttl-minutes: ${JWT_ACCESS_TOKEN_TTL_MINUTES:15}`.
  - Add `app.jwt.refresh-token-grace-period-seconds: ${JWT_REFRESH_TOKEN_GRACE_PERIOD_SECONDS:30}`.
  - Under `server:`, configure `forward-headers-strategy: framework` to honor `X-Forwarded-Proto: https` from Google Cloud Run and reverse proxies.
- **Verification Command:**
  - `./gradlew :apps:api:test`

---

### Slice 3: Refresh Token Service Grace Period & Rotation Cache

**Status:** completed

- **Assigned Agent:** `@backend`
- **Files/Modules:**
  - `apps/api/src/main/kotlin/com/productivityos/auth/service/RefreshTokenService.kt`
- **Acceptance Criteria:** `AC-001`, `AC-002`, `AC-003`
- **Behavior:**
  1. Inject `@Value("\${app.jwt.refresh-token-grace-period-seconds:30}") private val gracePeriodSeconds: Long = 30`.
  2. Maintain a thread-safe cache `private val recentRotations = ConcurrentHashMap<String, CachedRotation>()` where:
     ```kotlin
     private data class CachedRotation(
         val rawRefreshToken: String,
         val rotatedAt: Instant
     )
     ```
  3. When rotating token `stored` to `rotated`:
     - Record `recentRotations[tokenHash] = CachedRotation(newRefreshToken, now)`.
     - Evict entries older than `gracePeriodSeconds`.
  4. When `stored.revokedAt != null`:
     - Check `clock.instant().isBefore(stored.revokedAt!!.plusSeconds(gracePeriodSeconds))`.
     - If true:
       - Find active child: query `refreshTokenRepository.findAllByUserIdAndRotatedFrom(stored.userId, stored.id!!)`.
       - Check if any child is active (`revokedAt == null && clock.instant().isBefore(expiresAt)`).
       - If active child exists:
         - Generate new access token: `tokenService.generateAccessToken(stored.userId)`.
         - Lookup cached raw token: `recentRotations[tokenHash]?.rawRefreshToken`.
         - Return `TokenPair(accessToken = newAccessToken, refreshToken = cachedRawToken)`.
         - Do NOT invoke `revokeFamily()` and do NOT throw `InvalidRefreshTokenException`.
       - If no active child exists (e.g. session was revoked via logout): fall through to theft detection.
     - If false (grace period elapsed):
       - Call `revokeFamily(stored)`.
       - Throw `InvalidRefreshTokenException()`.
- **Verification Command:**
  - `./gradlew :apps:api:test --tests "com.productivityos.auth.service.RefreshTokenServiceTest"`

---

### Slice 4: Controller Header Fallback & LoginResponse DTO

**Status:** completed

- **Assigned Agent:** `@backend`
- **Files/Modules:**
  - `apps/api/src/main/kotlin/com/productivityos/auth/dto/LoginResponse.kt`
  - `apps/api/src/main/kotlin/com/productivityos/auth/controller/AuthController.kt`
- **Acceptance Criteria:** `AC-005`, `AC-006`, `AC-007`
- **Behavior:**
  1. In `LoginResponse.kt`, add `val refreshToken: String? = null`:
     ```kotlin
     data class LoginResponse(
         val accessToken: String,
         val refreshToken: String? = null,
         val user: UserResponse? = null
     )
     ```
  2. In `AuthController.kt`:
     - Update `extractRefreshToken(request: HttpServletRequest)`:
       ```kotlin
       private fun extractRefreshToken(request: HttpServletRequest): String? {
           val cookieToken = request.cookies?.find { it.name == "refresh_token" }?.value
           if (!cookieToken.isNullOrBlank()) {
               return cookieToken
           }
           val headerToken = request.getHeader("X-Refresh-Token")
           if (!headerToken.isNullOrBlank()) {
               return headerToken
           }
           return null
       }
       ```
     - Update `login()` to supply `refreshToken = result.refreshToken` to `LoginResponse`.
     - Update `qrExchange()` to supply `refreshToken = result.refreshToken` to `LoginResponse`.
     - Update `refresh()`:
       - If `pair.refreshToken != null`: attach `Set-Cookie` with `buildRefreshCookie(pair.refreshToken, request.isSecure)`.
       - Pass `pair.accessToken` and `pair.refreshToken` to `LoginResponse`.
- **Verification Command:**
  - `./gradlew :apps:api:test`

---

### Slice 5: Automated Testing & Verification Suite

**Status:** completed

- **Assigned Agent:** `@backend`
- **Files/Modules:**
  - `apps/api/src/test/kotlin/com/productivityos/auth/service/RefreshTokenServiceTest.kt`
  - `apps/api/src/test/kotlin/com/productivityos/auth/controller/AuthControllerTest.kt` (new)
- **Acceptance Criteria:** `AC-001` through `AC-008`
- **Behavior:**
  1. `RefreshTokenServiceTest.kt`:
     - Test: `refresh within grace period succeeds and returns new access token and cached refresh token`.
     - Test: `refresh within grace period succeeds even if cache misses (returns null refresh token)`.
     - Test: `refresh outside grace period triggers family revocation`.
     - Test: `refresh on logged-out token within grace period fails with InvalidRefreshTokenException`.
  2. `AuthControllerTest.kt`:
     - Test: `POST /refresh with valid cookie returns 200 with new access token and refresh cookie`.
     - Test: `POST /refresh with X-Refresh-Token header returns 200 when cookie absent`.
     - Test: `POST /refresh prefers cookie value over X-Refresh-Token header`.
     - Test: `POST /refresh returns 401 when both cookie and header are missing`.
     - Test: `POST /logout extracts token from X-Refresh-Token header and revokes token`.
     - Test: `LoginResponse body contains refreshToken on login and refresh`.
- **Verification Command:**
  - `./gradlew :apps:api:test`

---

## Tests & QA Matrix

| Acceptance Criteria | Implementation Step | Test File / Verification Method | Expected Result |
| :--- | :--- | :--- | :--- |
| **AC-001** (Grace period refresh) | Slice 3, Slice 5 | `RefreshTokenServiceTest` | Returns new access token, does not throw, does not revoke family |
| **AC-002** (Theft detection outside grace) | Slice 3, Slice 5 | `RefreshTokenServiceTest` | Throws `InvalidRefreshTokenException`, marks family revoked |
| **AC-003** (Logged out token rejected) | Slice 3, Slice 5 | `RefreshTokenServiceTest` | Throws `InvalidRefreshTokenException` (no active child) |
| **AC-004** (15-min Access Token TTL) | Slice 2 | `TokenServiceTest` / `application.yml` | JWT expiry claim = issuedAt + 900s |
| **AC-005** (`X-Refresh-Token` header) | Slice 4, Slice 5 | `AuthControllerTest` | Returns 200 with new token when cookie absent |
| **AC-006** (Cookie precedence) | Slice 4, Slice 5 | `AuthControllerTest` | Cookie token preferred over header |
| **AC-007** (`LoginResponse.refreshToken`) | Slice 4, Slice 5 | `AuthControllerTest` | JSON body contains `refreshToken` string |
| **AC-008** (Forwarded headers HTTPS) | Slice 2 | `application.yml` configuration check | `ForwardedHeaderFilter` enabled, cookie sets `Secure` |
| **AC-009** (Database index) | Slice 1 | Flyway migration `V17` | `idx_refresh_tokens_token_hash` created on table |

---

## Completion Checklist

- [x] Approved specification in `docs/specs/auth/refresh-token-robustness.md`.
- [x] Flyway migration `V17__refresh_tokens_token_hash_idx.sql` created.
- [x] `application.yml` updated with `server.forward-headers-strategy`, 15-minute access token TTL, and 30-second grace period.
- [x] `RefreshTokenService.kt` updated with grace window check, active child detection, and in-memory rotation cache.
- [x] `LoginResponse.kt` updated with `refreshToken` field.
- [x] `AuthController.kt` updated with header fallback and response body population.
- [x] Unit and controller slice tests written and passing.
- [x] Full backend test suite passing (`./gradlew :apps:api:test --tests "com.productivityos.auth.**"`).
- [x] Code review completed via `./scripts/agent-review.sh` or `@code-reviewer`.

---

## Change History

- **2026-11-13:** Initial Draft created for refresh token robustness, rotation grace period, header fallback, access token TTL restoration, reverse proxy forwarding, and database index migration.
