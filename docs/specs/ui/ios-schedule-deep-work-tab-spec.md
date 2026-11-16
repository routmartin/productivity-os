# iOS Schedule & Dedicated Deep Work Tab UI Specification

## Status
Approved

## Problem Statement
Based on user testing on iPhone 17 Pro (Simulator screenshot `Simulator Screenshot - iPhone 17 Pro - 2026-11-14 at 16.36.23.png`), three critical usability and layout problems prevent the iOS app from providing a serene, coherent daily planning experience:

1. **Intrusive Bedtime Shift Banner at Schedule Top**:
   - In `ScheduleView.swift`, the `ScheduleBedtimeBanner` ("Bedtime Shifts: 23:15 (+45m past target 22:30)... Habit Momentum 0/6 completed (0%)") is pinned prominently at the top of the schedule timeline.
   - Pinned at the very top of the morning routine, this creates cognitive alarm and anxiety when the user is trying to start their morning habits.
   - Furthermore, the circadian bedtime target is already represented as an anchor milestone node in the Bedtime phase at the end of the timeline, making this top banner redundant.

2. **Broken Time UI & Bottom Scroll Clipping**:
   - **Bottom Tab Bar Clipping**: In `ScheduleView.swift`, the scroll view bottom padding is only `.padding(.bottom, 100)`. Because the app uses a modern floating Liquid Glass bottom tab bar with safe area insets and blur, the bottom card of the morning phase ("Daily Top 3 Planning & Intent", 08:15, 30m) is cut in half and partially obscured behind the tab bar.
   - **Inconsistent Time Badge Placement**: Schedule nodes display scheduled times in divergent, disjointed locations:
     - `ScheduleAnchorNodeView` (`Wake Up`) places time `[ 🌅 06:30 ]` at the trailing edge of the title row.
     - `ScheduleHabitNodeView` (`Hydration`, `Cardio`, `Cold Rinse`) places streak `[ 🔥 1d ]` at the trailing edge of the title row, while tucking time `[ 🕒 06:45 ] [ ⌛ 15m ]` below the subtitle in tiny pills.
     - `ScheduleActivityNodeView` places duration in the top row and time in a bottom execution row.
     - This breaks the user's vertical eye-tracking rhythm when scanning the day chronologically.
   - **Weak Contrast in Phase Header Time Ranges**: In `ScheduleJourneyLayoutView.swift`, the phase time range (e.g. `06:30 – 09:00`) is rendered in `AppColors.textSecondary` on a light purple capsule (`#F3EFFF`), failing WCAG AA contrast standards.

3. **Deep Work Mixed into Circadian Habits Timeline**:
   - Currently, Phase 2 of the Daily Link-Map is `deepFocus` ("Deep Focus Work", 09:00 - 12:30), mixing deep work tasks (Top 1, Top 2, Recharge breaks) directly into the circadian habit sequence (Wake -> Hydrate -> Cardio -> Cold Shower -> Bedtime).
   - Deep work is an intentional focus modality with timer loops, session states, and task commitments, whereas circadian habits are automated behavioral rituals.
   - Combining them in one scrolling list creates clutter and cognitive confusion.
   - The user requires Deep Work to be moved to its own dedicated tab in the primary tab bar navigation.

---

## Goal
Deliver a refined iOS navigation and schedule experience that:
- Removes the top bedtime shift warning banner from `ScheduleView`.
- Increases bottom scroll clearance to `140pt` so all timeline cards clear the floating bottom tab bar cleanly.
- Unifies time badges across all schedule nodes with prominent, scannable, and consistent positioning and high contrast.
- Restores the primary app bottom navigation to the 4 core tabs (`Schedule`, `Tasks`, `Goals`, `Me`).
- Introduces an internal top segmented control in `ScheduleView`: `[ Routine ]` and `[ Deep Work ]`.
  - `Routine`: Pure circadian habit journey (Morning Activation, Afternoon Momentum, Bedtime Sanctuary).
  - `Deep Work`: Schedule's deep focus blocks (Top 1, Top 2, Recharge walk) with 1-tap focus timers and progress.

