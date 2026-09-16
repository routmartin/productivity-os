# Plan 006 — macOS Focus Companion

Implement the macOS Focus Companion specified in
`docs/specs/focus/macos-focus-companion.md` (v0.2, after Phase 0
endpoint verification).

## Phase 0 — Spec verification (COMPLETE 2026-09-04)

All six endpoints were verified against `http://localhost:8080`. Findings
were folded back into the spec as v0.2 (see spec revision history). No
backend work is required for v1.

## Phase 1 — Platform cleanup

Goal: make the existing iOS sources compilable on macOS by gating
UIKit-only APIs.

1. `ProductivityOS/Core/Utilities/Haptics.swift` — wrap
   `UIImpactFeedbackGenerator` calls in `#if os(iOS)`. On macOS the
   function body is empty.
2. `ProductivityOS/Features/Focus/FocusPreparationView.swift` — wrap
   `UIApplication.shared.open(url)` in `#if os(iOS)`. The macOS build
   does not include this view (see Phase 2).
3. `ProductivityOS/Features/Authentication/QRScannerView.swift` —
   already iOS-only; exclude it from the macOS target's source list
   in the Xcode project.
4. `ProductivityOS/Features/Profile/DevAPIRequestLogView.swift` —
   wrap the entire file in `#if DEBUG` and verify nothing else in
   the production app references it.
5. `ProductivityOS/Core/Networking/APILogStore.swift` — wrap in
   `#if DEBUG`.
6. Verify `ProductivityOS/Core/Networking/Endpoint.swift` and
   `APIDTOs.swift` do not depend on UIKit; should already be the case
   but confirm.

Tests:

- Existing iOS test suite still passes:
  `xcodebuild -scheme ProductivityOS -destination 'platform=iOS
  Simulator,name=iPhone 15' test`.
- macOS SwiftPM target compiles: `swift build` from `apps/ios`
  (existing `Package.swift` already declares `macOS(.v14)`).

## Phase 2 — Restructure targets around a shared library

Goal: both iOS app and macOS app consume the same compiled
`ProductivityOSCore` library rather than duplicating source files in
two targets.

This phase is the most error-prone. Do it in a focused commit with a
revert plan.

1. In `ProductivityOS.xcodeproj`:
   - Add a new `framework` or `static library` target named
     `ProductivityOSCore` (file path `apps/ios/ProductivityOS`).
   - Move all source files currently in the iOS app target into the
     `ProductivityOSCore` target.
   - The iOS app target becomes thin: just
     `App/ProductivityOSApp.swift`, `Resources/Info.plist`, and
     `Resources/Assets.xcassets`.
   - The macOS app target (`Phase 4`) consumes the same library.
2. Keep `ProductivityOSTests` as is; it imports `ProductivityOSCore`.
3. Update `Package.swift` to match — the existing target name already
   aligns but verify the `exclude` list still covers the iOS-only
   files.

Acceptance: `xcodebuild -scheme ProductivityOS -destination
'platform=iOS Simulator,name=iPhone 15' build` succeeds with no
warnings about UIKit on macOS-like platform slices.

If restructuring targets proves disruptive, fall back to the simpler
approach: duplicate source files between iOS and macOS targets,
gated by `#if os(iOS)` blocks. This is worse long-term but lower-risk
for a v1. The implementer will surface this trade-off to the human
reviewer before choosing.

## Phase 3 — URL-scheme handling

Goal: the Mac app can be launched or focused by clicking
`productivityos://auth?challenge=...`.

1. `ProductivityOS/Resources/Info-macOS.plist`:
   - `LSUIElement = YES` (menu bar app, no Dock icon).
   - `CFBundleURLTypes` with scheme `productivityos`, host
     `auth`, query `challenge`.
2. In `MacCompanionApp.swift`, attach `.onOpenURL { url in ... }` on
   the root `MenuBarExtra` scene.
3. The handler validates the URL shape and calls
   `QRAuthenticationService.shared.authenticate(challenge:)`. This
   service is already used by iOS unchanged.
4. Add `FocusCompanionState.handleAuthenticated(_ user:)` that the
   `.onOpenURL` callback invokes after a successful exchange.
5. Tests:
   - `QRAuthenticationServiceTests` already cover the exchange;
     verify the new path reuses them. If `QRAuthenticationService`
     currently has iOS-specific assumptions (e.g. UIDevice in
     logging), strip them.

## Phase 4 — Mac app target

Goal: ship the menu bar app.

1. In `ProductivityOS.xcodeproj`:
   - Add a new macOS App target named `ProductivityOSMac`.
   - Platform: macOS 14, SwiftUI lifecycle, no Storyboard.
   - Sources: `ProductivityOS/Features/MacCompanion/*.swift`. The
     existing `App/ProductivityOSApp.swift` is NOT included.
   - Resources: `Info-macOS.plist` (URL scheme + LSUIElement).
   - Frameworks: AppKit (auto), SwiftUI (auto).
2. New `@main` `App`:
   `ProductivityOS/Features/MacCompanion/MacCompanionApp.swift`
   - Declares `MenuBarExtra("Productivity OS", systemImage: "timer")`
     with `MenuBarContentView()` as content.
   - Optionally a `Window` scene for the persistent view.
   - `.onOpenURL { ... }` handler calling the pairing flow.
