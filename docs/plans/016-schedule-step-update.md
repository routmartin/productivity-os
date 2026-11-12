# Plan 016: Schedule Step Update & In-Place Detail Editing

## Status

Verified & Complete

## Specification

### Primary Behavioral Source of Truth

- [daily-schedule-linkmap.md](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/specs/planning/daily-schedule-linkmap.md) (Proposed Amendment: AC-010 to AC-013)

### Acceptance Criteria in Scope

- **AC-010:** Step Details Update & Real-Time Sync (`PUT /api/v1/schedule/steps/{id}`)
- **AC-011:** Anchor Immutability Protection on Update (`400 Bad Request` with `ANCHOR_UPDATE_NOT_ALLOWED`)
- **AC-012:** Step Phase Reassignment & Topological Rewiring
- **AC-013:** User Isolation on Step Update (`404 Not Found` per ADR-004)

### Supporting Decisions & Architectural Guidelines

- **ADR-002: Technology Stack** (Spring Boot 3, Kotlin 1.9+, Vue 3, Pinia, Swift 5.9+, SwiftUI)
- **ADR-003: Database Persistence** (`schedule_entries` and `schedule_habits`, soft-delete invariants, transactional updates)
- **ADR-004: Authentication and User Isolation** (Stateless JWT, `CurrentUser.id()`, no cross-user visibility)
- **ADR-005: API Architecture** (REST `/api/v1`, resource URIs, structured error model, thin controllers)
- **ADR-006: Time and Timezone Handling** (IANA user timezone, `LocalDate`, deterministic date boundaries)
- **ADR-007: Package and Module Layout** (`com.productivityos.schedule` with standard layers)

---

## Architecture & Endpoint Contracts

### 1. Endpoint Contract: `PUT /api/v1/schedule/steps/{id}`

Updates an existing schedule step (either a single-day activity block/break in `schedule_entries` or a recurring habit in `schedule_habits`).

- **HTTP Method:** `PUT`
- **URI:** `/api/v1/schedule/steps/{id}`
- **Path Variable:**
  - `id` (`String`): UUID of the step to update, or anchor identifier (e.g. `anchor-wake`, `anchor-bedtime`).
- **Headers:**
  - `Authorization: Bearer <jwt-token>`
  - `Content-Type: application/json`

#### Request Body (`UpdateScheduleStepRequest`)

```json
{
  "title": "Deep Focus Architecture & System Design",
  "subtitle": "High cognitive load · Core DB schema",
  "phase": "deep-focus",
  "timeSlot": "09:30",
  "durationMinutes": 90,
  "notes": "Ensure all FK constraints and indexes are covered.",
  "iconName": "brain.head.profile",
  "date": "2026-11-12"
}
```

| Field | Type | Validation / Constraints | Nullable | Description |
|---|---|---|---|---|
| `title` | `String` | `@field:NotBlank` | No | Step title / headline |
| `subtitle` | `String` | `@field:Size(max = 500)` | Yes | Secondary explanatory subtitle |
| `phase` | `String` | Must be one of `morning`, `deep-focus`, `afternoon`, `bedtime` | Yes | Target phase container |
| `timeSlot` | `String` | `@field:Size(max = 32)` | Yes | Wall-clock time label or target time (e.g. `09:30`) |
| `durationMinutes` | `Int` | `@field:Min(1)` / `@JsonAlias("totalMinutes")` | Yes | Duration in minutes (defaults to existing value if omitted) |
| `notes` | `String` | Optional protocol notes | Yes | Protocol details or execution advice |
| `iconName` | `String` | Optional icon identifier (used for habits) | Yes | SF Symbol or Lucide icon name |
| `date` | `LocalDate` | Optional calendar date | Yes | Calendar date context for habit history generation |

#### Successful Response (`200 OK`)

Returns the updated `ScheduleNodeDTO`:

```json
{
  "id": "e2a1b9c3-4d5e-6f7a-8b9c-0d1e2f3a4b5c",
  "type": "task",
  "phase": "deep-focus",
  "title": "Deep Focus Architecture & System Design",
  "subtitle": "High cognitive load · Core DB schema",
  "time": "09:30",
  "durationMinutes": 90,
  "inFocus": false,
  "completedMinutes": 0,
  "totalMinutes": 90,
  "notes": "Ensure all FK constraints and indexes are covered.",
  "order": 6
}
```

