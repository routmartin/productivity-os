# Review: Daily Schedule Link-Map Backend Vertical Slice (Plan 010)

## Verdict

**PASS**

---

## Critical
*None.*

---

## High
*None.*

---

## Medium
- **Domain Entity Transformation Pattern (ADR-007)**: In `ScheduleService.kt`, `ScheduleHabitEntity` and `ScheduleEntryEntity` are mapped directly to `ScheduleNodeDTO` rather than routing through domain classes (`ScheduleHabit`, `ScheduleEntry`) with explicit `toDomain()` extension methods. While all domain calculations (`BedtimeProjectionEngine`, `HabitStreakCalculator`) are decoupled and pure Kotlin without framework dependencies, aligning entity mapping with other modules' `toDomain()` conventions in a future refactor will increase codebase consistency.

---

## Low
- **Repository Optimization**: In `ScheduleHabitRepository`, adding a compound index or explicit `countByUserIdAndDeletedAtIsNull` method avoids any potential table scan overhead during user initialization checks.

---

## Correct
- **Acceptance Criteria Verification (AC-B01 to AC-B10)**: All 10 acceptance criteria defined in `docs/plans/010-backend-schedule-slice.md` and `docs/specs/planning/daily-schedule-linkmap.md` are completely implemented and verified by 25 dedicated unit and mock MVC integration tests.
- **Security & User Isolation (ADR-004)**: All repository queries, habit toggles, step insertions, and deletions are strictly scoped to `currentUser.id()`. Foreign-user access throws `ScheduleNodeNotFoundException` mapping to standard `404 Not Found` without disclosing resource presence.
- **Architecture & Layering (ADR-002, ADR-007)**: ArchUnit test `schedule_module_depends_only_on_user_and_shared_packages` passes (11/11 rules), confirming the schedule domain has zero coupling to `task`, `project`, `goal`, `focus`, or `auth`.
- **Database & Flyway Migration (ADR-003)**: `V15__habits_and_schedule.sql` adheres strictly to PostgreSQL conventions with UUID primary keys, user-scoped foreign keys with cascading deletes, `TIMESTAMPTZ` instant columns, and unique constraints (`uq_habit_occurrence_user_habit_date`).
- **Timezone Compliance (ADR-006)**: Uses `UserTimezoneService.today(userId)` for user-local date defaults and injectable `Clock.instant()` for UTC instants.
- **Client Contract Parity**: API contracts match `apps/web/src/features/planning/types.ts` and `apps/ios/ProductivityOS/Core/Services/ScheduleService.swift`.

---

## Recommended changes
1. *(Follow-up)* Add `toDomain()` helper extensions on `ScheduleHabitEntity` and `ScheduleEntryEntity` to mirror the entity-to-domain mapping seen in `task` and `project` modules.
