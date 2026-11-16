# Plan 023: iOS Schedule Cleanup & Dedicated Deep Work Tab

## Status
Completed

---

## 1. Specification Reference

### Primary Behavioral Source of Truth
- [docs/specs/ui/ios-schedule-deep-work-tab-spec.md](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/specs/ui/ios-schedule-deep-work-tab-spec.md) (Proposed)
- [docs/specs/planning/daily-schedule-linkmap.md](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/specs/planning/daily-schedule-linkmap.md) (Approved)

### Acceptance Criteria in Scope
- **AC-001:** Bedtime Shift Banner Removal from Schedule Top
- **AC-002:** Schedule Bottom Scroll Clearance & Zero Clipping
- **AC-003:** Unified & Prominent Time Pills across Schedule Nodes
- **AC-004:** Phase Header Time Range Contrast & Readability
- **AC-005:** Dedicated Deep Work Tab in Main Navigation Bar
- **AC-006:** Deep Work Phase Filter in Schedule Journey Link-Map

---

## 2. Architectural Decisions & Product Choices

### D1: Bedtime Shift Banner Removal vs Relocation
- **Context:**
  In `ScheduleView.swift`, `ScheduleBedtimeBanner` ("Bedtime Shifts: 23:15 (+45m past target 22:30)... Habit Momentum 0/6 completed (0%)") is pinned at the top of the schedule timeline. As observed in simulator testing on iPhone 17 Pro (`Simulator Screenshot - iPhone 17 Pro - 2026-11-14 at 16.36.23.png`), this banner creates visual clutter and early morning anxiety.
- **Options Evaluated:**
  - *Option A (Recommended):* Remove `ScheduleBedtimeBanner` from `ScheduleView.swift`. The bedtime target and projected overflow are already modeled and displayed in their natural chronological place at the bottom of the timeline in the Bedtime Sanctuary phase (`ScheduleAnchorNodeView`). Keep the banner component file for potential settings/insights reuse.
  - *Option B:* Collapse the banner into an accordion. Still clutters the morning header and distracts from morning activation.
- **Decision:** **Option A**. Keeps the schedule screen clean, calm, and focused on current trajectory.

### D2: Schedule Internal Segmented Switcher ('Routine' vs 'Deep Work')
- **Context:**
  The user clarified that "move deep work section to separate tab" refers specifically to the Schedule feature, not the main bottom app navigation bar.
- **Decision:**
  - Restore the bottom navigation bar to the 4 core tabs: `Schedule`, `Goals`, `Tasks`, `Me` (or `Schedule`, `Tasks`, `Goals`, `Me`).
  - In `ScheduleView.swift`, introduce a top segmented switcher:
    - Segment 1: `Routine` (Circadian timeline: Morning Activation, Afternoon Momentum, Bedtime Sanctuary).
    - Segment 2: `Deep Work` (Deep Focus Work phase from the schedule: Top 1, Top 2, Recharge breaks, with 1-tap focus launch).
  - Both segments share the same `ScheduleViewModel` state.

### D3: Schedule Node Unified Layout & Zero-Wrapping Time Badges
- **Context:**
  In simulator screenshot `11.06.38.png`, `ScheduleAnchorNodeView` wraps `23:15 (+45m)` into `23:1` \ `5` because it was crammed into the title row of "Sleep Target & Bedtime Terminus". `ScheduleRechargeNodeView` placed `"Scheduled: 21:00"` next to the subtitle, squeezing the text, and put duration in the title row.
- **Decision:**
  - Standardize all 4 node types (`ScheduleAnchorNodeView`, `ScheduleRechargeNodeView`, `ScheduleHabitNodeView`, `ScheduleActivityNodeView`) to a uniform 3-tier vertical layout:
    1. Row 1: Title (and streak icon).
    2. Row 2: Subtitle description (clean, full width).
    3. Row 3: Metadata Row containing Time Pill + Duration Pill + Overflow Badge with `.fixedSize(horizontal: true, vertical: false)` and `.lineLimit(1)`.
  - Bedtime anchor overflow `23:15 (+45m overflow)` moves to Row 3 where it has full horizontal width and never wraps.
  - In `ScheduleView.swift`, add opaque navigation bar background so content doesn't bleed under the Dynamic Island.

