# Weekly Review & Progress Analytics

## Status

Proposed

---

## Problem

Productivity tools often suffer from an "execution without reflection" trap: users log tasks, track habits, and time focus sessions, yet lack systemic feedback on whether their planning matches reality. Without deliberate weekly closure:
1. **Planning Optimism Bias:** Users over-commit during daily planning without knowing their historical task completion velocity.
2. **Effort Fragmentation:** Users cannot readily see where their focused hours were actually allocated across strategic projects versus reactive inbox work.
3. **Circadian Drift:** Slip in evening routines and bedtime overflow accumulates across the week unnoticed, degrading next-day energy.
4. **Lack of Behavioral Learning:** Insights are lost if qualitative reflection (what worked, what failed, what to adjust) is disconnected from objective operational telemetry.

---

## Goal

Provide a structured, end-of-week **Weekly Review & Progress Analytics** engine that unifies objective behavioral metrics with qualitative reflection. The feature helps users:
1. **Resolve Week Boundaries Accurately:** Compute weekly timeframes in the user's configured IANA timezone per ISO-8601 (Monday `00:00:00` to Sunday `23:59:59.999999`).
2. **Aggregate Multidimensional Telemetry:** Roll up completed tasks vs planned commitments, focus session minutes by project, habit streak consistency, and circadian bedtime alignment.
3. **Guide the Weekly Review Ritual:** Provide a calm, step-by-step reflection wizard (Wins, Blockers, Adjustments, Satisfaction score).
4. **Preserve Historical Ground Truth:** Freeze review analytics into permanent, immutable historical records upon completion.
5. **Visualize Multi-Week Trajectories:** Present 4-week rolling behavioral trend sparklines and comparative analytics across web and iOS clients.

---

## User Stories

- **As a user**, I want my weekly review to automatically compute my week's start and end boundaries in my local timezone, so that my metrics match my real-world calendar week.
- **As a user**, I want to see how many of my planned tasks were actually completed, so that I can calibrate my daily capacity more realistically.
- **As a user**, I want a breakdown of my focus session hours across projects, so that I know whether I spent deep effort on my primary goals.
- **As a user**, I want to review my habit streak consistency and average bedtime overflow, so that I can maintain circadian rhythm and recovery.
- **As a user**, I want to record my qualitative wins, obstacles, and next-week adjustments in draft form before finalizing, so that I can reflect thoughtfully without losing progress.
- **As a user**, I want completed reviews to be archived as permanent milestones and compare my last 4 weeks of progress, so that I can observe my growth over time.

---

## Core Domain Concepts

```text
User
 └── Weekly Review (User-scoped, Monday-to-Sunday ISO week)
      ├── Status: DRAFT | COMPLETED
      ├── Period: [periodStartDate (Mon), periodEndDate (Sun)]
      ├── Objective Telemetry:
      │    ├── Task Metrics (planned, completed, planned-vs-actual rate)
      │    ├── Focus Rollup (total minutes, daily avg, project breakdown)
      │    ├── Habit Metrics (consistency rate, active habit logs, streaks)
      │    └── Circadian Metrics (avg bedtime overflow, bedtime compliance)
      ├── Qualitative Reflection:
      │    ├── Wins (accomplishments & breakthroughs)
      │    ├── Blockers (frictions & distractions)
      │    ├── Adjustments (commitments for next week)
      │    └── Satisfaction Score (1 to 10)
      └── Multi-Week Progress Trends:
           └── Rolling 4-week comparison of key velocity and consistency indicators
```

---

## Behavior

### 1. Week Boundary Resolution (ISO-8601 & ADR-006)
- A review period is defined strictly as an ISO-8601 week: starting on **Monday at `00:00:00`** and ending on **Sunday at `23:59:59.999999`** local wall-clock time in the user's configured IANA timezone (from `UserTimezoneService`).
- In the database, the period is identified by `period_start_date` (`DATE`, always a Monday) and `period_end_date` (`DATE`, always the following Sunday).
- For instant-based data sources (`focus_sessions`, `tasks.completed_at`), the query window is converted to UTC instants:
  $$\text{startInstant} = \text{periodStartDate}.\text{atStartOfDay}(\text{userZone}).\text{toInstant()}$$
  $$\text{endInstant} = \text{periodEndDate}.\text{plusDays}(1).\text{atStartOfDay}(\text{userZone}).\text{toInstant()}$$