---

## Temporal Mental Model & UX Paradigm

```
┌────────────────────────────────────────────────────────────────────────┐
│                   SEPARATION OF PRODUCTIVITY MODALITIES                │
│                                                                        │
│  [ SCHEDULE TAB ]                 [ DEEP WORK TAB ]                    │
│  Circadian Habit Journey          Intentional Focus Execution          │
│  ────────────────────────         ───────────────────────────          │
│  Phase 1: Morning Activation      Today's Intention Hero Card          │
│  Phase 2: Afternoon Momentum      Daily Top 3 Focus Commitments        │
│  Phase 3: Bedtime Sanctuary       Interactive Focus Clock & Launcher   │
│  (Anchors, habits, recovery)      Session stats (streak, weekly focus) │
└────────────────────────────────────────────────────────────────────────┘
```

1. **Circadian Rhythm (Schedule Tab)**:
   - Answers: *"What is my biological trajectory today from rise to sleep?"*
   - Focuses strictly on wake anchors, health rituals (water, cardio, cold rinse), afternoon recharge, and evening wind-down to bedtime target.
2. **Deep Work Flow (Deep Work Tab)**:
   - Answers: *"What is my highest-value work commitment right now and how long will I focus?"*
   - Focuses on intentional daily focus blocks, Top 3 priority tasks, live countdown timer, and focus session lifecycle.
3. **Tasks & Inbox (Tasks Tab)**:
   - Answers: *"What tasks exist across projects, backlog, kanban, and date segments?"*

---

## User Stories

1. **As a morning user**, when I open the Schedule tab, I want to see my morning routine immediately without an alarming bedtime shift warning banner at the top, so that I can focus calmly on my morning habits.
2. **As a mobile user**, when I scroll to the bottom of any phase in the Schedule view, I want all cards to be completely visible above the floating tab bar without clipping, so that I can read and tap every step.
3. **As a time-conscious planner**, when I scan the schedule timeline, I want scheduled times (e.g. `06:30`, `06:45`, `07:00`) to appear in a consistent, prominent position across all card types with crisp contrast, so that I immediately know what time each event begins.
4. **As a focused professional**, I want a dedicated "Deep Work" tab in the bottom navigation bar, so that I can access my Daily Top 3, set my daily intention, and launch focus sessions without navigating through circadian habit lists.

---

## Detailed Behavior & Component Specifications

### 1. Schedule View Header Cleanup (`ScheduleView.swift`)
- Remove `ScheduleBedtimeBanner` from the top of `ScheduleView.swift`.
- The header cleanly renders only:
  - Date subtitle: `todayDateFormatted` (e.g. `SATURDAY, NOVEMBER 14`).
  - Title: `"Daily Link-Map"`.
  - Subtitle: `"Morning-to-bedtime unified circadian trajectory"`.
  - Trailing action: `+` circular button to add a new step.
- Scroll view bottom padding increased from `100pt` to `140pt`:
  ```swift
  .padding(.bottom, 140)
  ```
- Bedtime target and projected overflow remain visible in their natural chronological place at the bottom of the timeline in Phase 3 (Bedtime Sanctuary) via `ScheduleAnchorNodeView`.

### 2. Dedicated Deep Work Tab (`AppTab` & `MainTabView`)
- `AppTab` enum updated to include `deepWork`:
  ```swift
  public enum AppTab: String, CaseIterable, Identifiable {
      case schedule = "Schedule"
      case deepWork = "Deep Work"
      case tasks = "Tasks"
      case goals = "Goals"
      case me = "Me"

      public var id: String { rawValue }

      public var iconName: String {
          switch self {
          case .schedule: return "calendar.day.timeline.left"
          case .deepWork: return "brain.head.profile"
          case .tasks: return "checklist"
          case .goals: return "target"
          case .me: return "person.fill"
          }
      }
  }
  ```
