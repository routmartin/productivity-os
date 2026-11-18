# Plan 025: Personal Habit-Based Schedule Blueprint & Circadian Calibration

## Status
Approved by Human (2026-11-18)

---

## 1. Specification Reference

### Primary Behavioral Source of Truth
- [docs/specs/planning/daily-schedule-linkmap.md](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/specs/planning/daily-schedule-linkmap.md) (Proposed, Amended 2026-11-18)

### Acceptance Criteria in Scope
- **AC-004 (amended):** Bedtime Projection Calculation (calibrated to `23:20` target bedtime)
- **AC-009 (amended):** Personal Daily Blueprint Pre-population (15 recurring habits, 2 anchors, zero fake task entries)
- **AC-014 (new):** Personal Habit-Based Baseline Blueprint & Calibrated Phases (exact 15 baseline habits, 4 phase windows, uncompleted default state)

### Supporting Decisions and Constraints
- **ADR-001:** SDD Workflow (Specification before implementation; human approval gate)
- **ADR-002:** Technology Stack (Kotlin/Spring Boot 3 for `apps/api`; Vue 3/Pinia for `apps/web`; Swift/SwiftUI for `apps/ios`)
- **ADR-004:** User Isolation (All schedule habits and graph queries strictly scoped to authenticated user)
- **ADR-006:** Timezone Authority (Circadian schedule continuity maintained across calendar dates)

---

## 2. Architectural Decisions & Product Choices

### D1: Habit-Centric Blueprint vs Fake Activity Seeding
- **Context:**
  The legacy `seedDefaultBlueprint` in `ScheduleService.kt` seeded 5 arbitrary baseline habits and then invoked `seedDefaultEntriesForDate(userId, targetDate)`, injecting 9 dummy tasks and recharge entries ("Finish authentication architecture", "Build task dashboard layout", etc.) into `schedule_entries`.
  This produced an unrealistic schedule where users had to manually delete dummy tasks every day.
- **Decision:** **Eliminate `seedDefaultEntriesForDate` completely**.
  - The Daily Blueprint consists purely of the user's authentic habit-based routine in `schedule_habits` and boundary anchors (`anchor-wake` and `anchor-bedtime`).
  - No dummy tasks or recharge entries are injected into `schedule_entries`.
  - Schedule tasks are added intentionally by the user via the in-line `+ Add Step` action or task board, preserving a clean daily canvas.

### D2: Calibrated Circadian Phase Windows & Anchors
- **Context:**
  The default schedule previously assumed wake at `06:30` and bedtime at `22:30`. The user's actual daily rhythm runs from wake at `06:20` to bedtime at `23:20` (a clean 7-hour circadian sleep window).
- **Decision:** **Re-calibrate all phase boundaries and anchor constants**:
  - **Wake Anchor:** `06:20` (`anchor-wake`)
  - **Bedtime Anchor:** `23:20` (`anchor-bedtime`)
  - **Phase 1: Morning Activation (`morning`):** `06:20 – 10:00` (covers waking, run, grooming, and transit window to 09:30 arrive-work planning)
  - **Phase 2: Deep Focus Work (`deep-focus`):** `10:00 – 12:00` (covers 90m morning deep work session)
  - **Phase 3: Afternoon Momentum (`afternoon`):** `12:00 – 18:30` (covers lunch break, admin/meetings, afternoon deep work, short workout/breathwork break, and wrap-up)
  - **Phase 4: Bedtime Sanctuary (`bedtime`):** `20:00 – 23:20` (covers shower & dinner, hobby time, reading, skill learning, wind-down prep, and sleep target)

### D3: Unticked Initial State & Organic Habit Stacking
- **Context:**
  Previous mock data displayed several habits as pre-completed (`completed = true`, streak = 8..14), which gave a misleading impression of task completion for fresh days.
- **Decision:**
  - All seeded blueprint habits initialize with `completed = false` and `streak = 0`.
  - Streaks and 14-day history accumulate purely through actual user interactions (clicking the tick on the Serpentine Journey canvas).

### D4: Scope Allocation Across Repositories
- **Context:**
  Per human directive: *"Keep apps/ios code unchanged (iOS reads the graph from the backend API dynamically)"*.