- Requesting `/current` resolves "today" via the server clock in the user's timezone, determines the current week's Monday, and opens or creates the week's review.

### 2. Multi-Domain Telemetry Aggregation

#### A. Task Velocity & Commitment Ratio
- **Planned Tasks:** Tasks associated with `daily_plans` where `calendar_date` falls in `[periodStartDate, periodEndDate]` and `deleted_at IS NULL`.
- **Completed Tasks:** Active tasks with `status = 'COMPLETED'` whose `completed_at` falls within $[\text{startInstant}, \text{endInstant})$.
- **Planned-Completed Tasks:** Tasks that were both included in that week's `daily_plans` and completed during the week.
- **Completion Rate:**
  $$\text{taskCompletionRate} = \begin{cases} \frac{\text{plannedCompletedTasksCount}}{\text{plannedTasksCount}} \times 100 & \text{if } \text{plannedTasksCount} > 0 \\ 0.0 & \text{otherwise} \end{cases}$$
- **Daily Top 3 Rate:** Percentage of Top 3 slots that were marked completed during the week.

#### B. Focus Effort & Project Allocation
- **Focus Minutes:** Sum of active `duration_seconds / 60` for all focus sessions where `started_at` falls within $[\text{startInstant}, \text{endInstant})$ and `ended_at IS NOT NULL`.
- **Daily Average:** $\text{totalFocusMinutes} / 7$.
- **Project Allocation:** Focus minutes grouped by `task.projectId`:
  - Each item includes `projectId`, `projectTitle`, `focusMinutes`, and percentage of total focus time.
  - Tasks without a project are categorized as `"Inbox / Standalone Tasks"`.

#### C. Habit Consistency & Circadian Bedtime Alignment
- **Habit Consistency Rate:**
  $$\text{habitConsistencyRate} = \frac{\text{totalCompletedOccurrences}}{\text{activeHabitsCount} \times 7} \times 100$$
  Derived from `schedule_habit_occurrences` matching active habits in `schedule_habits`.
- **Per-Habit Breakdown:** List of habits with icon, title, phase, weekly completions (out of 7), and active consecutive streak.
- **Bedtime Overflow Tracking:**
  - Evaluates the projected/actual bedtime overflow minutes across the 7 days from schedule entries and anchor nodes.
  - Computes `averageBedtimeOverflowMinutes` (e.g. $+18\text{m}$).
  - Computes `bedtimeComplianceRate`: percentage of days in the week where bedtime overflow was $\le 15$ minutes.

### 3. Review Lifecycle: Draft vs Completed
- **`DRAFT` State:**
  - A review starts in `DRAFT` status upon creation.
  - Aggregated metrics are dynamically re-calculated or refreshed on read to reflect the latest task completions or focus sessions.
  - User can continuously edit qualitative responses (`wins`, `blockers`, `adjustments`) and update `satisfactionScore` (1–10).
- **`COMPLETED` State:**
  - When the user finishes their review ritual, they trigger `POST /api/v1/reviews/{id}/complete`.
  - The server aggregates final operational metrics, writes them into the scalar columns and detailed `metrics_snapshot` JSON/text payload, sets `status = 'COMPLETED'`, and sets `completed_at = now()`.
  - **Immutability Invariant:** Once `COMPLETED`, a review is permanently frozen. Subsequent changes to tasks, daily plans, or habit logs will never alter the completed review's metrics or reflections. Editing reflection text on a `COMPLETED` review returns `409 Conflict`.

### 4. 4-Week Progress Trends
- The endpoint `GET /api/v1/reviews/trends?weeks=4` evaluates the 4 most recent weeks (ending at the current week).
- Returns a chronological progression of:
  - Focus time (minutes per week)
  - Task completion rate (%)
  - Habit consistency rate (%)
  - Average bedtime overflow (minutes)
  - Satisfaction score (1–10)
- Computes trend deltas between the most recent completed week and the preceding 3-week baseline.

---

## Rules

