# User Management

## Status

Approved

## Problem

The system is multi-user: every domain object belongs to exactly one user, and
users must only ever see their own data. That requires a defined way to create
an account, prove identity, stay signed in across devices, and end sessions —
without which the isolation rules in Task Management and the per-user
associations in Daily Top 3 cannot be satisfied.

## Goal

Provide the minimal account behavior the product needs: registration, login,
session continuity across devices, logout, password security, a per-user
timezone, and strict user isolation.

## User Story

As a user, I want to create a personal account, sign in on any of my devices,
and sign out, so that my productivity data is mine alone and available wherever
I work.

## Behavior

- A person registers with an email address and a password. Email addresses are
  unique per account, compared case-insensitively.
- A registered user logs in with their email and password. Failed logins
  receive a generic error that does not reveal whether the email is
  registered.
- A logged-in user stays signed in on that device without re-entering their
  password, until the session expires or is ended.
- A user can be signed in on multiple devices at once; each device has an
  independent session.
- Logging out ends the session on that device only.
- Changing the password ends all other sessions; the user must sign in again
  on other devices.
- Each account has a timezone (IANA identifier) used to interpret calendar
  days. It may be provided at registration and changed later; it defaults to
  UTC when not provided.
- After repeated failed login attempts, further attempts are temporarily
  limited.
- Passwords are never stored or transmitted in plaintext and never appear in
  logs or error messages.

## Rules

1. An account is identified by exactly one email address. Email uniqueness is
   case-insensitive.
2. A password must be at least 12 characters. No composition rules (required
   character classes) and no forced password rotation are imposed.
   (Resolved — see Resolved Questions.)
3. Passwords must be stored only as memory-hard password hashes. The hashing
   algorithm is an architecture decision (ADR-004).
4. Authentication is by email and password only. No social or external login
   exists in this version.
5. Successful login establishes a session on that device. Sessions are
   independent per device.
6. A session continues across application restarts without re-entering the
   password, until it expires or is revoked. Session mechanics (tokens,
   rotation, reuse detection) are defined by ADR-004.
7. Logout ends the session on the current device and does not affect sessions
   on other devices.
8. Changing the password revokes all sessions. The current session may be
   re-established with the new password; all other devices must sign in again.
9. The account timezone is an IANA timezone identifier (for example
   `Asia/Phnom_Penh`). When not provided at registration it defaults to UTC.
10. The timezone is used to interpret calendar days (00:00:00–23:59:59 local).
    Changing it applies prospectively and never rewrites historical date
    attributions (per ADR-006 and Daily Top 3 AC-023).
11. A user's identity in any operation is derived from their authenticated
    session, never from client-supplied identifiers (per ADR-004).
12. A user can only access their own account and their own domain data. There
    is no anonymous access to domain data.
13. Repeated failed login attempts trigger temporary limitation of further
    attempts. Exact thresholds are not product-specified (see Resolved
    Questions).
14. Registering with an already-registered email is rejected with feedback
    that the email is unavailable. (See Resolved Questions for the
    enumeration trade-off.)

## Constraints

1. Authentication, session tokens, and identity propagation follow ADR-004
   (Spring Security, short-lived access tokens, rotating server-side refresh
   tokens, security-context identity). This specification does not redefine
   them.
2. Time interpretation, storage, and DST behavior follow ADR-006.
3. API representations and error shapes follow ADR-005.
4. Credentials and session records are persisted per ADR-003.
5. Authentication and session behavior must work without any AI component.

## Acceptance Criteria

### AC-001 — Registration

Given no account exists for an email address,
when a person registers with that email and a valid password,
then an account is created and the user can log in with those credentials.

### AC-002 — Duplicate email rejected

Given an account exists for an email address,
when a registration is attempted with the same email in any letter casing,
then the registration is rejected and the user is informed that the email is
unavailable.

### AC-003 — Password minimum length enforced

Given a registration or password change,
when the password is shorter than 12 characters,
then the operation is rejected and the user is informed of the requirement.

### AC-004 — Passwords are never stored in plaintext

Given a registered account,
when the stored credential record is inspected,
then it does not contain the password and cannot be reversed to it.

### AC-005 — Successful login

Given a registered account,
when the user logs in with the correct email and password,
then an authenticated session is established on that device.

### AC-006 — Wrong password

Given a registered account,
when the user logs in with an incorrect password,
then access is denied with a generic error that does not reveal whether the
email is registered.

### AC-007 — Unknown email

