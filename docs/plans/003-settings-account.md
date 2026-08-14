# Plan: Account Settings

## Status

Draft — the governing specification
(`docs/specs/users/account-settings.md`) is Draft. Implementation must
not proceed until the spec is Approved and the pre-implementation
decisions are resolved.

## Specification

Primary behavioral source of truth:

- `docs/specs/users/account-settings.md` (Draft)

Acceptance criteria in scope:

- AC-001 change timezone persists
- AC-002 invalid timezone rejected
- AC-003 wrong current password
- AC-004 successful password change ends the session
- AC-005 client-side password validation
- AC-006 user isolation honored client-side
- AC-007 mock mode available
- AC-008 server error surfaces error state
- AC-009 timezone change applies prospectively

Supporting decisions and constraints:

- ADR-004 — token model, password-change revocation, isolation rules
- ADR-005 — URL conventions, error model
- ADR-006 — timezone semantics, prospective application
- `docs/specs/users/user-management.md` — account and password rules
- `docs/specs/api-integration.md` — silent refresh, error contract,
  mock toggles (the Settings page builds on its shared client)

## Architecture

The Settings page is a new feature module (`features/settings/`) using
the existing shared pieces:

- `lib/api/client.ts` — `apiClient` with silent refresh and structured
  `ApiError` (already implemented, plan 002 Step 1).
- `features/auth/store.ts` — owns the session (user profile +
  accessToken) and `updateProfile`-style local mutation; the settings
  module updates it, it does not own a second copy of the profile.
- `app/router` — the `/settings` route already exists
  (ComingSoonPage, `implemented: false`); this plan implements the page
  and flips the flag.
- `components/ui/*` and `components/shared/*` — existing input,
  button, empty/error/skeleton primitives.

Modules introduced or changed:

- `features/settings/api.ts` + `types.ts` — new (changePassword,
  changeTimezone)
- `features/settings/store.ts` — new (per-feature state + mock toggle)
- `pages/SettingsPage.vue` — new
- `app/router/index.ts` — point `/settings` at SettingsPage
- `features/auth/store.ts` — small extension: update the persisted
  profile from a settings response (e.g. `setTimezone`)

## Step 1 — Settings API module + shared types

- **Files/modules:** `features/settings/api.ts` (new),
  `features/settings/types.ts` (new)
- **Spec/AC:** AC-001–AC-009 (foundation)
- **Behavior:**
  - `changePassword(currentPassword, newPassword)` →
    `PUT /api/v1/users/password` with
    `{ currentPassword, newPassword }` → `UserResponse` (reuse
    `UserProfile` from `features/auth/types.ts`).
  - `changeTimezone(timezone)` → `PUT /api/v1/users/timezone` with
    `{ timezone }` → `UserResponse`.
  - Both go through `apiClient` (Bearer token, silent refresh, error
    model). No userId is ever sent (AC-006).
- **Dependencies:** plan 002 Step 1 (client) + Step 2 (types).
- **Tests:**
  - Request bodies contain exactly `currentPassword`/`newPassword` and
    `timezone` — no userId (AC-006).
  - Mock 401 `invalid_credentials` → `ApiError` with that code/message
    (AC-003).
  - Mock 400 `INVALID_TIMEZONE` and 400 `VALIDATION_ERROR` → codes
    surface (AC-002, AC-005).
- **Risks/ambiguities:** mock mode follows spec Open Question 3
  (`VITE_USE_MOCK_SETTINGS`).

## Step 2 — Settings store + auth profile update

- **Files/modules:** `features/settings/store.ts` (new),
  `features/auth/store.ts` (edit)
- **Spec/AC:** AC-001, AC-003, AC-004, AC-009
- **Behavior:**
  - The settings store keeps per-form state (current password, new
    password, selected timezone, submit/error state) and calls the API
    module; it owns no copy of the profile.
  - On a successful timezone change, the store updates the auth
    session's `user.timezone` from the response and persists it
    (`saveSession`) — profile updates survive reload (AC-001).
  - On a successful password change, the store calls the session-end
    path: clear the session and redirect to `/login` (AC-004) — per
    spec Rule 3, no silent-refresh attempt.
- **Dependencies:** Step 1.
- **Tests:**
  - Timezone change → auth store profile updated + persisted
    (AC-001/AC-009).
  - Password change success → session cleared + login redirect
    (AC-004).
  - Wrong current password → error message set, session intact
    (AC-003).
- **Risks/ambiguities:** the session-end path must reuse the existing
  clear-and-redirect logic (`clearSession` + router push) so it stays
  consistent with `onSessionExpired`.

## Step 3 — Settings page UI

- **Files/modules:** `pages/SettingsPage.vue` (new),
  `app/router/index.ts` (edit)