- **Decision:**
  - **Backend (`apps/api`):** Overhaul `ScheduleEnums.kt`, `ScheduleService.kt`, and `ScheduleServiceTest.kt` to encode the 15 baseline habits, updated phase ranges, and anchor constants.
  - **Web Frontend (`apps/web`):** Update `createMockScheduleGraph()` in `scheduleStore.ts` and unit test assertions in `scheduleStore.spec.ts` to mirror the calibrated 15 habits and phase ranges.
  - **iOS (`apps/ios`):** Excluded from changes. iOS dynamically parses the `ScheduleGraphResponse` payload returned from `GET /api/v1/schedule/{date}`.

---

## 3. Agent Delegation Matrix

| Agent | Target Slice | Owned Files / Scope | Verification Command | Dispatch Brief |
| :--- | :--- | :--- | :--- | :--- |
| `@backend` | Slice 1: Backend Schedule Blueprint & Phase Calibration | `apps/api/src/main/kotlin/com/productivityos/schedule/domain/ScheduleEnums.kt`<br>`apps/api/src/main/kotlin/com/productivityos/schedule/service/ScheduleService.kt`<br>`apps/api/src/test/kotlin/com/productivityos/schedule/service/ScheduleServiceTest.kt`<br>`apps/api/src/test/kotlin/com/productivityos/schedule/ScheduleControllerTest.kt` | `./gradlew :apps:api:test --tests "com.productivityos.schedule.*"` | Update phase ranges to 06:20-10:00, 10:00-12:00, 12:00-18:30, 20:00-23:20; update WAKE_TIME to 06:20, TARGET_BEDTIME to 23:20; seed exactly 15 baseline habits in seedDefaultBlueprint; delete seedDefaultEntriesForDate; update unit tests |
| `@frontend` | Slice 2: Web Mock Schedule Graph & Test Parity | `apps/web/src/features/planning/scheduleStore.ts`<br>`apps/web/src/features/planning/__tests__/scheduleStore.spec.ts` | `pnpm --dir apps/web test:unit && pnpm --dir apps/web typecheck` | Update `createMockScheduleGraph` with 06:20 wake, 23:20 bedtime, updated phase ranges, 15 uncompleted baseline habits, 16 edges; update vitest assertions |
| `@code-reviewer` | Slice 3: Verification & SDD Compliance Audit | Full Git Diff across `apps/api`, `apps/web`, `docs/specs`, `docs/plans` | `./scripts/agent-review.sh` | Verify zero regression against spec AC-004, AC-009, AC-014; verify test suites pass; verify no iOS files modified |

---

## 4. Step-by-Step Implementation Tasks

### Step 1: Update Phase Windows in `ScheduleEnums.kt` & Constants in `ScheduleService.kt` (`apps/api`)
- **Files Affected:**
  - `apps/api/src/main/kotlin/com/productivityos/schedule/domain/ScheduleEnums.kt`
  - `apps/api/src/main/kotlin/com/productivityos/schedule/service/ScheduleService.kt`
- **Spec / AC:** `AC-014`
- **Detailed Action:**
  1. In `ScheduleEnums.kt`:
     - Update `SchedulePhaseId` enum definitions:
       ```kotlin
       MORNING(
           "morning",
           "Morning Activation",
           "Rise, hydrate, move & set daily direction",
           "06:20 – 10:00",
           "warning"
       ),
       DEEP_FOCUS(
           "deep-focus",
           "Deep Focus Work",
           "Uninterrupted creative flow on primary deliverables",
           "10:00 – 12:00",
           "accent"
       ),
       AFTERNOON(
           "afternoon",
           "Afternoon Momentum",
           "Review, collaboration, deep execution & wrap-up",
           "12:00 – 18:30",
           "blue"
       ),
       BEDTIME(
           "bedtime",
           "Bedtime Sanctuary",
           "Dinner, decompression, learning & sleep recovery",
           "20:00 – 23:20",
           "success"
       )
       ```
  2. In `ScheduleService.kt`:
     - Update companion object constants:
       ```kotlin
       companion object {
           const val WAKE_TIME = "06:20"
           const val TARGET_BEDTIME = "23:20"
           const val ANCHOR_WAKE_ID = "anchor-wake"
           const val ANCHOR_BEDTIME_ID = "anchor-bedtime"
       }
       ```
     - In `buildScheduleGraph()`:
       - Update `wakeAnchor`:
         - `time = WAKE_TIME` (`"06:20"`)
         - `targetTime = WAKE_TIME`
         - `durationMinutes = 10`
         - `order = 1`
       - Update `bedtimeAnchor`:
         - `time = TARGET_BEDTIME` (`"23:20"`)
         - `targetTime = TARGET_BEDTIME`
         - `subtitle = "Target $TARGET_BEDTIME · 7h Circadian Sleep Target"`
         - `durationMinutes = 420`
         - `order = 17`