- `MainTabView` Tab Hierarchy:
  1. `Tab(AppTab.schedule.rawValue, systemImage: AppTab.schedule.iconName, value: .schedule) { ScheduleView() }`
  2. `Tab(AppTab.deepWork.rawValue, systemImage: AppTab.deepWork.iconName, value: .deepWork) { TodayView(...) }`
  3. `Tab(AppTab.tasks.rawValue, systemImage: AppTab.tasks.iconName, value: .tasks) { TasksView(...) }`
  4. `Tab(AppTab.goals.rawValue, systemImage: AppTab.goals.iconName, value: .goals) { GoalsView() }`
  5. `Tab(AppTab.me.rawValue, systemImage: AppTab.me.iconName, value: .me) { ProfileView() }`
- Deep Linking URL scheme:
  - `productivityos://deepwork`, `productivityos://focus`, `productivityos://today` -> switches `selectedTab = .deepWork`.
  - `productivityos://schedule` -> switches `selectedTab = .schedule`.
- `CustomTabBar`:
  - Renders 5 tabs evenly with fluid spacing, 20pt SF Symbols icons, active indicator line, and bold captions.

### 3. Circadian Phase Filtering in Schedule Journey (`ScheduleJourneyLayoutView.swift`)
- `displayedPhases` excludes `.deepFocus`:
  ```swift
  private var displayedPhases: [SchedulePhase] {
      viewModel.phases.filter { $0.id != .deepFocus }
  }
  ```
- Serpentine connectors link displayed phases continuously:
  - Phase 1: Morning Activation
  - Phase 2: Afternoon Momentum
  - Phase 3: Bedtime Sanctuary
- Phase numbers dynamically index as `1`, `2`, `3`.
- Phase progress pill contrast improved:
  - Time range text styled with high-contrast slate `AppColors.textPrimary` (or `Color(hex: "334155")`), font weight `.semibold`, monospaced digits.
  - Background: `Color(hex: "EDE9FE")` or `AppColors.primaryTint`.

### 4. Unified Time & Duration Badges across Schedule Nodes
- **Standard Card Hierarchy**:
  All schedule nodes (`ScheduleAnchorNodeView`, `ScheduleRechargeNodeView`, `ScheduleHabitNodeView`, `ScheduleActivityNodeView`) follow a unified 3-tier vertical hierarchy:
  1. **Row 1**: Icon + Title (clean, uncluttered; streak badge inline next to title).
  2. **Row 2**: Subtitle description (full width, never squeezed by misplaced badges).
  3. **Row 3**: Dedicated Time & Duration Metadata Row:
     - **Time Pill**: Always formatted with `.monospacedDigit()`, `.lineLimit(1)`, and `.fixedSize(horizontal: true, vertical: false)`. Never wraps across lines.
     - **Duration Pill**: Standardized capsule pill (e.g. `[ ⌛ 15m ]`, `[ 🍃 15m recovery ]`, `[ ⏱️ 90m focus ]`). Never wraps.
     - **Bedtime Anchor Overflow**: Positioned on the metadata row with full card width, so `23:15 (+45m overflow)` never wraps into `23:1` \ `5`.
- **Top Safe Area Navigation**:
  In `ScheduleView.swift`, ensure `.toolbarBackground(.visible, for: .navigationBar)` so cards do not bleed under the Dynamic Island.

---

## Acceptance Criteria

### AC-001: Bedtime Shift Banner Removal from Schedule Top
- **Given** the user navigates to the Schedule tab
- **When** the view loads
- **Then** no bedtime shift warning banner (`ScheduleBedtimeBanner`) is rendered at the top of the screen.
- **And** the view begins immediately with the screen header followed by the Phase 1 card.

### AC-002: Schedule Bottom Scroll Clearance & Zero Clipping
- **Given** an iPhone device with a floating bottom tab bar
- **When** the user scrolls to the bottom of the Schedule view
- **Then** the final card in the timeline is completely visible above the tab bar with at least 20pt of visible clearance.
- **And** no text, time badge, or button is clipped or obscured behind the tab bar.