- **Spec/AC:** AC-001–AC-009
- **Behavior:**
  - Two sections: **Profile** (email, current timezone — read-only
    until edited) and **Password** (current, new, confirm).
  - Timezone: searchable IANA list (Open Question 2) with the current
    value preselected; saves via the store.
  - Password: new password input with client-side length validation
    (≥ 12, AC-005) and a confirm field that must match; wrong current
    password shows the server message inline (AC-003).
  - Loading skeleton while the page mounts; error state with Retry when
    the backend is unreachable (AC-008); disabled submit while in
    flight (double-submit protection).
  - Router: point `/settings` at `SettingsPage` and set
    `implemented: true`.
- **Dependencies:** Step 2.
- **Tests:** component-level checks: invalid password blocks submit
  (AC-005); wrong-current-password error renders inline; success state
  per AC-004; error state with retry (AC-008).
- **Risks/ambiguities:** keep the page aligned with the "Calm Command
  Center" visual system and existing form patterns
  (`NewGoalDialog`, `LoginForm`).

## Step 4 — Mock mode

- **Files/modules:** `features/settings/api.ts` (edit)
- **Spec/AC:** AC-007
- **Behavior:** behind `VITE_USE_MOCK_SETTINGS` (default on), the API
  module returns mock `UserResponse`s (mirroring backend validation
  codes) with latency, so the page is reviewable without the backend.
- **Dependencies:** Step 1.
- **Tests:** toggle on → settings renders and operates with no backend;
  toggle off → real endpoints called.
- **Risks/ambiguities:** mock validation must mirror backend codes
  (`invalid_credentials`, `INVALID_TIMEZONE`, `VALIDATION_ERROR`) so
  error paths are reviewable too.

## Step 5 — End-to-end verification

- **Files/modules:** none new.
- **Spec/AC:** all.
- **Behavior:** run the full stack, sign in, change the timezone,
  reload and confirm the profile persists (AC-001), verify the Today
  date bucketing follows the new zone (AC-009), attempt a wrong-current-
  password change (AC-003), then a valid one and confirm return to
  login and that the old session cannot be restored (AC-004); stop the
  backend to verify the error state (AC-008); test the mock toggle
  (AC-007).
- **Dependencies:** Steps 1–4.
- **Tests:** manual checklist mapped to AC-001 through AC-009.
- **Risks/ambiguities:** after a real password change the user must
  log in again with the new password; verify the refresh cookie was
  cleared/revoked.

## Tests

Traceability matrix:

- AC-001, AC-009 → Step 2 store tests + manual reload check
- AC-002 → Step 1 API tests (`INVALID_TIMEZONE`) + manual check
- AC-003 → Step 1 API tests + Step 2 store test + Step 3 UI check
- AC-004 → Step 2 store test (session cleared, redirect) + manual
- AC-005 → Step 3 component test (submit blocked) + Step 1 API test
  (`VALIDATION_ERROR` fallback)
- AC-006 → Step 1 request-body assertion (no userId)
- AC-007 → Step 4 toggle tests
- AC-008 → Step 3 component test + manual backend-down check

## AC Status (spec-sync drift check, 2026-08-14)

Per `docs/specs/users/account-settings.md` and the spec-sync workflow.
No implementation exists yet (spec is Draft; pre-implementation decisions
D2–D4 open), so every AC is recorded NOT VERIFIED — planned work, not
drift. No FAIL, UNREACHABLE, or intended-change items; no spec amendment
needed.

- AC-001 through AC-009 → NOT VERIFIED (no implementation; Steps 1–5 pending)

## Verification

Before reporting completion (per AGENTS.md):

1. All in-scope acceptance criteria pass (automated where possible,
   manual checklist otherwise).
2. `vue-tsc` and `eslint` pass.
3. No unrelated changes introduced (diff review).
4. Completion report includes: summary, specification references, files
   changed, AC pass/fail evidence, deviations, risks, follow-ups.

## Pre-Implementation Decisions (must be resolved first)

- **D1:** the spec `docs/specs/users/account-settings.md` must be
  **Approved** before implementation starts (SDD workflow, ADR-001).
- **D2 (spec Open Question 1):** after a successful password change,
  end the session immediately and return to login (recommended), or
  keep the user signed in until the next 401? Backend behavior is fixed
  either way (all refresh tokens revoked).
- **D3 (spec Open Question 2):** timezone picker — full IANA list with
  search or a curated subset?
- **D4 (spec Open Question 3):** mock toggle name —
  `VITE_USE_MOCK_SETTINGS` or reuse `VITE_USE_MOCK_AUTH`.

## Out of Scope for This Plan

- Backend changes of any kind (both endpoints exist and are fixed).
- Email change, profile fields, account deletion, password reset.
- Session-management UI (device list/revocation).
- OAuth/social login.
- Other settings categories (the router's "daily focus capacity"
  blurb is a separate future feature).

## Change History

- Initial plan created against `docs/specs/users/account-settings.md`
  (Draft).
- Spec-sync drift check (2026-08-14): all ACs recorded NOT VERIFIED — no
  implementation yet; no drift found; no spec amendment.