- **Verification Command:** `./gradlew :apps:api:compileKotlin`

### Step 2: Overhaul `seedDefaultBlueprint` & Eliminate `seedDefaultEntriesForDate` (`apps/api`)
- **Files Affected:**
  - `apps/api/src/main/kotlin/com/productivityos/schedule/service/ScheduleService.kt`
- **Spec / AC:** `AC-009 (amended)`, `AC-014`
- **Detailed Action:**
  1. Remove private method `seedDefaultEntriesForDate(userId: UUID, date: LocalDate)`.
  2. In `getSchedule(userId: UUID, date: LocalDate)`:
     - Remove commented-out invocation of `seedDefaultEntriesForDate`.
     - Verify clean read of user's existing habits and entries.
  3. In `seedDefaultBlueprint(userId: UUID, date: LocalDate? = null)`:
     - Replace legacy 5 habits with the calibrated 15 baseline habits:
       - **Morning (Phase 1):**
         - `orderIndex = 2`: Title: "Deep Breaths & Hydration", Subtitle: "Kickstart metabolism & oxygenate brain", Icon: "drop.fill", TargetTime: "06:20", Duration: 10, Notes: "Full glass of water, 10 deep diaphragmatic breaths."
         - `orderIndex = 3`: Title: "Morning Run or Workout", Subtitle: "Cardio, mobility & morning energy", Icon: "figure.run", TargetTime: "06:30", Duration: 30, Notes: "Outdoor run or indoor workout to elevate heart rate and boost dopamine."
         - `orderIndex = 4`: Title: "Grooming & Get Ready: Shower, teeth, dress up", Subtitle: "Shower, brush teeth, dress up & prepare", Icon: "shower.fill", TargetTime: "07:00", Duration: 40, Notes: "Warm shower with cool rinse finish, brush teeth, prepare clothes."
         - `orderIndex = 5`: Title: "Arrive Work & Daily Task Planning", Subtitle: "Set up workspace & lock in daily task priorities", Icon: "list.bullet.clipboard", TargetTime: "09:30", Duration: 20, Notes: "Arrive at office/desk, review daily agenda, set Top 3 priorities."
       - **Deep Focus (Phase 2):**
         - `orderIndex = 6`: Title: "Morning Deep Work Session", Subtitle: "Uninterrupted focus on high-impact core priorities", Icon: "brain.head.profile", TargetTime: "10:00", Duration: 90, Notes: "No email, no Slack. 90 minutes of flow state on complex cognitive task."
       - **Afternoon (Phase 3):**
         - `orderIndex = 7`: Title: "Lunch Break & Reset: Eat, commute, relax / play game", Subtitle: "Nutritious lunch, commute, relax & recharge", Icon: "gamecontroller.fill", TargetTime: "12:00", Duration: 60, Notes: "Wholesome lunch, step away from screens or enjoy casual gaming/walk."
         - `orderIndex = 8`: Title: "Daily Review, Admin & Meetings", Subtitle: "Email review, admin coordination & syncs", Icon: "person.2.fill", TargetTime: "13:00", Duration: 60, Notes: "Address messages, attend team standups/syncs, clear paperwork."
         - `orderIndex = 9`: Title: "Afternoon Deep Work", Subtitle: "Second deep focus block for key deliverables", Icon: "flame.fill", TargetTime: "14:00", Duration: 120, Notes: "Two hours of deep execution on code, design, or architecture deliverables."
         - `orderIndex = 10`: Title: "Short Break: Light Workout & Breathwork", Subtitle: "Physical reset, stretching & parasympathetic breath", Icon: "figure.cooldown", TargetTime: "16:30", Duration: 30, Notes: "Stretch shoulders, walk around, 5 minutes physiological sigh or box breathing."
         - `orderIndex = 11`: Title: "Continue Work & Wrap-Up", Subtitle: "Close loops, tidy tasks & daily wrap-up", Icon: "briefcase.fill", TargetTime: "17:00", Duration: 90, Notes: "Close out open PRs/tickets, log daily notes, clear desk for tomorrow."
       - **Bedtime Sanctuary (Phase 4):**
         - `orderIndex = 12`: Title: "Shower & Dinner", Subtitle: "Evening shower and mindful dinner", Icon: "fork.knife", TargetTime: "20:00", Duration: 30, Notes: "Relaxing warm shower followed by a nutritious dinner; disconnect from work."
         - `orderIndex = 13`: Title: "Hobby Time", Subtitle: "Creative expression, gaming, or personal projects", Icon: "sparkles", TargetTime: "20:30", Duration: 60, Notes: "Spend uninterrupted time on personal hobbies, music, or creative play."
         - `orderIndex = 14`: Title: "Reading Time", Subtitle: "Physical book or quiet reading", Icon: "book.fill", TargetTime: "21:30", Duration: 30, Notes: "Read non-work literature or fiction in warm ambient light."
         - `orderIndex = 15`: Title: "Learn New Skill", Subtitle: "Dedicated self-improvement and study", Icon: "graduationcap.fill", TargetTime: "22:15", Duration: 50, Notes: "Focused study or practice session to build a new capability."
         - `orderIndex = 16`: Title: "Wind-Down & Tomorrow Prep", Subtitle: "Dim lights, prep clothing, calm central nervous system", Icon: "tshirt.fill", TargetTime: "23:05", Duration: 15, Notes: "Lay out clothes for tomorrow, dim bedroom lights, phone on airplane mode."
     - Save all 15 habits via `scheduleHabitRepository.saveAll(habits)`.
     - Remove invocation of `seedDefaultEntriesForDate`.