#### Error Responses

1. **Anchor Mutation Rejection (`400 Bad Request`):**
   When `{id}` starts with `anchor-` or equals `anchor-wake` / `anchor-bedtime`:
   ```json
   {
     "code": "ANCHOR_UPDATE_NOT_ALLOWED",
     "message": "Anchor node update is not allowed",
     "traceId": "7f8a9b0c"
   }
   ```
2. **Step Not Found or Cross-User Access (`404 Not Found`):**
   When `{id}` is not found or owned by a different user:
   ```json
   {
     "code": "NOT_FOUND",
     "message": "Schedule node not found: e2a1b9c3-4d5e-6f7a-8b9c-0d1e2f3a4b5c",
     "traceId": "7f8a9b0c"
   }
   ```
3. **Invalid Request Payload (`400 Bad Request`):**
   When `title` is blank, `durationMinutes <= 0`, or `phase` is invalid:
   ```json
   {
     "code": "VALIDATION_ERROR",
     "message": "Request validation failed",
     "details": [
       { "field": "title", "message": "must not be blank" }
     ],
     "traceId": "7f8a9b0c"
   }
   ```

---

## Implementation Slices

### Slice 1: Backend Vertical Implementation (`apps/api`)

#### Step 1.1: Request DTO
- **Files:** `apps/api/src/main/kotlin/com/productivityos/schedule/dto/UpdateScheduleStepRequest.kt`
- **Spec / AC:** AC-010
- **Behavior:**
  Define Kotlin data class `UpdateScheduleStepRequest` with Bean Validation annotations:
  - `@field:NotBlank val title: String`
  - `val subtitle: String? = null`
  - `val phase: String? = null`
  - `val timeSlot: String? = null`
  - `@field:Min(1) @JsonAlias("totalMinutes") val durationMinutes: Int? = null`
  - `val iconName: String? = null`
  - `val notes: String? = null`
  - `val date: LocalDate? = null`
- **Dependencies:** Jakarta validation constraints, Jackson annotations.

#### Step 1.2: Domain Exception & Exception Handler
- **Files:**
  - `apps/api/src/main/kotlin/com/productivityos/schedule/exception/ScheduleExceptions.kt`
  - `apps/api/src/main/kotlin/com/productivityos/api/GlobalExceptionHandler.kt`
- **Spec / AC:** AC-011
- **Behavior:**
  - Add `class AnchorUpdateNotAllowedException(message: String = "Anchor node update is not allowed") : RuntimeException(message)` to `ScheduleExceptions.kt`.
  - Add `@ExceptionHandler(AnchorUpdateNotAllowedException::class)` in `GlobalExceptionHandler.kt` returning `400 BAD_REQUEST` with `code = "ANCHOR_UPDATE_NOT_ALLOWED"`.

#### Step 1.3: Service Layer Update Logic
- **Files:** `apps/api/src/main/kotlin/com/productivityos/schedule/service/ScheduleService.kt`
- **Spec / AC:** AC-010, AC-011, AC-012, AC-013
- **Behavior:**
  Implement `fun updateStep(userId: UUID, stepId: String, request: UpdateScheduleStepRequest): ScheduleNodeDTO`:
  1. Check anchor guard: If `stepId == ANCHOR_WAKE_ID || stepId == ANCHOR_BEDTIME_ID || stepId.startsWith("anchor-")`, throw `AnchorUpdateNotAllowedException`.
  2. Parse UUID: If invalid format, throw `ScheduleNodeNotFoundException("Invalid step id: $stepId")`.
  3. Validate phase if provided: Must belong to `{ "morning", "deep-focus", "afternoon", "bedtime" }`. Throw `IllegalArgumentException` if invalid.
  4. Query `scheduleEntryRepository.findByIdAndUserIdAndDeletedAtIsNull(uuid, userId)`. If present:
     - Update `entry.title = request.title.trim()`
     - Update `entry.subtitle = request.subtitle?.trim()`
     - If `request.phase` is provided: `entry.phase = request.phase`
     - If `request.timeSlot` is provided: `entry.timeLabel = request.timeSlot.trim()`
     - If `request.durationMinutes` is provided: `entry.durationMinutes = request.durationMinutes`
     - If `request.notes` is provided: `entry.notes = request.notes.trim()`
     - Save and map to `ScheduleNodeDTO`.
  5. Query `scheduleHabitRepository.findByIdAndUserIdAndDeletedAtIsNull(uuid, userId)`. If present:
     - Update `habit.title = request.title.trim()`
     - Update `habit.subtitle = request.subtitle?.trim()`
     - If `request.iconName` is provided: `habit.icon = request.iconName.trim()`
     - If `request.phase` is provided: `habit.phase = request.phase`
     - If `request.timeSlot` is provided: `habit.targetTime = request.timeSlot.trim()`
     - If `request.durationMinutes` is provided: `habit.durationMinutes = request.durationMinutes`
     - If `request.notes` is provided: `habit.notes = request.notes.trim()`
     - Save habit, compute streak and 14-day history window for `date` (or user today), and map to `ScheduleNodeDTO`.
  6. If neither found, throw `ScheduleNodeNotFoundException("Schedule node not found: $stepId")`.

