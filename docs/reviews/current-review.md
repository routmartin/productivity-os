# Review: Client API Integration — Daily Schedule Link-Map & Habit Tracker (Plan 011) - Cycle 2

## Verdict

PASS

---

## Summary of Changes Reviewed

This is Cycle 2 of the code review covering the client-side integration slice connecting the Web application (`apps/web`) and iOS application (`apps/ios`) to the Daily Schedule Link-Map backend REST API (`/api/v1/schedule`), implementing [Plan 011](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/plans/011-client-schedule-api-integration.md) based on [daily-schedule-linkmap.md](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/specs/planning/daily-schedule-linkmap.md).

All four issues raised during Review Cycle 1 have been resolved:
1. **High (AC-C08 / Decision D3)**: `ScheduleView.swift` now awaits `viewModel.addStep(payload)` asynchronously inside `Task`. `ScheduleViewModel.swift` reconciles temporary local IDs with canonical server UUIDs and dynamically rewires connecting edges upon server response in both sync and async paths.
2. **Medium (AGENTS.md Test Integrity)**: `GoalsViewModelTests.swift` fixture was updated with a completed project, genuinely verifying `overall.completed >= 1` without weakening assertions.
3. **Medium (Swift Performance)**: `ScheduleService.swift` reuses static `isoDateFormatter`, avoiding repeated allocations of `DateFormatter`.
4. **Low (Web Edge Re-Link Fallback)**: `scheduleStore.ts` matches edges by both `id` and `(fromNodeId, toNodeId)` fallback.

---

## Acceptance Criteria Verification

| Acceptance Criteria | Description | Target | Status | Verification Notes |
|:---|:---|:---|:---:|:---|
| **AC-C01** | Schedule View Route & Initial Live Fetch | Web | **PASS** | `scheduleStore.load()` dispatches `GET /api/v1/schedule/{date}` via `scheduleApi.getSchedule`. Transitions status `loading` -> `ready` and populates `graph`. Retains query-based preview modes for UI reviews. |
| **AC-C02** | Sub-16ms Optimistic Habit Toggle | Web | **PASS** | `scheduleStore.toggleHabit()` mutates habit completion, streak, and outgoing edge illumination synchronously before dispatching `POST /api/v1/schedule/habits/{id}/toggle`. Reconciles authoritative streak, history, and edges (matching both ID and node endpoints) on 200 OK. |
| **AC-C03** | Habit Toggle Network Failure Snapshot Rollback | Web | **PASS** | On network rejection or 5xx, `scheduleStore.toggleHabit()` restores complete snapshot (completion, streak, 14-day history, edges, overflow minutes, projected bedtime) and displays dismissible error banner in `SchedulePage.vue`. |
| **AC-C04** | Asynchronous In-Line Step Creation (server UUID) | Web | **PASS** | Form submission in `ScheduleAddStepDialog.vue` awaits `scheduleStore.addStep()`, calls `POST /api/v1/schedule/steps`, inserts server-returned node with canonical UUID, rewires topological edges, and recalculates bedtime. Displays inline loading spinner during in-flight request. |
| **AC-C05** | Step Deletion with Circadian Anchor Protection | Web | **PASS** | `ScheduleContextPanel.vue` hides delete button for anchor nodes (`node.type === "anchor"`). `scheduleStore.deleteNode()` validates anchor guard, optimistically removes node, bridges edges smoothly, and calls `DELETE /api/v1/schedule/steps/{id}`. Restores snapshot on rejection. |
| **AC-C06** | iOS Offline Resilience & Graceful Fallback | iOS | **PASS** | `ScheduleService.loadSchedule(for:)` queries `GET /api/v1/schedule/{date}`. On network failure or offline, gracefully returns 16-node baseline blueprint so user can interact uninterrupted. Preserves and propagates 401 unauthorized errors to trigger authentication logout. Verified in `ScheduleServiceTests`. |
| **AC-C07** | iOS Optimistic Habit Toggle & Server Reconciliation | iOS | **PASS** | `ScheduleViewModel.toggleHabit()` optimistically toggles state and edge illumination immediately, then dispatches `POST /api/v1/schedule/habits/{id}/toggle`. Reconciles state on 200 OK and rolls back on error. Verified in `ScheduleViewModelTests`. |
| **AC-C08** | iOS In-Line Step Addition & Anchor Deletion Guard | iOS | **PASS** | `ScheduleView.swift` invokes `await viewModel.addStep(payload)` asynchronously inside `Task`. `ScheduleViewModel.swift` now assigns server-generated canonical UUIDs directly in the async path and provides background reconciliation in `addStepSync`. Circadian anchors are guarded against deletion (`guard !nodeId.hasPrefix("anchor-")`), non-anchor deletions bridge incoming and outgoing edges, and server failures roll back gracefully. Verified in unit tests `testAnchorNodesCannotBeDeleted`, `testDeleteNonAnchorNodeRemovesItAndBridgesEdges`, `testDeleteNodeRollbackOnServerFailure`, `testAddStepReconcilesTemporaryIdWithServerUUID`, and `testAsyncAddStepReturnsServerNodeWithUUID`. |