### D4: Circadian Journey Phase Filtering & Dynamic Serpentine Linkage
- **Context:**
  With Deep Work moved to its own dedicated tab, the Daily Link-Map timeline should present a pure circadian habit journey: Rise -> Hydrate -> Move -> Groom -> Afternoon Habits -> Bedtime Sanctuary.
- **Architecture:**
  - In `ScheduleJourneyLayoutView.swift`, define `displayedPhases = viewModel.phases.filter { $0.id != .deepFocus }`.
  - Map `phaseIndex + 1` dynamically over `displayedPhases`, cleanly numbering phases:
    1. Morning Activation (Rise, hydrate, move & set daily direction)
    2. Afternoon Momentum (Afternoon habits, shallow reset)
    3. Bedtime Sanctuary (Digital curfew, reflection, reading & sleep recovery)
  - Serpentine connectors seamlessly connect Phase 1 to Phase 2, and Phase 2 to Phase 3 without orphan curves.

---

## 3. Agent Delegation Matrix

| Agent | Target Slice | Owned Files / Scope | Verification Command | Dispatch Brief |
| :--- | :--- | :--- | :--- | :--- |
| `@ios-engineer` | Slice 1: Tab Navigation & Dedicated Deep Work Tab | `apps/ios/.../CustomTabBar.swift`<br>`apps/ios/.../MainTabView.swift`<br>`apps/ios/.../AppTabTests.swift` | `swift test --package-path apps/ios --filter AppTabTests` | Add `.deepWork` to `AppTab`, wire `TodayView` in `MainTabView`, update tests |
| `@ios-engineer` | Slice 2: Schedule View Cleanup & Bottom Clearance | `apps/ios/.../ScheduleView.swift` | `swift test --package-path apps/ios` | Remove bedtime shift banner from header; increase bottom scroll padding to 140pt |
| `@ios-engineer` | Slice 3: Phase Filtering & Header Contrast | `apps/ios/.../ScheduleJourneyLayoutView.swift` | `swift test --package-path apps/ios` | Filter `.deepFocus` phase, update numbering 1..3, improve phase header time range contrast |
| `@ios-engineer` | Slice 4: Unified Time Badges across Schedule Nodes | `apps/ios/.../ScheduleHabitNodeView.swift`<br>`apps/ios/.../ScheduleAnchorNodeView.swift` | `swift test --package-path apps/ios` | Standardize time badges with `.monospacedDigit()`, prominent pills, and streak alignment |
| `@code-reviewer` | Slice 5: Quality Audit | Full PR Git Diff | `./scripts/agent-review.sh` | Verify zero regression against ACs, ADRs, and visual hierarchy |

---

## 4. Step-by-Step Implementation Tasks

### Step 1: Add Dedicated `Deep Work` Tab to Navigation
- **Files Affected**:
  - `apps/ios/ProductivityOS/Core/DesignSystem/Components/CustomTabBar.swift`
  - `apps/ios/ProductivityOS/Features/Main/MainTabView.swift`
  - `apps/ios/ProductivityOSTests/AppTabTests.swift`
- **AC Reference**: `AC-005`
- **Detailed Action**:
  1. In `CustomTabBar.swift`:
     - Update `AppTab` enum:
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
  2. In `MainTabView.swift`:
     - Add `Tab(AppTab.deepWork.rawValue, systemImage: AppTab.deepWork.iconName, value: .deepWork)` hosting `TodayView`.
     - Wire focus callbacks:
       ```swift
       Tab(AppTab.deepWork.rawValue, systemImage: AppTab.deepWork.iconName, value: AppTab.deepWork) {
           TodayView(
               projectsViewModel: projectsViewModel,
               onStartFocus: { task in
                   focusViewModel.setSelectedTask(task)
                   isShowingFocusSheet = true
               },
               onSelectTask: { task in
                   focusViewModel.setSelectedTask(task)
                   isShowingFocusSheet = true
               }
           )
       }
       ```
     - In `.onOpenURL`, support `"deepwork"`, `"focus"`, `"today"` mapping to `selectedTab = .deepWork`.
  3. In `AppTabTests.swift`:
     - Update `testAppTabCasesCountAndOrder` to assert 5 tabs: `[.schedule, .deepWork, .tasks, .goals, .me]`.
