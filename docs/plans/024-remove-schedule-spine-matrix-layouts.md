# Plan 024: Remove Schedule Spine and Matrix Layout Projections

## Status
Approved by Human (2026-11-18; iOS retained unchanged per human guidance)

---

## 1. Specification Reference

### Primary Behavioral Source of Truth
- [docs/specs/planning/daily-schedule-linkmap.md](file:///Users/metamartin/Documents/RoutMartin/productivity-os/docs/specs/planning/daily-schedule-linkmap.md) (Approved, Amended 2026-11-18)

### Acceptance Criteria in Scope
- **AC-001 (amended):** Canonical Serpentine Journey Link-Map Layout & Legacy Preference Migration
- **AC-003:** Native Activity Execution Toggle (Serpentine Journey parity)
- **AC-007:** In-Line Step Creation (`+` Popover) in Serpentine Journey layout
- **AC-010:** Step Details Update & Real-Time Sync in Serpentine Journey link-map
- **AC-012:** Step Phase Reassignment & Topological Rewiring in Serpentine Journey layout

### Supporting Decisions and Constraints
- **ADR-001:** SDD Workflow (Specification before implementation; human approval gate)
- **ADR-002:** Technology Stack (Vue 3, Pinia, TypeScript, Vite for `apps/web`; Swift 5.9+, SwiftUI for `apps/ios`)
- **ADR-006:** Timezone Authority (Circadian schedule continuity maintained)

---

## 2. Architectural Decisions & Product Choices

### D1: Complete Removal of `ScheduleViewSwitcher` vs Retention
- **Context:**
  The Daily Schedule link-map originally featured three visual projections: Central Spine (`spine`), Serpentine Journey (`journey`), and Swimlane Matrix (`matrix`). A segmented control (`ScheduleViewSwitcher`) was exposed in the header allowing users to toggle between them.
  Product evaluation established the Serpentine Journey layout as the canonical circadian representation. On iOS, Plan 023 already moved `ScheduleView.swift` to render `ScheduleJourneyLayoutView` directly alongside a "Routine vs Deep Work" tab.
- **Options Evaluated:**
  - *Option A (Recommended):* Completely remove `ScheduleViewSwitcher` on both Web and iOS, and delete the switcher components (`ScheduleViewSwitcher.vue`, `ScheduleViewSwitcher.swift`).
  - *Option B:* Retain `ScheduleViewSwitcher` as a single-option disabled/hidden control. (Adds clutter and zero user value).
- **Decision:** **Option A (Complete Removal)**.
  - Eliminates visual noise in `SchedulePage.vue` header, providing breathing room for the date banner and primary `Add Step` button.
  - Aligns Web and iOS architectures to render the Serpentine Journey link-map directly.
  - Removes dead code and unused components.

### D2: Legacy Layout Preference Migration & Fallback in Client Storage
- **Context:**
  Existing users on web (`localStorage.getItem('productivity-os:schedule-layout')`) and iOS (`UserDefaults.standard.string(forKey: "productivity-os:schedule-layout")`) may have saved `"spine"` or `"matrix"` from prior sessions.
- **Options Evaluated:**
  - *Option A (Recommended):* Explicit fallback and auto-migration. If client storage contains `"spine"` or `"matrix"`, normalize the value to `"journey"` and overwrite storage with `"journey"`.
  - *Option B:* Delete storage key without migration. If unmanaged, older code or tests could read invalid values.
- **Decision:** **Option A (Explicit Auto-Migration)**.
  - In `apps/web/src/features/planning/scheduleStore.ts`: `getSavedLayout()` checks for `"journey"`; any other value (including `"spine"` or `"matrix"`) normalizes to `"journey"` and updates `localStorage`.
  - In `apps/ios/ProductivityOS/Features/Schedule/ScheduleViewModel.swift`: `loadSavedLayout()` checks `ScheduleLayoutMode(rawValue: raw)`; if not matching `.journey`, resets `UserDefaults` to `"journey"` and returns `.journey`.
  - In `types.ts` and `Schedule.swift`: `ScheduleLayoutMode` simplifies to only support `'journey'`, retiring `'spine'` and `'matrix'`.

### D3: Scope of Node Styles Cleanup
- **Context:**
  `ScheduleAnchorNode.vue`, `ScheduleHabitNode.vue`, and `ScheduleTaskNode.vue` contain minor `.compact` CSS classes originally introduced for matrix table cells.
- **Decision:**
  Retain generic `.compact` rules in node components to avoid breaking drawer or mini-inspection views, but remove all matrix-specific container files (`ScheduleMatrixLayout.vue`) and spine-specific files (`ScheduleSpineLayout.vue`).

### D4: Scope Exemption for iOS Application (`apps/ios`)
- **Context:**
  During the Human Approval Gate, the user explicitly instructed: *"one thing keep ios the same. after rewind approve and execute the plan"*.
- **Decision:**
  Keep `apps/ios` entirely untouched. No swift files, Xcode configurations, or iOS tests will be altered. All Spine and Matrix removal is scoped strictly to Web (`apps/web`).

---

## 3. Agent Delegation Matrix

| Agent | Target Slice | Owned Files / Scope | Verification Command | Dispatch Brief |
| :--- | :--- | :--- | :--- | :--- |
| `@frontend` | Slice 1: Web Frontend Refactoring & Cleanup | `apps/web/src/pages/SchedulePage.vue`<br>`apps/web/src/features/planning/scheduleStore.ts`<br>`apps/web/src/features/planning/types.ts`<br>`apps/web/src/features/planning/components/ScheduleViewSwitcher.vue` *(delete)*<br>`apps/web/src/features/planning/components/layouts/ScheduleSpineLayout.vue` *(delete)*<br>`apps/web/src/features/planning/components/layouts/ScheduleMatrixLayout.vue` *(delete)* | `pnpm --filter @productivity-os/web run typecheck && pnpm --filter @productivity-os/web test:unit` | Remove layout switcher, retire Spine & Matrix components, bind Serpentine Journey directly, normalize store preferences |
| `@code-reviewer` | Slice 2: Verification & SDD Compliance Audit | Full Git Diff across `apps/web`, `docs/specs`, `docs/plans` | `./scripts/agent-review.sh` | Verify zero regression against spec ACs, verify clean build, no orphaned imports, no broken references |

---

## 4. Step-by-Step Implementation Tasks

### Step 1: Update Frontend Types & Schedule Store (`apps/web`)
- **Files Affected:**
  - `apps/web/src/features/planning/types.ts`
  - `apps/web/src/features/planning/scheduleStore.ts`
- **Spec / AC:** `AC-001 (amended)`
- **Detailed Action:**
  1. In `types.ts`:
     - Update `ScheduleLayoutMode`:
       ```typescript
       export type ScheduleLayoutMode = 'journey'
       ```
  2. In `scheduleStore.ts`:
     - Update `getSavedLayout()`:
       ```typescript
       function getSavedLayout(): ScheduleLayoutMode {
         if (typeof window === 'undefined') return 'journey'
         const saved = localStorage.getItem(STORAGE_KEY)
         if (saved === 'journey') {
           return saved
         }
         // Gracefully migrate legacy preferences ('spine' | 'matrix') to 'journey'
         try {
           localStorage.setItem(STORAGE_KEY, 'journey')
         } catch {
           // Ignore storage write issues
         }
         return 'journey'
       }
       ```
     - Ensure `activeLayout` defaults to `journey`.
     - Update `setLayout(mode: ScheduleLayoutMode)` to enforce `'journey'` and keep backward compatibility.
- **Verification Command:** `pnpm --filter @productivity-os/web run typecheck`

### Step 2: Refactor `SchedulePage.vue` & Direct Serpentine Journey Binding (`apps/web`)
- **Files Affected:**
  - `apps/web/src/pages/SchedulePage.vue`
- **Spec / AC:** `AC-001 (amended)`, `AC-003`, `AC-007`
- **Detailed Action:**
  1. Remove imports:
     - `ScheduleViewSwitcher`
     - `ScheduleMatrixLayout`
     - `ScheduleSpineLayout`
  2. In `<script setup>`:
     - Remove `activeLayoutComponent` computed property.
  3. In `<template>`:
     - Remove `<ScheduleViewSwitcher v-model="scheduleStore.activeLayout" />` from `.header-right`.
     - In `<main class="schedule-canvas">`:
       Replace `<component :is="activeLayoutComponent" @add-step="onOpenAddStep" />` with direct rendering:
       ```html
       <ScheduleJourneyLayout @add-step="onOpenAddStep" />
       ```
- **Verification Command:** `pnpm --filter @productivity-os/web run typecheck && pnpm --filter @productivity-os/web test:unit`

### Step 3: Delete Retired Web Layout Components (`apps/web`)
- **Files Affected:**
  - `apps/web/src/features/planning/components/ScheduleViewSwitcher.vue` *(delete)*
  - `apps/web/src/features/planning/components/layouts/ScheduleSpineLayout.vue` *(delete)*
  - `apps/web/src/features/planning/components/layouts/ScheduleMatrixLayout.vue` *(delete)*
- **Spec / AC:** `AC-001 (amended)`
- **Detailed Action:**
  - Delete `ScheduleViewSwitcher.vue`, `ScheduleSpineLayout.vue`, and `ScheduleMatrixLayout.vue`.
  - Verify no lingering imports across `apps/web`.
- **Verification Command:** `pnpm --filter @productivity-os/web run typecheck && pnpm --filter @productivity-os/web run lint`

### Step 4: Out of Scope for Implementation (iOS Retained As-Is)
- Per human directive: *"one thing keep ios the same. after rewind approve and execute the plan"*, `apps/ios` is entirely retained in its current state without modification.
- iOS already renders `ScheduleJourneyLayoutView` directly in `ScheduleView.swift` (via Plan 023).

---

## 5. Traceability Matrix

| Acceptance Criteria | Description | Target Slices / Steps | Verifying Tests | Status |
| :--- | :--- | :--- | :--- | :--- |
| **AC-001 (amended)** | Canonical Serpentine Journey Link-Map Layout & Legacy Preference Migration | Step 1, Step 2, Step 3 | `scheduleStore.spec.ts` | Pending Implementation |
| **AC-003** | Native Activity Execution Toggle (in Serpentine Journey layout) | Step 2 | Existing `ScheduleJourneyLayout.vue` | Pending Implementation |
| **AC-007** | In-Line Step Creation (`+` Popover) in Serpentine Journey layout | Step 2 | Existing `ScheduleAddStepDialog.vue` | Pending Implementation |
| **AC-010** | Step Details Update & Real-Time Sync in Serpentine Journey link-map | Step 2 | Existing `scheduleStore.spec.ts` (`AC-010`) | Pending Implementation |
| **AC-012** | Step Phase Reassignment & Dynamic Rewiring in Serpentine Journey | Step 2 | Existing `scheduleStore.spec.ts` (`AC-012`) | Pending Implementation |

---

## 6. Verification & QA Matrix

| Area | Verification Mechanism | Target Command | Acceptance Threshold |
| :--- | :--- | :--- | :--- |
| **Web Type Safety** | TypeScript type check | `npm --prefix apps/web run typecheck` | 0 errors |
| **Web Code Quality** | ESLint static analysis | `npm --prefix apps/web run lint` | 0 errors |
| **Web Unit Tests** | Vitest test runner | `npm --prefix apps/web run test:unit` | All tests pass (67/67+) |
| **iOS Regression Check** | Swift Package Manager | `swift test --package-path apps/ios` | 0 build errors; all 201+ tests pass |
| **Dead Code Elimination** | Search for deleted symbols in web | `grep -rnEI "ScheduleSpineLayout|ScheduleMatrixLayout|ScheduleViewSwitcher" apps/web/src` | 0 references in active web source code |
| **Code Review** | Automated review script | `./scripts/agent-review.sh` | PASS (Verdict: APPROVED) |

---

## 7. Pre-Implementation Decisions (Resolved)

- **D1: Complete Removal of `ScheduleViewSwitcher` from Web**
  - **Decision:** Remove `ScheduleViewSwitcher` completely on Web, freeing header real-estate.
  - **Status:** APPROVED by Human.
- **D2: Legacy Storage Normalization on Web**
  - **Decision:** Gracefully auto-migrate any stored `"spine"` or `"matrix"` key in `localStorage` to `"journey"`.
  - **Status:** APPROVED by Human.
- **D4: Keep iOS Unchanged**
  - **Decision:** Do not touch `apps/ios`.
  - **Status:** APPROVED by Human.

---

## 8. Out of Scope for This Plan

- Modifying the underlying Schedule activity graph data model (`ScheduleGraph`, `ScheduleNode`, `ScheduleEdge`, `SchedulePhase`).
- Modifying backend APIs or database tables (`apps/api`).
- Modifying iOS application code, tests, or project configurations (`apps/ios`).
- Modifying Step Detail modal inspection dialogs or node creation workflows.

---

## 9. Change History

- **2026-11-18:** Initial Draft created for Plan 024 ("Remove Schedule Spine and Matrix Layout Projections"). Establishes 6 implementation steps across Web and iOS slices, Pre-Implementation Decisions D1–D3, and full traceability matrix against amended `AC-001` through `AC-012`.