- **Verification Command:** `./gradlew :apps:api:compileKotlin`

### Step 3: Update Backend Unit Tests (`apps/api`)
- **Files Affected:**
  - `apps/api/src/test/kotlin/com/productivityos/schedule/service/ScheduleServiceTest.kt`
  - `apps/api/src/test/kotlin/com/productivityos/schedule/ScheduleControllerTest.kt`
- **Spec / AC:** `AC-004 (amended)`, `AC-009 (amended)`, `AC-014`
- **Detailed Action:**
  1. In `ScheduleServiceTest.kt`:
     - Update `seedDefaultBlueprint seeds 5 baseline habits and default entries when called directly`:
       - Rename to `seedDefaultBlueprint seeds 15 baseline habits and zero entries when called directly`.
       - Assert that `habitCaptor.value.size == 15`.
       - Verify presence of all 15 habit titles and correct phases.
       - Verify `entryRepository.saveAll(...)` is never called.
     - Replace failing test `fresh user accessing schedule seeds default entries but does not auto-seed habits`:
       - New test: `fresh user accessing schedule returns empty middle graph when no habits or entries exist`.
       - Asserts 2 nodes (wake anchor `06:20` and bedtime anchor `23:20`), 1 edge connecting them, 4 default phases, and `wakeTime == "06:20"`, `targetBedtime == "23:20"`.
     - Update bedtime calculation tests to reflect base bedtime `23:20`:
       - Overflow 30m -> projected bedtime `23:50` (instead of `23:00`).
     - Update anchor wake and bedtime string assertions (`"06:20"` and `"23:20"`).
  2. In `ScheduleControllerTest.kt`:
     - Update mock response constants for `wakeTime` (`"06:20"`) and `targetBedtime` (`"23:20"`).
- **Verification Command:** `./gradlew :apps:api:test --tests "com.productivityos.schedule.*"`

### Step 4: Update Web Mock Graph & Vitest Tests (`apps/web`)
- **Files Affected:**
  - `apps/web/src/features/planning/scheduleStore.ts`
  - `apps/web/src/features/planning/__tests__/scheduleStore.spec.ts`
- **Spec / AC:** `AC-004 (amended)`, `AC-009 (amended)`, `AC-014`
- **Detailed Action:**
  1. In `scheduleStore.ts`:
     - Update `createMockScheduleGraph()`:
       - `wakeTime: '06:20'`, `targetBedtime: '23:20'`, `projectedBedtime: '23:20'`, `overflowMinutes: 0`.
       - Phases:
         - `morning`: timeRange `'06:20 – 10:00'`
         - `deep-focus`: timeRange `'10:00 – 12:00'`
         - `afternoon`: timeRange `'12:00 – 18:30'`
         - `bedtime`: timeRange `'20:00 – 23:20'`
       - Nodes:
         - `anchor-wake`: time `'06:20'`, targetTime `'06:20'`, duration 10m, order 1.
         - 15 habit nodes matching the blueprint, with:
           - All initialized with `completed: false`, `streak: 0`, `history: generateHistory(0)`.
           - Icons mapped cleanly (`Droplets`, `Dumbbell`, `Target`, `Flame`, etc.).
         - `anchor-bedtime`: time `'23:20'`, targetTime `'23:20'`, duration 420m, order 17.
       - Edges:
         - 16 sequential, prerequisite, and phase edges linking node 1 to node 17.
         - All edges initially `active: false`.
  2. In `scheduleStore.spec.ts`:
     - Update tests relying on previous mock node IDs (`task-top1` -> replace with updated test node or update assertion).
     - Update initial bedtime projection expectations to align with `23:20` target bedtime and new mock topology.