- **Verification**:
  - Run `swift test --package-path apps/ios --filter AppTabTests`.

---

### Step 2: Remove Bedtime Shift Banner & Fix Bottom Scroll Clearance
- **Files Affected**:
  - `apps/ios/ProductivityOS/Features/Schedule/ScheduleView.swift`
- **AC Reference**: `AC-001`, `AC-002`
- **Detailed Action**:
  1. In `ScheduleView.swift`:
     - Remove `ScheduleBedtimeBanner(...)` call from `VStack`.
     - Change `.padding(.bottom, 100)` to `.padding(.bottom, 140)` on the `ScrollView` content.
- **Verification**:
  - Check compilation and run `swift test --package-path apps/ios`.

---

### Step 3: Filter Deep Work Phase from Schedule Journey & Fix Header Contrast
- **Files Affected**:
  - `apps/ios/ProductivityOS/Features/Schedule/Layouts/ScheduleJourneyLayoutView.swift`
- **AC Reference**: `AC-004`, `AC-006`
- **Detailed Action**:
  1. In `ScheduleJourneyLayoutView.swift`:
     - Compute `displayedPhases`:
       ```swift
       private var displayedPhases: [SchedulePhase] {
           viewModel.phases.filter { $0.id != .deepFocus }
       }
       ```
     - Loop over `displayedPhases.enumerated()` instead of `viewModel.phases.enumerated()`.
     - Pass `phaseNumber: phaseIndex + 1` so Morning is 1, Afternoon is 2, Bedtime is 3.
     - Connectors link `phaseIndex < displayedPhases.count - 1`.
  2. Fix phase time range contrast:
     - Update `Text(phase.timeRange)` inside the phase progress pill to:
       ```swift
       Text(phase.timeRange)
           .font(AppTypography.captionSmall)
           .fontWeight(.semibold)
           .foregroundStyle(Color(hex: "334155"))
           .monospacedDigit()
       ```
     - Background: `Capsule().fill(Color(hex: "EDE9FE"))`.
- **Verification**:
  - Run `swift test --package-path apps/ios`.

---

### Step 4: Unify Time Pills across Schedule Node Views
- **Files Affected**:
  - `apps/ios/ProductivityOS/Features/Schedule/Components/Nodes/ScheduleHabitNodeView.swift`
  - `apps/ios/ProductivityOS/Features/Schedule/Components/Nodes/ScheduleAnchorNodeView.swift`
