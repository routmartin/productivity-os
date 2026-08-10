# ADR-006: Time and Timezone Handling

## Status

Proposed

## Context

Time semantics are load-bearing in this product. The specifications require:

- Calendar days defined as 00:00:00–23:59:59 in the user's configured timezone
  (Daily Top 3 Constraint 1).
- Completion timestamps recorded as absolute instants, with calendar-day
  attribution in the user's configured timezone (Task Management Constraint 3).
- Historical completion state frozen at the end of each calendar day (Daily
  Top 3 Rule 15).
- Existing records remaining bound to their original calendar date when the
  user changes timezone (Daily Top 3 AC-023).
- Server receipt time as the authority for last-write-wins conflict resolution
  (Daily Top 3 Constraint 3, AC-024).

The stack provides the building blocks: `java.time` on Kotlin/Spring Boot
(ADR-002), `timestamptz` persistence (ADR-003), and ISO-8601 API contracts
(ADR-005).

Known dependency: the user's configured timezone presumes a user profile
carrying that setting. No user/profile specification exists yet; this ADR
assumes one profile field and does not specify profile management.

## Decision Drivers

- Historical correctness: stored facts must survive timezone changes and
  travel.
- Specification fidelity: calendar-day behavior must match the approved
  specifications exactly.
- Testability: time-dependent acceptance criteria must be deterministically
  testable.
- Simplicity: delegate all timezone complexity to proven libraries; no custom
  arithmetic.

## Options

### Persisted timestamp type

- Option A — `timestamptz` storing UTC instants
- Option B — `timestamp` storing user-local wall-clock time
- Option C — `timestamp` plus a separate offset/zone column

### Domain time representation

- Option A — `java.time.Instant` for moments, `LocalDate` for date-only
  concepts, `ZoneId` for interpretation
- Option B — `OffsetDateTime` everywhere
- Option C — Legacy `java.util.Date` / `Calendar` or Joda-Time

### Source of "today" and receipt time

- Option A — Server clock, via an injectable `Clock`
- Option B — Client-supplied dates and timestamps

## Decision

1. **Persist all timestamps as UTC instants** using PostgreSQL `timestamptz`.
2. **Domain/application code uses `java.time.Instant`** for moments in time.
3. **The user profile stores an IANA timezone identifier** (for example
   `Asia/Phnom_Penh`), validated against the IANA timezone database.
4. **Calendar dates are interpreted in the user's configured timezone.**
5. **Calendar-day boundaries are 00:00:00 through 23:59:59 local** — computed
   as the instants `LocalDate.atStartOfDay(zone)` inclusive and
   `plusDays(1).atStartOfDay(zone)` exclusive, never by hand-written
   arithmetic.
6. **`LocalDate` is used for date-only concepts**, such as Daily Plan date and
   Top 3 date.
7. **Never persist a local wall-clock timestamp without its timezone context.**
8. **API timestamps use ISO-8601 UTC representation** (for example
   `2026-08-10T17:00:00Z`).
9. **API date-only fields use ISO-8601 `YYYY-MM-DD`.**
10. **Existing historical records remain bound to their original calendar
    date** if the user later changes timezone; attributed dates are never
    recomputed retroactively.
11. **Server receipt time is authoritative** for server-side ordering and
    conflict resolution where required (last-write-wins).
12. **DST and timezone-rule behavior is delegated to Java's IANA timezone
    support** (`ZoneId`/`ZoneRules`).
13. **No custom timezone arithmetic** anywhere in the codebase.

## Storage Model

- `timestamptz` columns for every moment-in-time fact: creation, completion,
  cancellation, deletion, restoration, and server receipt timestamps.
- `date` columns for date-only concepts (Top 3 date, Daily Plan date). The
  date is attributed once, at write time, by converting the current instant
  with the user's timezone, and is immutable thereafter.
- User profile column for the IANA timezone identifier.

## Calendar-Day Interpretation

- A single domain-level time component performs all conversions:
  `Instant -> LocalDate` via `instant.atZone(userZone).toLocalDate()`, and day
  windows via start-of-day instants as described in Decision 5.
- "Today" is derived per request from the server clock and the user's
  configured timezone.
- End-of-day freezing (Daily Top 3 Rule 15) is evaluated against the
  23:59:59 local boundary of the relevant date in the user's timezone.

## Timezone Changes

- A timezone change applies prospectively only: new date attributions use the
  new timezone.
- Stored `date` values and historical frozen views are never recomputed;
  records stay bound to their original calendar date (Daily Top 3 AC-023).
- No migration or rewrite of historical timestamps occurs on timezone change.

## DST Considerations

- All DST gaps, overlaps, and offset changes are handled by `ZoneRules`; local
  days may legitimately be 23 or 25 hours long, and this is correct by
  definition.
- Day-boundary computation via `LocalDate.atStartOfDay(zone)` resolves the
  correct instant even on transition days.
- Timezone rule updates arrive via JDK/IANA tz database updates; the
  application stores identifiers, not rules.

## API Representation

- Timestamps: ISO-8601 UTC instants (offset `Z`).
- Date-only fields: ISO-8601 calendar dates (`YYYY-MM-DD`).
- Clients render wall-clock times using the user's configured timezone,
  available from their profile; the API never returns bare local times.

## Server Timestamps

- The server clock is the sole authority for receipt time (last-write-wins
  ordering), completion time, deletion time, and all other recorded instants.
  Client clocks are never trusted.
- All time access goes through an injectable `java.time.Clock`, so
  time-dependent acceptance criteria can be tested deterministically.

## Consequences

### Positive

- Stored facts are absolute and immune to timezone changes and travel.
- Specification calendar-day behavior is implementable exactly as written,
  including frozen history.
- Deterministic time-dependent tests via the injectable clock, supporting
  acceptance-criteria traceability.
- All DST complexity is delegated to maintained IANA data.

### Negative

- Two representations (`Instant` and `LocalDate`) require developer discipline
  about which concept applies.
- Every date-attributing write needs the user's timezone, coupling such writes
  to the (not yet specified) user profile.
- Timezone rule updates are an operational dependency of the JDK/runtime.
- Queries mixing instants and attributed dates need care to stay consistent
  with the user's timezone.

## Rejected Alternatives

- **User-local `timestamp` storage:** corrupts under timezone changes and
  travel; violates the calendar-day constraints.
- **`OffsetDateTime` everywhere:** a fixed offset is not a timezone; DST rules
  are lost and future offsets can be wrong.
- **Client-supplied dates/timestamps:** untrusted clocks would break
  last-write-wins and recorded-time integrity.
- **Legacy `Date`/`Calendar` or Joda-Time:** superseded by `java.time`; no
  reason to adopt weaker APIs.
- **Custom timezone arithmetic or a custom time service:** error-prone and
  unnecessary given IANA support in the platform.

## Related Specifications and ADRs

- `docs/decisions/ADR-001-sdd-workflow.md`
- `docs/decisions/ADR-002-technology-stack.md`
- `docs/decisions/ADR-003-database-persistence.md`
- `docs/decisions/ADR-004-authentication-user-isolation.md`
- `docs/decisions/ADR-005-api-architecture.md`
- `docs/architecture/system.md`
- `docs/architecture/domain.md`
- `docs/specs/tasks/task-management.md` (Constraint 3)
- `docs/specs/planning/daily-top-three.md` (Constraints 1 and 3, Rule 15,
  AC-023, AC-024)