Given no account exists for an email address,
when a login is attempted with it,
then access is denied with the same generic error as a wrong password.

### AC-008 — Multi-device sessions

Given a user signed in on device A,
when the user signs in on device B,
then both sessions are valid and independent.

### AC-009 — Session continuity

Given a signed-in session,
when the user returns to the application after closing it,
then the user is still signed in without re-entering the password, as long as
the session has not expired or been revoked.

### AC-010 — Logout affects only the current device

Given a user signed in on devices A and B,
when the user logs out on device A,
then device A is signed out and device B remains signed in.

### AC-011 — Password change revokes other sessions

Given a user signed in on devices A and B,
when the user changes the password on device A,
then the session on device B is no longer valid and signing in on device B
requires the new password.

### AC-012 — Default timezone

Given a registration that provides no timezone,
when the account is created,
then the account timezone is UTC.

### AC-013 — Timezone provided at registration

Given a registration that provides a valid IANA timezone identifier,
when the account is created,
then the account timezone is set to that identifier; an invalid identifier is
rejected.

### AC-014 — Timezone changes are prospective

Given an account with existing dated records,
when the user changes their timezone,
then previously attributed calendar dates are unchanged and new attributions
use the new timezone.

### AC-015 — Identity comes from the session

Given an authenticated session for user A,
when a request attempts to act as another user via a client-supplied
identifier,
then the attempt is not honored; the operation applies to user A or is
rejected.

### AC-016 — No anonymous access

Given no authenticated session,
when domain data is requested,
then access is denied.

### AC-017 — Repeated failures are limited

Given repeated failed login attempts for an account,
when the failures exceed the configured threshold,
then further attempts are temporarily rejected regardless of correctness.

## Edge Cases

- Registering with the same email in different casing is a duplicate (Rule 1,
  AC-002).
- Returning to the app after the session has fully expired requires a fresh
  login (Rule 6).
- Using a session after logout on the same device is rejected (Rule 7,
  AC-010).
- A reused or invalidated session credential requires re-authentication (per
  ADR-004 reuse detection).
- Changing the timezone does not move existing records to different calendar
  dates (Rule 10, AC-014).
- An unrecognized timezone identifier is rejected (AC-013).

## Dependencies

- ADR-004 (authentication and user isolation architecture).
- ADR-006 (time and timezone handling).
- ADR-005 (API error model used by the feedback rules).
- ADR-003 (persistence of accounts and session records).
- `docs/architecture/domain.md` (User owns all domain data).
- Task Management specification (domain-level isolation Rules 1, 6, 7 rely on
  the identity defined here).
- Daily Top 3 specification (selections are associated with user and date).

## Out of Scope

- Email verification.
- Password reset / "forgot password" flows.
- Account deletion, deactivation, or suspension.
- Profile management beyond the timezone field.
- OAuth/social login (per ADR-004) and multi-factor authentication.
- Roles, permissions, teams, or any sharing between users.
- Display name, avatar, and other profile attributes.

## Resolved Questions

- **Password policy:** Minimum 12 characters. No composition rules (required
  character classes). No forced password rotation. Confirmed as specified.
- **Duplicate registration feedback:** Returns 409 EMAIL_TAKEN with "email
  unavailable" feedback. Accepts the enumeration trade-off — distinct from
  login which never reveals whether an email is registered.
- **Rate-limit thresholds:** 5 failed login attempts per email within a
  15-minute window triggers a 15-minute lockout for that email. Application-level
  in-memory tracking; no dedicated infrastructure required for V1.
- **Registration auto-login:** Registration does not sign the user in. An
  explicit login is required afterward. Registration returns 201 with user
  info only.
- **Email verification and password reset:** Deferred beyond V1. Both require
  email sending infrastructure which does not exist. Revisit when operational
  complexity is justified (Phase 3+).

## Change History

- Promoted to Approved: an implementation exists (auth vertical slice,
  plan 001), all rules are load-bearing in production code, and
  `docs/specs/users/account-settings.md` (approved) depends on it for
  account and password rules.
- Resolved all 5 open questions: confirmed 12-char minimum password policy,
  409 EMAIL_TAKEN for duplicate registration (accepting enumeration trade-off),
  5-attempts/15-min rate limit with 15-min lockout, no auto-login after
  registration, email verification and password reset deferred beyond V1.
  Status changed to Proposed.

- Initial draft created to close Gap G0 / decision D2 of implementation plan
  `docs/plans/001-auth-task-vertical-slice.md`, using ADR-004 and ADR-006 as
  architecture sources of truth.