- **AC Reference**: `AC-003`
- **Detailed Action**:
  1. In `ScheduleHabitNodeView.swift`:
     - Keep streak flame badge adjacent to title:
       ```swift
       HStack(alignment: .center, spacing: 6) {
           Text(node.title)
               .font(AppTypography.headline)
               .foregroundStyle(AppColors.textPrimary)
               .strikethrough(isCompleted, color: AppColors.textSecondary)

           if streakCount > 0 {
               HStack(spacing: 3) {
                   Text("🔥")
                       .font(.system(size: 11))
                   Text("\(streakCount)d")
                       .font(AppTypography.captionSmall)
                       .fontWeight(.bold)
               }
               .foregroundStyle(Color(hex: "EA580C"))
               .padding(.horizontal, 6)
               .padding(.vertical, 2)
               .background(Capsule().fill(Color(hex: "FFEDD5")))
           }
       }
       ```
     - Scheduled Time Pill and Duration Pill rendered prominently below subtitle with consistent font, padding, and monospaced digits:
       ```swift
       if node.time != nil || node.durationMinutes != nil {
           HStack(spacing: 6) {
               if let time = node.time {
                   HStack(spacing: 4) {
                       Image(systemName: "clock.fill")
                           .font(.system(size: 10, weight: .bold))
                       Text(time)
                           .font(.system(size: 12, weight: .bold, design: .rounded))
                           .monospacedDigit()
                   }
                   .foregroundStyle(isCompleted ? AppColors.success : AppColors.primary)
                   .padding(.horizontal, 9)
                   .padding(.vertical, 4)
                   .background(
                       Capsule()
                           .fill(isCompleted ? AppColors.success.opacity(0.12) : AppColors.primaryTint)
                           .overlay(
                               Capsule()
                                   .stroke(isCompleted ? AppColors.success.opacity(0.3) : AppColors.primary.opacity(0.2), lineWidth: 1)
                           )
                   )
               }

               if let duration = node.durationMinutes {
                   HStack(spacing: 4) {
                       Image(systemName: "hourglass")
                           .font(.system(size: 10, weight: .bold))
                       Text("\(duration)m")
                           .font(.system(size: 12, weight: .bold, design: .rounded))
                           .monospacedDigit()
                   }
                   .foregroundStyle(Color(hex: "334155"))
                   .padding(.horizontal, 9)
                   .padding(.vertical, 4)
                   .background(
                       Capsule()
                           .fill(Color(hex: "F1F5F9"))
                           .overlay(Capsule().stroke(Color(hex: "CBD5E1"), lineWidth: 1))
                   )
               }
           }
       }
       ```
- **Verification**:
  - Run `swift test --package-path apps/ios`.

---

### Step 5: Test Execution & Regression Verification
- **AC Reference**: `AC-001` through `AC-006`
- **Command**:
  ```bash
  swift test --package-path apps/ios
  ```
- **Expected Outcome**: All 185+ unit tests pass without failure.

---

## 5. Traceability Matrix

| Acceptance Criteria | Description | Addressed In Step | Target Files | Verification Method |
| :--- | :--- | :--- | :--- | :--- |
| **AC-001** | Bedtime Shift Banner Removal from Top | Step 2 | `ScheduleView.swift` | Visual audit & SwiftUI test build |
| **AC-002** | Bottom Scroll Clearance (140pt) | Step 2 | `ScheduleView.swift` | Visual simulator scroll test |
| **AC-003** | Unified & Prominent Time Pills | Step 4 | `ScheduleHabitNodeView.swift`<br>`ScheduleAnchorNodeView.swift` | Unit tests & visual inspection |
| **AC-004** | Phase Header Time Range Contrast | Step 3 | `ScheduleJourneyLayoutView.swift` | Visual contrast inspection |
| **AC-005** | Dedicated Deep Work Tab | Step 1 | `CustomTabBar.swift`<br>`MainTabView.swift`<br>`AppTabTests.swift` | `swift test --package-path apps/ios --filter AppTabTests` |
| **AC-006** | Deep Work Phase Filter in Journey | Step 3 | `ScheduleJourneyLayoutView.swift` | SwiftUI view preview & unit tests |

---

## 6. Risks & Mitigation

| Risk | Impact | Mitigation Strategy |
| :--- | :--- | :--- |
| **Tab Bar icon congestion on narrow screens (iPhone SE)** | Medium | `CustomTabBar` uses equal horizontal flex (`.frame(maxWidth: .infinity)`), 20pt symbols, and small caption typography. Tested on 375pt viewport. |
| **Deep linking URL collision** | Low | Map `productivityos://today`, `productivityos://focus`, `productivityos://deepwork` all safely to `selectedTab = .deepWork`. |
| **Existing tests referencing SchedulePhaseId.deepFocus** | Low | Data model enum `SchedulePhaseId.deepFocus` is preserved intact; filtering is purely presentation-layer in `ScheduleJourneyLayoutView`. |
