# Account Settings

**Status:** approved

## Problem

Users cannot change their password or timezone from the frontend. The
backend already exposes both operations (`UserController`:
`PUT /api/v1/users/password`, `PUT /api/v1/users/timezone`), and the
router already reserves a `/settings` route, but it renders a
ComingSoonPage. Timezone is load-bearing for the whole product
(ADR-006: "today", Top 3 dates, daily-plan dates are interpreted in the
user's configured timezone), and a user who relocates or wants a
stronger password currently has no way to update either setting.

## Goal

Provide an Account Settings page where a signed-in user can:

- See their account information (email and current timezone).
- Change their timezone.
- Change their password (current + new).

The page uses the existing API integration layer (silent refresh,
structured errors, mock toggles per `docs/specs/api-integration.md`).

## User Story

As a user, I want to change my timezone and password from the app, so
that my calendar days follow where I live and my account stays secure
without any API or support interaction.

## Behavior

- The signed-in user opens Settings from the navigation. The page shows
  their email and current timezone (from the login profile).
- Changing the timezone selects an IANA timezone identifier from a
  searchable picker: the browser-detected local zone is pinned first,
  followed by a short list of common zones, then the full IANA list
  (from `Intl.supportedValuesOf('timeZone')`, grouped by region), each
  entry showing its current UTC offset. On success, the saved profile
  and the in-memory session update immediately; the Today page and
  date-bucketed views use the new timezone prospectively (ADR-006:
  existing records keep their original dates).
- Changing the password requires the current password, a new password of
  at least 12 characters, and a confirm field that must match the new
  password (mismatch blocks submission; the confirm value is never sent
  to the server). On success the app ends the session immediately and
  redirects to the login screen, which shows a "password changed" banner
  (see Resolved Question 1).
- Wrong current password produces a clear inline error and does not end
  the session.
- Invalid input produces inline validation feedback before any request:
  a short new password or a mismatched confirm blocks submission, and a
  timezone picker search that matches no zone (or an empty selection)
  cannot be saved. The server's structured error is surfaced if a
  request still fails (see Rule 5).
- The page works without the backend in mock mode for design review.
- Network or server failures surface the existing error state with a
  Retry action.

## Rules

1. Identity and scoping stay server-side (ADR-004): the frontend sends
   only the Bearer access token, never a userId.
2. Password rules match the backend and `docs/specs/users/user-management.md`
   Rule 2: minimum 12 characters, no composition rules, no forced
   rotation. The client validates the length before submitting; the
   server remains the authority (`@Size(min = 12)`).
3. After a successful password change the server revokes all refresh
   tokens for the user (ADR-004: "Password change revokes all refresh
   tokens"). The current session therefore ends: the app clears the
   local session and returns to login. It must not attempt a silent
   refresh first, because the refresh token is already revoked.
4. A wrong current password maps to `401 invalid_credentials`; the UI
   shows the server's message inline (generic, revealing nothing about
   the account — per ADR-004, authentication failures are generic).
5. The timezone picker only offers valid IANA identifiers, so invalid
   values cannot be submitted through normal use; the server remains the
   authority (`ZoneId.of`): a request that still carries an invalid
   value maps to `400 INVALID_TIMEZONE` and the UI shows the server
   message without changing anything locally (defense in depth against
   stale lists or tampered requests).
6. Timezone changes apply prospectively only (ADR-006 Decision 10):
   stored dates are never recomputed client-side, and the client sends
   no dates or times in the request.
7. The structured error model is the only error contract (ADR-005):
   `code`, `message`, `details`, `traceId`. Domain messages surface to
   the user; raw backend text is never rendered.
8. Mock mode remains available via an environment toggle
   (`VITE_USE_MOCK_SETTINGS`), following the per-feature toggle pattern
   from `docs/specs/api-integration.md` Rule 8.
9. The integration must not change any backend behavior, endpoint, or
   response shape. Both endpoints already exist and are fixed.

## Constraints

- Backend endpoints are fixed by Milestone 1:
  - `PUT /api/v1/users/password` — body
    `{ currentPassword: string, newPassword: string }` →
    200 `UserResponse` (`{ id, email, timezone }`); 401
    `invalid_credentials` when the current password is wrong; 400
    `VALIDATION_ERROR` with field `details` when invalid.
  - `PUT /api/v1/users/timezone` — body `{ timezone: string }` → 200
    `UserResponse`; 400 `INVALID_TIMEZONE` when the IANA identifier is
    invalid.
- No `GET /users/me` exists; the profile comes from the login response
  and from these two update responses.
- No new dependencies: the existing `apiClient` and auth store suffice.
- The settings route already exists in the router (`/settings`,
  ComingSoonPage, `implemented: false`); this work implements it.

## Page Layout

The Settings page (`/settings`) shows two stacked sections:

- **Profile** — email (read-only; email change is out of scope) and the
  current timezone. The timezone is the only editable field.
- **Password** — current password, new password, confirm new password.

The page follows the "Calm Command Center" visual system and the
existing form patterns (`LoginForm`, `NewGoalDialog`).

## Acceptance Criteria

### AC-001 — Change timezone persists

Given a signed-in user on the Settings page
When they choose a valid timezone and save
Then the profile and session show the new timezone, and after a page
reload the stored profile still shows it (the change is server-side).

### AC-002 — Invalid timezone rejected

Given a signed-in user on the Settings page
When they submit an invalid timezone identifier
Then the page shows the server's `INVALID_TIMEZONE` message, the current
timezone is unchanged, and the session is untouched.

### AC-003 — Wrong current password

Given a signed-in user on the Settings page
When they submit a password change with an incorrect current password
Then the page shows the server's `invalid_credentials` message inline,
and the user remains signed in with the existing session.

### AC-004 — Successful password change ends the session

Given a signed-in user on the Settings page
When they submit a valid password change with the correct current
password
Then the local session is cleared and the user is returned to the login
screen, which shows a "password changed" success banner; the old refresh
token can no longer be used (server revoked it).

### AC-005 — Client-side password validation

Given a signed-in user on the Settings page
When they enter a new password shorter than 12 characters, or a confirm
value that does not match the new password
Then the form blocks submission with inline validation feedback before
any request is made.

### AC-006 — User isolation honored

Given any request made by the Settings page
When the request is inspected
Then it contains no userId in path, query, or body — only the Bearer
token.

### AC-007 — Mock mode available

Given `VITE_USE_MOCK_SETTINGS` is enabled
When the app runs without the backend
Then the Settings page renders and both operations behave with mock
responses.

### AC-008 — Server error surfaces error state

Given the backend is unreachable or returns 500
When the Settings page loads or a save is attempted
Then the existing error state renders with a working Retry action.

### AC-009 — Timezone change applies prospectively

Given a signed-in user who has Top 3 / daily-plan data recorded under
their old timezone
When they change their timezone
Then the Today page and date bucketing reflect the new timezone going
forward, and existing recorded dates are unchanged.

## Edge Cases

- Save button double-submit: requests are serialized per action; the
  button disables while in flight.
- Token expiry mid-change: the request triggers the silent-refresh
  interceptor; after a password change the refresh token is revoked, so
  any 401 lands on the session-expired handler and returns to login —
  the user is never stuck on a broken form.
- Reload after a timezone change: the persisted session carries the new
  timezone from the update response.
- Changing the timezone to one with a different day boundary: the date
  bucketing is computed server-side from the stored timezone (ADR-006);
  the client only re-renders "today" from the user's local date in the
  new zone.
- Multiple devices: a password change signs out the other devices
  (revoked refresh tokens) but the Settings page on the current device
  ends its own session deterministically (Rule 3).

## Out of Scope

- Email address change, name/avatar/profile fields.
- Account deletion.
- Password reset ("forgot password") flows.
- Two-factor authentication / additional login methods (ADR-004 defers
  OAuth and social login).
- Backend changes of any kind (new endpoints, changed DTOs, new error
  codes).
- Session-management UI (list/revoke devices).
- Notifications or other workspace preferences (the router's settings
  blurb mentions focus capacity — that is a separate future feature).

## Dependencies

- `docs/specs/users/user-management.md` — account and password rules.
- `docs/specs/api-integration.md` — silent refresh, error contract, mock
  toggles, user isolation.
- `docs/decisions/ADR-004-authentication-user-isolation.md` — token
  model, password-change revocation, identity rules.
- `docs/decisions/ADR-005-api-architecture.md` — endpoint conventions,
  structured errors.
- `docs/decisions/ADR-006-time-and-timezone.md` — timezone semantics and
  prospective application.
- Backend `UserController` / `UserService` (verified contract).

## Resolved Questions

1. **Password-change UX:** end the session immediately after success and
   redirect to `/login?password_changed=1`, where the login page shows a
   "password changed" banner. Deterministic, and the confirmation
   survives the redirect (no artificial delay on the Settings page).
2. **Timezone picker:** full IANA list with search, backed by
   `Intl.supportedValuesOf('timeZone')` (browser-native, always current,
   no bundled list). The browser-detected local zone is pinned first, a
   short common-zones group follows, then the full list grouped by
   region, each entry showing its UTC offset. Browsers without
   `Intl.supportedValuesOf` fall back to the detected local zone plus a
   small static fallback list.
3. **Mock toggle:** new `VITE_USE_MOCK_SETTINGS` (keeps the settings
   mock independent of the auth mock), default on in development and off
   in production.

## Change History

- Open Questions 1–3 resolved (password-change UX: immediate session end
  + login banner; timezone picker: `Intl.supportedValuesOf` full list
  with common group and UTC offsets; mock toggle: `VITE_USE_MOCK_SETTINGS`
  default on in dev). Added Page Layout, confirm-password rule,
  defense-in-depth timezone validation (Rule 5), and the
  `Intl.supportedValuesOf` fallback. Removed stale template artifacts.
  Status stays approved.
- Initial Draft created for the Account Settings page (Milestone 4
  route already reserved in the router).