1. **User Isolation (ADR-004):** Every Weekly Review belongs to exactly one authenticated user. Cross-user access returns `404 Not Found` without disclosing resource existence.
2. **Single Review per Week:** A user can have at most one review per ISO-8601 week. Uniqueness is enforced at the database level: `UNIQUE(user_id, period_start_date)`.
3. **Timezone Authority (ADR-006):** Week boundaries and date-to-instant conversions are always evaluated using the user's configured IANA timezone from `UserTimezoneService`. No client clocks or arbitrary offsets are trusted.
4. **ISO-8601 Week Standard:** A week strictly begins on Monday (`00:00:00`) and ends on Sunday (`23:59:59.999999`).
5. **State Machine Invariant:** Reviews follow the strictly unidirectional lifecycle: `DRAFT` $\rightarrow$ `COMPLETED`. Reopening or reversing a completed review is disallowed in V1.
6. **Freeze on Completion:** Transitioning to `COMPLETED` snapshots and freezes all metrics. A completed review is read-only.
7. **Draft Updatability:** A review in `DRAFT` status may be updated repeatedly via `PUT /api/v1/reviews/{id}` without creating duplicate records.
8. **Valid Satisfaction Range:** `satisfactionScore` must be an integer between 1 and 10 (inclusive) or null.
9. **Non-Negative Durations:** All calculated focus minutes, task counts, and habit occurrences must be non-negative integers.
10. **Graceful Handling of Empty Weeks:** Weeks with zero planned tasks, zero focus sessions, or zero habits return valid zero-value metrics (`0%`, `0m`, empty breakdowns) without errors or division-by-zero exceptions.

---

## Constraints

1. **PostgreSQL Persistence (ADR-003):** Flyway migration `V16__weekly_reviews.sql` defines the schema with foreign keys, checks, and partial/unique indexes.
2. **Layered Modular Layout (ADR-007):** Placed in package `com.productivityos.review` with sub-packages `controller/`, `service/`, `domain/`, `persistence/`, `dto/`, `exception/`.
3. **ArchUnit Compliance:** The `review` module may depend on `user`, `task`, `project`, `dailyplan`, `focus`, `schedule`, `auth`, `api`, and `config`. No other module may depend on `review`.
4. **Server Clock Authority:** Server UTC `Clock` governs all created, updated, and completed timestamps.

---

## Acceptance Criteria

### AC-WR01: Weekly Review Generation & Week Boundary Resolution (ADR-006)
- **Given** an authenticated user with configured IANA timezone `Europe/Paris`,
- **When** the client sends `GET /api/v1/reviews/current` on Wednesday `2026-11-11`,
- **Then** the server calculates the week boundaries as Monday `2026-11-09` through Sunday `2026-11-15`,
- **And** returns a review with `periodStartDate = 2026-11-09` and `periodEndDate = 2026-11-15`,
- **And** if no review previously existed for that week, a new review is created with `status = 'DRAFT'`,
- **And** the instantaneous query window spans `2026-11-08T23:00:00Z` to `2026-11-15T22:59:59.999999Z` (the UTC equivalent of Paris local boundaries).

### AC-WR02: Aggregation of Completed Tasks & Planned vs Actual Rate
- **Given** a user has 10 tasks in `daily_plans` across Monday through Sunday of the review week,
- **And** 7 of those planned tasks were completed within the week, plus 3 inbox tasks were completed,
- **When** the weekly review metrics are computed,
- **Then** `plannedTasksCount` equals 10,
- **And** `plannedCompletedTasksCount` equals 7,
- **And** `completedTasksCount` equals 10 (7 planned + 3 inbox),
- **And** `taskCompletionRate` is calculated as `70.0%`,
- **And** tasks completed outside the week's boundary are excluded from the count.

### AC-WR03: Focus Session Effort Rollup (total minutes, project breakdown)
- **Given** a user completed 6 focus sessions during the review week:
  - 120 minutes on Task A (Project "Productivity OS MVP")
  - 60 minutes on Task B (Project "Productivity OS MVP")
  - 90 minutes on Task C (Project "Health & Fitness")
  - 30 minutes on Task D (Inbox / No Project),
- **When** the review metrics are computed,
- **Then** `totalFocusMinutes` equals 300,
- **And** `dailyAverageFocusMinutes` equals 42 (rounded from $300/7$),
- **And** `focusSessionCount` equals 6,
- **And** `projectFocusBreakdown` contains 3 entries:
  - "Productivity OS MVP": 180 minutes (60.0%)
  - "Health & Fitness": 90 minutes (30.0%)
  - "Inbox / Standalone Tasks": 30 minutes (10.0%).