3. Build settings:
   - `MACOSX_DEPLOYMENT_TARGET = 14.0`.
   - `ENABLE_HARDENED_RUNTIME = YES` (default).
   - `CODE_SIGN_STYLE = Automatic` with the user's Development Team
     (developer-specific; document in README).

## Phase 5 — State, polling, and popover UI

1. `FocusCompanionState` (an `@Observable` class):
   - `enum Phase { case unauthenticated, authenticatedIdle,
     activeSession(FocusSessionResponse), error(String) }`
   - Methods: `refresh()`, `endSession()`,
     `handleAuthenticated(user:email:)`.
2. `FocusPoller` (an `actor`):
   - Holds the current interval and a `Task` reference.
   - `start()`, `stop()`, `tick()` methods.
   - Internal backoff: doubles on transient network errors up to 30
     seconds.
   - Skips ticks when `ProcessInfo.processInfo.isLowPowerModeEnabled`
     is true.
3. `MenuBarContentView`:
   - Renders the menu bar label based on `FocusCompanionState.phase`.
   - Holds the popover toggle.
4. `FocusPopoverView`:
   - Switches on `phase`:
     - `unauthenticated` → "Not signed in. Open the web app and click
       'Generate Login QR', then click the link."
     - `authenticatedIdle` → idle message.
     - `activeSession(session)` → `ActiveSessionCard`.
     - `error(message)` → error banner + Retry.
5. `ActiveSessionCard`:
   - Task title, monospaced `mm:ss` / `h:mm:ss` label, End button.
   - End button calls `state.endSession()`; disabled during the
     request.

## Phase 6 — Verification

1. `xcodebuild -scheme ProductivityOSMac -destination 'platform=macOS'
   build` succeeds.
2. Manual smoke:
   - Launch from Xcode with the macOS scheme.
   - Verify no Dock icon, menu bar item visible.
   - In a browser, navigate to `productivityos://auth?challenge=<token>`
     where `<token>` is a fresh challenge created via the web app's
     pairing UI. Verify macOS routes to the app, app authenticates,
     popover shows idle.
   - Start a session on iOS; verify Mac shows ticking timer within
     5s.
   - End from Mac; verify Mac shows idle and iOS reflects end.
3. `xcodebuild -scheme ProductivityOSTests -destination 'platform=iOS
   Simulator,name=iPhone 15' test` — all existing tests still pass.
4. `xcodebuild -scheme ProductivityOSMac -destination 'platform=macOS'
   test` — new macOS tests pass.

## Phase 7 — Docs

1. Update `apps/ios/README.md` with a "macOS companion" section: how
   to build, how to launch from Xcode, that it's menu-bar only, and
   the web-app-driven pairing flow.
2. Update root `Makefile` with `ios-mac-build` and `ios-mac-test`
   targets that wrap `xcodebuild` with the right scheme and
   destination.
3. Move the spec status from `Draft` to `Approved` when the human
   re-approves v0.2. Mark `Implemented` when all phases ship.

## Acceptance Criteria Traceability

| ID | Phase | Status |
|----|-------|--------|
| AC-MAC-01 (menu bar, no Dock) | Phase 4 | pending |
| AC-MAC-02 (URL scheme auth) | Phase 3 + 4 | pending |
| AC-MAC-03 (idle state) | Phase 5 | pending |
| AC-MAC-04 (ticking timer, ±1s) | Phase 5 | pending |
| AC-MAC-05 (End button) | Phase 5 | pending |
| AC-MAC-06 (reconnecting badge) | Phase 5 | pending |
| AC-MAC-07 (401 clears session) | Phase 5 | pending |
| AC-MAC-08 (no UIKit in macOS binary) | Phase 1 + 4 | pending |
| AC-MAC-09 (iOS unchanged) | Phase 2 | pending |
| AC-MAC-10 (no Start button on Mac) | Phase 5 | pending |
| AC-MAC-11 (reused challenge rejected) | Phase 3 + 5 | pending |

## Risks and Rollback

- Phase 2 (target restructure) is the highest-risk phase. If it
  cannot be done cleanly in the first attempt, fall back to source
  duplication flagged with `#if os(iOS)` and document the tech debt.
- All phases are independent enough to ship incrementally; if
  Phase 5+ is blocked, Phase 1 alone is a clean PR.
- Revert plan: each phase is a separate commit; rollback is `git
  revert`.

## Reviewer Checklist (for v0.2)

The human reviewer should specifically confirm:

1. The reversed QR flow direction (Mac consumes, web/iOS produces) is
   acceptable, given it adds a step for the user.
2. The 2-minute challenge TTL is acceptable (verified in
   `QrAuthService.createChallenge`).
3. The Mac app does not gain a Start button.
4. The lack of "Connect Mac" UI in the web app is acceptable for v1
   (the existing "Generate Login QR" works as the producer; the
   user must also click the deep link).
5. The 404 behavior of `/api/v1/focus/active` (vs 200/null) is
   correctly handled.