#### Step 1.4: Controller Endpoint
- **Files:** `apps/api/src/main/kotlin/com/productivityos/schedule/controller/ScheduleController.kt`
- **Spec / AC:** AC-010, AC-011, AC-012, AC-013
- **Behavior:**
  Add endpoint:
  ```kotlin
  @PutMapping("/steps/{id}")
  fun updateStep(
      @PathVariable("id") id: String,
      @Valid @RequestBody request: UpdateScheduleStepRequest
  ): ResponseEntity<ScheduleNodeDTO> {
      val updated = scheduleService.updateStep(currentUser.id(), id, request)
      return ResponseEntity.ok(updated)
  }
  ```

#### Step 1.5: Backend Automated Verification
- **Files:**
  - `apps/api/src/test/kotlin/com/productivityos/schedule/ScheduleControllerTest.kt`
  - `apps/api/src/test/kotlin/com/productivityos/schedule/service/ScheduleServiceTest.kt`
- **Tests to Add:**
  - `updateStep returns 200 OK with updated ScheduleNodeDTO`
  - `updateStep on anchor node returns 400 Bad Request with ANCHOR_UPDATE_NOT_ALLOWED`
  - `updateStep for non-existent or foreign node returns 404 Not Found`
  - `updateStep with blank title returns 400 Bad Request with VALIDATION_ERROR`
  - `service updates ScheduleEntryEntity fields and preserves order`
  - `service updates ScheduleHabitEntity and retains streak history`
  - `service throws IllegalArgumentException on invalid phase string`

---

### Slice 2: Web Client Implementation (`apps/web`)

#### Step 2.1: Types & API Client
- **Files:**
  - `apps/web/src/features/planning/types.ts`
  - `apps/web/src/features/planning/scheduleApi.ts`
- **Spec / AC:** AC-010
- **Behavior:**
  - Add `UpdateStepPayload` interface in `types.ts`:
    ```typescript
    export interface UpdateStepPayload {
      title: string
      subtitle?: string
      phase?: SchedulePhaseId | string
      timeSlot?: string
      durationMinutes?: number
      totalMinutes?: number
      notes?: string
      iconName?: string
      date?: string
    }
    ```
  - Add `updateStep` in `scheduleApi.ts`:
    ```typescript
    async function updateStep(stepId: string, payload: UpdateStepPayload): Promise<ScheduleNode> {
      return apiClient.put<ScheduleNode>(`${BASE}/steps/${stepId}`, payload)
    }
    ```

#### Step 2.2: Pinia Store Mutation & Optimistic Sync
- **Files:** `apps/web/src/features/planning/scheduleStore.ts`
- **Spec / AC:** AC-010, AC-012
- **Behavior:**
  Implement `async function updateStep(stepId: string, payload: UpdateStepPayload): Promise<ScheduleNode>`:
  1. Guard against anchor updates: If node is anchor, return immediately.
  2. Snapshot previous node and edges for optimistic rollback.
  3. Mutate node in `graph.value.nodes`: update title, subtitle, duration, time, notes, icon, and phase.
  4. If `phase` changed:
     - Re-sort / re-position node into new phase partition.
     - Dynamically rebuild graph edges via existing topological rewiring logic (`from.phase != to.phase -> 'phase'`).
  5. Trigger `recalculateBedtime()` to reflect any change in activity duration or habit count.
  6. Dispatch `await scheduleApi.updateStep(stepId, payload)`.
  7. On API failure: rollback snapshot and set `errorMessage`.