### AC-WR04: Circadian & Habit Streak Consistency Metrics (link-map habits & bedtime overflow)
- **Given** a user has 4 active habits in the Daily Schedule,
- **And** over the 7 days of the week, 21 habit occurrences were logged out of 28 expected opportunities,
- **And** bedtime overflow minutes recorded across the 7 days were `[0, 15, 30, 45, 0, 0, 15]` (total 105m),
- **When** the review metrics are computed,
- **Then** `habitConsistencyRate` equals `75.0%` ($21 / 28$),
- **And** `averageBedtimeOverflowMinutes` equals 15 ($105 / 7$),
- **And** `bedtimeComplianceRate` equals `71.4%` (5 of 7 days had overflow $\le 15$ minutes),
- **And** each habit includes its title, icon, weekly completion fraction, and current consecutive streak.

### AC-WR05: Draft Reflection Persistence (wins, blockers, adjustments)
- **Given** an existing review in `DRAFT` status with ID `{id}`,
- **When** the client sends `PUT /api/v1/reviews/{id}` with:
  ```json
  {
    "wins": "Shipped backend schedule slice ahead of deadline.",
    "blockers": "Late afternoon meetings disrupted deep work.",
    "adjustments": "Protect 09:00-11:30 for deep focus blocks only.",
    "satisfactionScore": 8
  }
  ```
- **Then** the server persists the text fields and satisfaction score,
- **And** updates `updated_at` with the current server instant,
- **And** returns `200 OK` with the updated review in `DRAFT` status.

### AC-WR06: Finalize / Complete Weekly Review (status transition DRAFT -> COMPLETED)
- **Given** a review in `DRAFT` status with ID `{id}`,
- **When** the client sends `POST /api/v1/reviews/{id}/complete`,
- **Then** the server executes final metrics aggregation and persists the snapshot,
- **And** transitions `status` to `COMPLETED`,
- **And** sets `completed_at` to the current server UTC instant,
- **And** returns `200 OK` with `status = "COMPLETED"`,
- **And** any subsequent call to `PUT /api/v1/reviews/{id}` returns `409 Conflict` with code `"REVIEW_ALREADY_COMPLETED"`,
- **And** subsequent task completions for that calendar week do not alter the saved review metrics.

### AC-WR07: Historical Review Retrieval & 4-Week Progress Trends
- **Given** a user has completed reviews for the past 4 consecutive weeks,
- **When** the client sends `GET /api/v1/reviews/trends?weeks=4`,
- **Then** the server returns a chronological list of 4 trend entries,
- **And** each entry includes `periodStartDate`, `isoWeek`, `totalFocusMinutes`, `taskCompletionRate`, `habitConsistencyRate`, `averageBedtimeOverflowMinutes`, and `satisfactionScore`,
- **And** the response includes computed percentage deltas comparing the latest week against the prior 3-week average.

### AC-WR08: REST Endpoint Contract & Validation
- **Given** an unauthenticated request or an attempt by User A to access User B's review ID,
- **When** any endpoint under `/api/v1/reviews` is invoked,
- **Then** unauthenticated requests return `401 Unauthorized`,
- **And** requests for another user's review return `404 Not Found` (ADR-004),
- **And** submitting `satisfactionScore: 12` returns `400 Bad Request` with code `"VALIDATION_ERROR"`,
- **And** submitting an invalid date format returns `400 Bad Request`.

### AC-WR09: Web Client Weekly Review Ritual & Insights Dashboard
- **Given** an authenticated user navigates to `/review` on the web client,
- **When** `ReviewPage.vue` mounts,
- **Then** the page loads the active week's review and presents a 3-step ritual layout:
  1. **Insights Overview:** Stat cards for Task Completion Rate, Focus Hours by Project (with visual stacked bar chart), Habit Consistency Ring, and Bedtime Alignment gauge.
  2. **Reflection Wizard:** Step-by-step inputs for "What went well?" (Wins), "What slowed you down?" (Blockers), "What will you change next week?" (Adjustments), and a 1–10 satisfaction slider with debounce auto-save.
  3. **Completion & Commitment:** "Finalize Review" button with confirmation modal, transitioning the page to a polished "Review Completed" summary view.
- **And** a historical drawer allows browsing past completed reviews and viewing the 4-week trend sparkline.

