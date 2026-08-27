# QR Authentication (Backend)

## Status

Proposed

## Problem

iOS users need a fast way to authenticate without typing email/password on a mobile keyboard. An existing authenticated session on the web application can serve as a trust source to bootstrap the iOS session.

## Goal

Provide a secure challenge-exchange mechanism that allows a web-authenticated user to authorize a new iOS device.

## API Design

### POST /api/v1/auth/qr/challenge

**Role:** Web application (Authenticated)

Generates a short-lived, single-use authentication challenge.

**Authentication:** Required (Bearer token)

**Request:**
Empty body or optional device metadata.

**Response (200 OK):**
```json
{
  "challenge": "opaque-one-time-value",
  "expiresAt": "2026-08-27T10:15:00Z"
}
```

**Behavior:**
1. Create a `QrAuthChallenge` record bound to the `authenticatedUser`.
2. Set expiration (e.g., 2 minutes).
3. Return the opaque challenge string.

---

### POST /api/v1/auth/qr/exchange

**Role:** iOS application (Unauthenticated)

Exchanges a valid challenge for a full authentication session.

**Authentication:** None (Public)

**Request:**
```json
{
  "challenge": "opaque-one-time-value"
}
```

**Response (200 OK):**
```json
{
  "accessToken": "jwt-access-token",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "displayName": "User Name"
  }
}
```

**Errors:**
- 400 Bad Request: Malformed challenge.
- 401 Unauthorized: Challenge expired, already used, or invalid.
- 404 Not Found: Challenge does not exist.

**Behavior:**
1. Find `QrAuthChallenge` by `challenge` value.
2. Verify it is not expired.
3. Verify it has not been used.
4. Mark challenge as used.
5. Issue a new `LoginResponse` (JWT + Refresh Cookie) for the `User` associated with the challenge.

## Security Rules

1. **Short Lifetime:** Challenges must expire within minutes (e.g., 2-5 minutes).
2. **Single Use:** A challenge must be invalidated immediately after one exchange attempt (success or failure).
3. **No Sensitive Data in QR:** The challenge value must be an opaque, cryptographically random string (e.g., UUID or 32+ chars hex).
4. **User Binding:** The challenge is bound to the user who generated it on the web. The exchange issues a session for *that* specific user.
5. **Rate Limiting:** The exchange endpoint must be rate-limited to prevent brute-forcing challenges.

## Data Model

### QrAuthChallenge
- `id`: UUID (PK)
- `challenge`: String (Unique, Indexed)
- `userId`: UUID (FK to Users)
- `expiresAt`: Instant
- `usedAt`: Instant (Nullable)
- `createdAt`: Instant