#### Step 2.3: In-Place Editing UI in Step Detail Dialog
- **Files:** `apps/web/src/features/planning/components/ScheduleContextPanel.vue`
- **Spec / AC:** AC-010, AC-011, AC-012
- **Behavior:**
  - Add "Edit Step" button in the dialog header / actions bar (hidden when `node.type === 'anchor'`).
  - Introduce `isEditing = ref(false)` state.
  - When editing is active, render form inputs with two-way bindings:
    - Title (`UiInput` or standard text input with autofocus)
    - Subtitle (`UiInput`)
    - Phase (`UiSelect` dropdown: Morning, Deep Focus, Afternoon, Bedtime)
    - Scheduled Time (`UiInput type="time"`)
    - Duration Minutes (`UiInput type="number" min="5" step="5"`)
    - Protocol Notes (`textarea` with 3 rows)
  - Footer provides "Cancel" (reverts form) and "Save Changes" (submits `updateStep`, shows saving spinner).
  - Esc key cancels edit mode; form submit triggers save.

#### Step 2.4: Frontend Automated Tests
- **Files:** `apps/web/src/features/planning/__tests__/scheduleStore.spec.ts`
- **Tests to Add:**
  - Store updates step fields and persists to backend via `scheduleApi.updateStep`.
  - Store dynamically rewires edges when node phase is reassigned.
  - Bedtime recalculates when activity duration increases.
  - Anchor nodes cannot be updated and reject edit actions.

---

### Slice 3: iOS Client Implementation (`apps/ios`)

#### Step 3.1: Wire DTO & Endpoint Definition
- **Files:**
  - `apps/ios/ProductivityOS/Core/Networking/APIDTOs.swift`
  - `apps/ios/ProductivityOS/Core/Networking/Endpoint.swift`
- **Spec / AC:** AC-010
- **Behavior:**
  - Add `UpdateScheduleStepRequestBody: Codable, Sendable` in `APIDTOs.swift`.
  - Add case `.updateScheduleStep(id: String, body: Data)` in `AppEndpoint` in `Endpoint.swift` mapping to `PUT /api/v1/schedule/steps/\(id)`.

#### Step 3.2: ScheduleService Integration
- **Files:** `apps/ios/ProductivityOS/Core/Services/ScheduleService.swift`
- **Spec / AC:** AC-010
- **Behavior:**
  - Add `func updateStep(id: String, payload: UpdateStepPayload, for date: Date) async throws -> ScheduleNode` to `ScheduleServicing` protocol and `ScheduleService` class.

#### Step 3.3: ScheduleViewModel Mutation & State Parity
- **Files:** `apps/ios/ProductivityOS/Features/Schedule/ScheduleViewModel.swift`
- **Spec / AC:** AC-010, AC-012
- **Behavior:**
  - Implement `updateStep(id: String, payload: UpdateStepPayload) async throws`:
    - Guard against anchor nodes.
    - Apply optimistic update in `graph.nodes`.
    - If phase changed, re-sequence and rewire edges using `rewireEdges()`.
    - Recalculate bedtime projection.
    - Call service; roll back on failure.

#### Step 3.4: ScheduleNodeDetailSheet Edit Mode
- **Files:** `apps/ios/ProductivityOS/Features/Schedule/Sheets/ScheduleNodeDetailSheet.swift`
- **Spec / AC:** AC-010, AC-011
- **Behavior:**
  - Add "Edit" button to navigation toolbar (disabled/hidden for anchors).
  - Support an editing state or present dedicated `ScheduleEditStepSheet.swift`.
  - Allow updating title, subtitle, phase, target time, duration minutes, and notes.
  - On save, invoke `viewModel.updateStep` and dismiss sheet.

#### Step 3.5: iOS Automated Tests
- **Files:**
  - `apps/ios/ProductivityOSTests/ScheduleServiceTests.swift`
  - `apps/ios/ProductivityOSTests/ScheduleViewModelTests.swift`
- **Tests to Add:**
  - `ScheduleService.updateStep` formats JSON payload and sends `PUT` request to correct URI.
  - `ScheduleViewModel.updateStep` updates node attributes in state and updates bedtime overflow.
  - Anchor nodes are protected from update calls.

---

## Traceability Matrix