### AC-WR10: iOS Client Weekly Review View & Progress Cards
- **Given** an authenticated user opens the Weekly Review view in the iOS app,
- **When** `ReviewViewModel.loadCurrentReview()` executes,
- **Then** the view renders native SwiftUI metric cards:
  - Task Planned vs Actual completion ring,
  - Focus time bar breakdown by project,
  - Habit streak summary and Bedtime deviation card,
  - Expandable text areas for Wins, Blockers, and Adjustments with haptic feedback on save,
  - "Complete Review" action button with celebratory confirmation animation,
- **And** a "4-Week Progress Trends" section visualizes multi-week velocity charts,
- **And** previously loaded reviews are cached locally via `APICache` for offline browsing.

---

## Edge Cases

1. **Mid-Week Review Creation:** When a review is opened on Wednesday, metrics reflect Monday through Wednesday to date. The review remains in `DRAFT` status and updates dynamically until finalized on Sunday or Monday.
2. **Reviewing Past Weeks:** A user may generate or finalize a review for a prior week by passing `POST /api/v1/reviews` with `{ "date": "2026-11-02" }`. The server normalizes the date to that week's Monday and aggregates metrics for that historical window.
3. **Week Spanning Month or Year Boundary:** Handled deterministically by ISO-8601 week rules (e.g. `2026-12-28` to `2027-01-03`). The starting Monday date defines the period record.
4. **Zero Recorded Activity:** If a user was completely inactive (0 tasks, 0 focus sessions, 0 habits logged), metrics safely calculate as `0%` completion rate, `0` focus minutes, `0%` habit consistency, and `0m` overflow without arithmetic overflow or null pointer errors.
5. **DST Transition Within Week:** Handled automatically by `java.time.ZoneId` and `ZoneRules` (ADR-006). Days may be 23 or 25 hours; the exact UTC instant span matches the local wall-clock week boundaries.
6. **Concurrent Edits from Multiple Devices:** Protected by database-level transactions and optimistic versioning; the last saved reflection draft persists cleanly.

---

## Out of Scope

- Automated AI reflection generation or LLM-generated personal reviews (AI is an external advisory capability per `domain.md`, not an automatic actor).
- Social sharing or public publishing of weekly productivity reports.
- Multi-user team productivity rollups or manager dashboards (Productivity OS is strictly personal and user-isolated).
- Custom week boundary configurations (e.g. Saturday-to-Friday); ISO-8601 Monday-to-Sunday is the standard.
- Complex calendar export (e.g. PDF generation, email summaries).

---

## Dependencies

- **User Module & Timezone:** `com.productivityos.user.service.UserTimezoneService` (ADR-006).
- **Task Module:** `com.productivityos.task.persistence.TaskRepository` (task completion state).
- **Daily Plan Module:** `com.productivityos.dailyplan.persistence.DailyPlanRepository` (planned tasks).
- **Focus Module:** `com.productivityos.focus.persistence.FocusSessionRepository` (focus durations).
- **Schedule Module:** `com.productivityos.schedule.persistence.ScheduleHabitRepository`, `ScheduleHabitOccurrenceRepository`, `ScheduleEntryRepository` (habits and bedtime).
- **Project Module:** `com.productivityos.project.persistence.ProjectRepository` (project metadata).
- **Architecture Decisions:** ADR-002, ADR-003, ADR-004, ADR-005, ADR-006, ADR-007.

---

## Open Questions

1. **Reopening Completed Reviews:** Should a user be allowed to reopen a `COMPLETED` review back into `DRAFT` if they want to amend their notes?
   - *Recommendation for V1:* Keep reviews immutable once `COMPLETED` to preserve historical integrity. If users request amendments, add an explicit "Amend Reflection" endpoint in a future iteration.
2. **Weekly Review Notification / Prompt:** Should the system prompt the user (e.g. banner on Today page on Sundays after 18:00) to conduct their review?
   - *Recommendation for V1:* Show a subtle reminder card on `TodayPage.vue` when the current day is Sunday or Monday and that week's review is still in `DRAFT` status.

---

## Change History

- **2026-11-12:** Initial specification authoring for Weekly Review & Progress Analytics (Behavior & Productivity Learning) covering AC-WR01 through AC-WR10, ISO-8601 boundary resolution, multi-domain telemetry aggregation, draft reflection lifecycle, 4-week trends, and client ritual experiences.