- **Verification Command:** `pnpm --dir apps/web test:unit && pnpm --dir apps/web typecheck`

### Step 5: Regression & Build Verification
- **Verification Commands:**
  - Backend: `./gradlew :apps:api:test`
  - Web: `pnpm --dir apps/web test:unit && pnpm --dir apps/web typecheck`
  - iOS: `swift test --package-path apps/ios` (verify zero regressions on untouched iOS codebase)

---

## 5. Traceability Matrix

| Acceptance Criteria | Description | Target Slices / Steps | Verifying Tests | Status |
| :--- | :--- | :--- | :--- | :--- |
| **AC-004 (amended)** | Bedtime Projection Calculation (calibrated to `23:20` target bedtime) | Step 1, Step 3, Step 4 | `ScheduleServiceTest`, `BedtimeProjectionEngineTest`, `scheduleStore.spec.ts` | Pending Implementation |
| **AC-009 (amended)** | Personal Daily Blueprint Pre-population (15 recurring habits, 2 anchors, zero fake tasks) | Step 2, Step 3 | `ScheduleServiceTest.kt` | Pending Implementation |
| **AC-014 (new)** | Personal Habit-Based Baseline Blueprint & Calibrated Phases | Step 1, Step 2, Step 3, Step 4 | `ScheduleServiceTest.kt`, `ScheduleControllerTest.kt`, `scheduleStore.spec.ts` | Pending Implementation |

---

## 6. Verification & QA Matrix

| Area | Verification Mechanism | Target Command | Acceptance Threshold |
| :--- | :--- | :--- | :--- |
| **Backend Unit Tests** | Gradle test runner | `./gradlew :apps:api:test --tests "com.productivityos.schedule.*"` | All tests pass (0 failures) |
| **Backend Full Test Suite** | Gradle full test suite | `./gradlew :apps:api:test` | All tests pass |
| **Web Unit Tests** | Vitest test runner | `pnpm --dir apps/web test:unit` | All tests pass (72/72+) |
| **Web Type Safety** | Vue TypeScript compiler | `pnpm --dir apps/web typecheck` | 0 errors |
| **iOS Untouched Parity** | Swift Package Manager | `swift test --package-path apps/ios` | 0 build errors; all 201+ tests pass |
| **Code Review** | Review script | `./scripts/agent-review.sh` | PASS (Verdict: APPROVED) |

---

## 7. Pre-Implementation Decisions (Pending Human Confirmation)

- **D1: Elimination of `seedDefaultEntriesForDate`**
  - **Proposal:** Permanently remove automatic injection of fake task and recharge entries into `schedule_entries`.
  - **Benefit:** Daily schedule starts cleanly populated only with the user's anchors and habits.
  - **Status:** PENDING HUMAN APPROVAL.
- **D2: Circadian Boundary Times (06:20 Wake / 23:20 Bedtime)**
  - **Proposal:** Calibrate anchors to `06:20` wake and `23:20` bedtime, providing a realistic 7h circadian sleep window.
  - **Status:** PENDING HUMAN APPROVAL.
- **D3: Unticked Initial State (`completed = false`, `streak = 0`)**
  - **Proposal:** Seed all 15 habits as uncompleted by default so users track actual habit completions day by day.
  - **Status:** PENDING HUMAN APPROVAL.
- **D4: Exclude `apps/ios` from Code Modifications**
  - **Proposal:** Retain `apps/ios` unchanged per human directive; iOS dynamically renders graph JSON from backend API.
  - **Status:** PENDING HUMAN APPROVAL.

---

## 8. Out of Scope for This Plan

- Modifying `apps/ios` source code or iOS tests (iOS reads schedule graph dynamically from backend).
- Modifying PostgreSQL database schema or Flyway migrations (existing schema accommodates all fields).
- External task backlog or calendar integration (Schedule remains decoupled per architecture principles).

---

## 9. Change History

- **2026-11-18:** Initial Draft created for Plan 025 ("Personal Habit-Based Schedule Blueprint & Circadian Calibration"). Establishes 5 vertical implementation tasks across Backend and Web slices, 4 Pre-Implementation Decisions D1–D4, and full traceability matrix against amended `AC-004`, amended `AC-009`, and new `AC-014`.