| Acceptance Criteria | Plan Step | Primary File(s) Changed | Verification Method |
|---|---|---|---|
| **AC-010: Step Details Update & Real-Time Sync** | Steps 1.1, 1.3, 1.4, 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 3.4 | `UpdateScheduleStepRequest.kt`, `ScheduleService.kt`, `ScheduleController.kt`, `scheduleStore.ts`, `ScheduleContextPanel.vue`, `ScheduleViewModel.swift` | MockMvc PUT 200, Pinia store unit test, iOS ViewModel test |
| **AC-011: Anchor Immutability Protection** | Steps 1.2, 1.3, 2.2, 2.3, 3.3, 3.4 | `AnchorUpdateNotAllowedException.kt`, `GlobalExceptionHandler.kt`, `ScheduleService.kt`, `ScheduleContextPanel.vue` | MockMvc returns 400 `ANCHOR_UPDATE_NOT_ALLOWED`, UI hides edit button for anchors |
| **AC-012: Step Phase Reassignment & Topological Rewiring** | Steps 1.3, 2.2, 3.3 | `ScheduleService.kt`, `scheduleStore.ts`, `ScheduleViewModel.swift` | Unit tests verify node moves to new phase and edge list contains no orphaned links |
| **AC-013: User Isolation on Step Update** | Step 1.3 | `ScheduleService.kt` | Unit test verifying user cannot update another user's step (returns 404) |

---

## Verification Checklist

Per `AGENTS.md`, each milestone must be verified before presenting completion:

- [x] **Backend Verification (`apps/api`):**
  - Run `./gradlew :apps:api:test` — all unit and integration tests must pass.
  - Verify error response format matching ADR-005 structured error standard (`code`, `message`, `traceId`).
- [x] **Web Frontend Verification (`apps/web`):**
  - Run `pnpm run typecheck` — zero TypeScript compilation errors.
  - Run `pnpm run lint` — zero ESLint violations.
  - Run `pnpm run test:unit` — all store and component tests pass.
- [x] **iOS Verification (`apps/ios`):**
  - Run `swift test --package-path apps/ios` — all unit tests pass.
- [x] **Review Loop:**
  - Execute independent review via `scripts/agent-review.sh` or `code-reviewer` agent.

---

## Pre-Implementation Decisions (Must Be Resolved First)

The following decisions are open for human approval:

- **D1: Step Detail Editing UX Mode (Web & iOS)**
  - *Option A (Recommended for Web):* In-Place Form Toggle inside `ScheduleContextPanel.vue`. Clicking "Edit Step" swaps view cards for input controls in the same dialog surface.
  - *Option B (Recommended for iOS):* Sheet-over-sheet modal or navigation destination (`ScheduleEditStepSheet.swift`) spawned from the inspection sheet toolbar.
  - *Status:* **OPEN — Pending Human Decision.**
- **D2: Anchor Node Handling (Wake Up & Bedtime Target)**
  - *Option A (Recommended):* Total immutability via `/api/v1/schedule/steps/{id}`. Generic step update calls reject anchor IDs with `400 Bad Request` (`ANCHOR_UPDATE_NOT_ALLOWED`). Anchor targets remain strictly configured via user circadian profile settings in a separate future plan.
  - *Option B:* Allow updating anchor target times (e.g. Wake time `06:30` -> `07:00`) directly via `PUT /api/v1/schedule/steps/anchor-wake`.
  - *Status:* **OPEN — Recommending Option A to preserve circadian invariants.**
- **D3: Habit Update Scope (Routine Blueprint vs Single Day)**
  - *Behavior:* In the current architecture, habits in `schedule_habits` represent recurring daily blueprints (AC-009). Updating a habit updates the routine definition and propagates to future days. Updating an activity block in `schedule_entries` only updates that specific calendar date.
  - *Status:* **CONFIRMED per ADR-003 and existing schema design.**

---

## Out of Scope for This Plan

- Modifying user wake/bedtime circadian profile defaults (reserved for user settings / circadian calibration).
- Drag-and-drop node reordering across phases (step phase selector handles reassignment).
- Historical habit occurrence batch alterations (habits maintain streak history).
- External Calendar 2-way sync (Google Calendar / Outlook).

---

## Change History

- **2026-11-12:** Initial Draft created for Schedule Step Update feature spanning Backend (`apps/api`), Web Frontend (`apps/web`), and iOS (`apps/ios`).