---

## Findings by Severity

### Critical
*None.*

---

### High
*None.* (All Cycle 1 findings resolved.)

---

### Medium
*None.* (All Cycle 1 findings resolved.)

---

### Low
- **Sample Date in `ScheduleService.generateHistory`**:
  - **File**: [ScheduleService.swift](file:///Users/metamartin/Documents/RoutMartin/productivity-os/apps/ios/ProductivityOS/Core/Services/ScheduleService.swift#L74)
  - **Note**: `generateHistory` uses `Date()` rather than the requested `dateString` parameter when generating mock 14-day history for fallback blueprint items. Because this only applies to offline blueprint simulation, it does not affect live API operation or data integrity.

---

## Architectural & Security Compliance

- **ADR-002: Technology Stack**:
  - **Compliant**. Vue 3 with TypeScript, Vite, and Pinia in `apps/web`. Swift 5.9+ with SwiftUI and `@Observable` in `apps/ios`.
- **ADR-004: Authentication and User Isolation**:
  - **Compliant**. Both platforms route API traffic through centralized clients attaching Bearer JWT tokens. No user IDs are present in request URLs or bodies; user identity is derived strictly from server-side JWT claims.
- **ADR-006: Time and Timezone Handling**:
  - **Compliant**. Web uses `todayISODate()` respecting `user.timezone`. Dates are formatted without UTC drift. iOS reuses static ISO-8601 date formatter with device calendar context.
- **ADR-007: Package and Module Layout**:
  - **Compliant**. Schedule domain is strictly autonomous with zero leaky cross-domain imports.

---

## Correct Highlights

1. **Robust Dual-Path ID Reconciliation in iOS**: `ScheduleViewModel` supports both async and sync `addStep` workflows; the async workflow directly injects the server node with canonical UUID, while the sync overload reliably replaces the temporary ID and rewires incident edges upon completion.
2. **Strict Test Integrity**: Restored the `>= 1` assertion in `GoalsViewModelTests.swift` while updating the project test fixture to include a completed project, upholding the AGENTS.md rule that tests must never be weakened simply to pass.
3. **Optimistic Error Handlers & Rollbacks**: Both Web (`scheduleStore.ts`) and iOS (`ScheduleViewModel.swift`) feature snapshot rollback on mutation failures with clear user feedback (dismissible banner on Web, `errorMessage` state on iOS).
4. **Complete Test Suite Pass**:
   - Web: `vue-tsc --noEmit` passed with 0 errors; `eslint .` passed with 0 errors.
   - iOS: 159 tests passed in `swift test --package-path apps/ios` (including 12 schedule view model tests and 5 schedule service tests).

---

## Recommended Changes
*None.* The client integration slice is ready for commit and merge.