### AC-003: Unified & Prominent Time Pills across Schedule Nodes
- **Given** any node in the schedule timeline (`anchor`, `habit`, `activity`, `recharge`)
- **When** the node displays a scheduled time
- **Then** the time is formatted with monospaced rounded digits (`.monospacedDigit()`).
- **And** habit nodes display scheduled time and duration in clear, prominent pills that do not conflict with streak counters.
- **And** the time pill is legible against its background with WCAG AA compliance.

### AC-004: Phase Header Time Range Contrast & Readability
- **Given** a phase card in `ScheduleJourneyLayoutView` (e.g. `Morning Activation`)
- **When** the phase header renders
- **Then** the phase time range (e.g. `06:30 – 09:00`) is rendered in high-contrast text (`Color(hex: "334155")` or `AppColors.textPrimary`) with `.semibold` weight.
- **And** the completion counter (`X/Y completed`) is clearly readable.

### AC-005: Dedicated Deep Work Tab in Main Navigation Bar
- **Given** the app launches to `MainTabView`
- **When** the bottom tab bar is displayed
- **Then** 5 primary tabs are visible in order: `Schedule`, `Deep Work`, `Tasks`, `Goals`, `Me`.
- **And** the `Deep Work` tab has the icon `brain.head.profile` (or `bolt.fill`).
- **When** the user taps the `Deep Work` tab
- **Then** the view transitions to `TodayView`, presenting Today's Intention, Your Top 3 focus tasks, the live Focus Today clock launcher, and session stats.
- **And** tapping "Start Focus" opens the focus session preparation flow.

### AC-006: Deep Work Phase Filter in Schedule Journey Link-Map
- **Given** the user is viewing the Schedule tab (`ScheduleJourneyLayoutView`)
- **When** the circadian timeline renders
- **Then** the `deepFocus` phase is excluded from the journey view.
- **And** the displayed phases are numbered sequentially: 1. Morning Activation, 2. Afternoon Momentum, 3. Bedtime Sanctuary.
- **And** serpentine curve connectors link Phase 1 directly to Phase 2, and Phase 2 directly to Phase 3 without visual gaps or disconnected curves.

---

## Edge Cases

1. **All Habits in Morning Completed**:
   - Habit checkboxes reflect green checkmark; time pill retains `.monospacedDigit()` in success green tint; phase header updates to `5/5 completed`.
2. **Deep Linking to Focus**:
   - URLs with `productivityos://today`, `productivityos://focus`, or `productivityos://deepwork` route directly to `selectedTab = .deepWork`.
3. **Narrow Screens (iPhone SE 375pt)**:
   - The 5-tab tab bar labels and icons fit comfortably without text truncation.
4. **Bedtime Overflow Calculation**:
   - Removing the banner does not alter the underlying calculation: if bedtime overflows, the Bedtime anchor node at the bottom of the Bedtime Sanctuary phase displays the overflow badge (+45m).

---

## Out of Scope
- Backend database schema migrations for schedule phases (existing schema supports phases).
- Web client changes (the web client already separates today focus hub and habits).
- Custom user re-ordering of tab bar items.

---

## Dependencies
- `apps/ios/ProductivityOS/Features/Schedule/ScheduleView.swift`
- `apps/ios/ProductivityOS/Features/Schedule/Layouts/ScheduleJourneyLayoutView.swift`
- `apps/ios/ProductivityOS/Features/Schedule/Components/Nodes/ScheduleHabitNodeView.swift`
- `apps/ios/ProductivityOS/Features/Schedule/Components/Nodes/ScheduleAnchorNodeView.swift`
- `apps/ios/ProductivityOS/Features/Today/TodayView.swift`
- `apps/ios/ProductivityOS/Features/Main/MainTabView.swift`
- `apps/ios/ProductivityOS/Core/DesignSystem/Components/CustomTabBar.swift`

---

## Change History
| Date | Author | Description |
| :--- | :--- | :--- |
| 2026-11-14 | SDD Planner | Initial specification authoring: Bedtime banner removal, bottom scroll padding fix, unified time badges, and dedicated Deep Work tab. |
