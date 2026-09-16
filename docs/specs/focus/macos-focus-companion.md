# macOS Focus Companion

**Status:** Approved (v0.2, approved 2026-09-08) — Implementation complete (Phase 1 + Phase 2-5 sources in working tree). Testing skipped per instruction; manual verification (Phase 6) and test fixes (crash in `FocusCompanionStateTests`) remain as follow-up.

## Revision History

- **v0.2 (2026-09-04, approved 2026-09-08)** — Reversed QR pairing flow after Phase 0 verification
  showed `POST /api/v1/auth/qr/challenge` requires an authenticated session
  and `POST /api/v1/auth/qr/exchange` is anonymous. The Mac companion now
  *consumes* challenges produced by the web or iOS app, not the other way
  around. All paths prefixed with `/api/v1/`. Removed invented `deepLink`
  response field.
- **v0.1 (2026-09-04)** — Initial draft. Inverted the QR flow direction;
  superseded by v0.2.

## Purpose

Provide a lightweight macOS companion that surfaces the user's currently
active Focus Session in the menu bar so a user who started a focus session
on iOS can see elapsed time and complete the session from their Mac without
picking up their phone.

The companion is read-mostly: the iOS app remains the only place a Focus
Session can be **started**. The Mac companion **displays** the active
session and lets the user **end** it.

## User Story

As a user who started a focus session on my iPhone, I want a small indicator
on my MacBook menu bar that shows my focus session is running and how long
it has been going. When I am done, I want to end the session from the Mac
without unlocking my phone.

## Scope

In scope:

- A new macOS app target sharing the existing `ProductivityOS` Swift sources.
- Menu bar (`MenuBarExtra`) UI showing session status and elapsed time.
- A popover with session details and an End button.
- URL-scheme handling for `productivityos://auth?challenge=...` deep links
  produced by the existing web app pairing flow.
- Polling `GET /api/v1/focus/active` to mirror state from the API.
- Reuse of existing `AuthSession`, `APIClient`, `FocusService`, and `Core`
  modules.

Out of scope:

- Starting a Focus Session from the Mac.
- Push notifications.
- Multiple concurrent sessions (already forbidden by the backend).
- Calendar / reminder integration.
- A signed/notarized release pipeline.
- New web app or iOS app UI. The web app's "Generate Login QR" button
  (in `apps/web/src/pages/SettingsPage.vue`) already produces the deep
  link the Mac consumes. No new web work is required for v1.

## Authentication on macOS

Authentication is a **handoff**, not a self-initiated flow. The backend
QR challenge model is:

- A logged-in user (on web or iOS) calls
  `POST /api/v1/auth/qr/challenge` and receives
  `{ challenge, expiresAt }`. The challenge expires after 2 minutes
  (verified — see `QrAuthService.createChallenge`).
- A new (anonymous) device presents that challenge to
  `POST /api/v1/auth/qr/exchange` and receives a fresh `accessToken` plus
  a `refresh_token` cookie. The session is for the same user that
  created the challenge.
- The exchange endpoint rejects reused or expired challenges with 401
  (`invalid_challenge`, `challenge_already_used`, `challenge_expired`).

For the Mac, the user triggers the handoff from the **web app**:

1. User opens the web app's Settings page and clicks "Generate Login QR".
2. The web app calls `/api/v1/auth/qr/challenge` and renders a QR plus
   the deep link `productivityos://auth?challenge=<token>`.
3. User clicks the deep link. macOS routes it to the Productivity OS Mac
   app because the app registers the `productivityos` URL scheme.
4. The Mac app parses the challenge from the URL, calls
   `POST /api/v1/auth/qr/exchange` (no auth header needed), receives
   `accessToken` + `user`, and stores them via `AuthSession`.

If the user does not have the web app open, the Mac popover can show a
help string pointing them to `productivity-os.app/settings` (out of scope:
the actual link).

**Important:** the Mac does not generate challenges itself. It does not
display a QR. It only consumes challenges. This is the opposite of the
v0.1 spec and is required by the existing backend contract.

## Behavior

### Surface

- The app launches as a menu bar item only. No Dock icon, no main window
  opened at launch. Achieved with `LSUIElement = YES` in the macOS Info.plist.
- Clicking the menu bar item opens a popover anchored to the menu bar.
- An optional "Open Window" affordance in the popover opens a small
  resizable window with the same content for users who want it persistent.

### Menu bar icon and label

The menu bar text reflects the current state:

| State | Label |
|-------|-------|
| Unauthenticated | `P/OS` |
| Authenticated, no active session | `P/OS · idle` |
| Active session, less than 1 hour elapsed | `P/OS · 12:34` (mm:ss) |
| Active session, 1 hour or more elapsed | `P/OS · 1:02:34` (h:mm:ss) |

Elapsed time is computed locally from the server-authoritative `startedAt`
timestamp; the Mac does not trust its local clock over the server clock.

### Active session display

When `GET /api/v1/focus/active` returns a session (200 with body), the
popover shows:

- Task title (from `FocusSessionResponse.taskTitle`).
- Elapsed time, ticking every second locally.
- A single "End session" button.

There is no Pause. The backend has no Pause concept; ending the session
ends it. (Future spec may add pause.)

When the endpoint returns **404** (no active session), the popover shows
"Idle — no focus session active".

### Ending a session from the Mac

Tapping "End session" calls `POST /api/v1/focus/{id}/end` via the existing
`FocusService.end(sessionId:)` method. On success the popover returns to
the "idle" state. On failure it shows an inline error and a Retry button.
The button is disabled while the request is in flight.

### Polling

| Condition | Interval |
|-----------|----------|
| Unauthenticated | No polling |
| Authenticated, no active session, popover open | Every 60 seconds |
| Authenticated, active session | Every 5 seconds |
| Authenticated, popover closed | Every 60 seconds |

Polling pauses when `ProcessInfo.processInfo.isLowPowerModeEnabled` is
true. We do not wake the machine from sleep.

Polling is implemented in a dedicated `FocusPoller` actor that publishes
state to a `@Observable` `FocusCompanionState` view-model.

### Offline and error states

- Network error while polling: keep showing last known state, dim the
  timer, show a small "Reconnecting…" badge in the popover footer. Retry
  on the next tick.
- 401 from the API: clear `AuthSession`, return to the "Not signed in"
  state with a help message pointing the user to the web app to start
  pairing.
- 404 on `/api/v1/focus/active`: treat as "no active session" (this is
  the normal idle response).

### Notifications and background work

No notifications, no background URLSession. The companion is
foreground-only. If the menu bar app is quit, the session continues on
the iOS device and the backend; only the mirror is gone.

## URL Scheme

The Mac app registers the `productivityos` URL scheme. The `Info-macOS.plist`
includes:

```
CFBundleURLTypes:
  - CFBundleURLName: com.productivityos.app
    CFBundleURLSchemes:
      - productivityos
```

On launch via deep link, the app:

1. Reads the URL from `NSAppleEventManager` via the SwiftUI
   `.onOpenURL { url in ... }` modifier on the root scene.
2. Validates `url.scheme == "productivityos"`, `url.host == "auth"`,
   and a `challenge` query item exists.
3. Calls `QRAuthenticationService.authenticate(challenge:)` (already
   exists for iOS, reusable unchanged).
4. Pops a transient confirmation banner in the menu bar: "Connected to
   <user email>".

If the app is already running, `.onOpenURL` fires again on the existing
scene. If the app is not running, the URL handler is invoked at launch
before the menu bar attaches; the menu bar attaches on the next runloop
tick with the authenticated state.

## Platform Conditionals

The shared sources are reorganized so UIKit-only code is excluded from
the macOS build:

| File | Change |
|------|--------|
| `Core/Utilities/Haptics.swift` | Wrap `UIImpactFeedbackGenerator` calls in `#if os(iOS)`. No-ops on macOS. |
| `Features/Focus/FocusPreparationView.swift` | Wrap `UIApplication.shared.open` in `#if os(iOS)`. |
| `Features/Authentication/QRScannerView.swift` | Already iOS-only; exclude it from the macOS target's source list in the Xcode project. |
| `Features/Profile/DevAPIRequestLogView.swift` | Wrap in `#if DEBUG` (already a smell; this PR fixes it). |
| `Core/Networking/APILogStore.swift` | Wrap in `#if DEBUG`. |
| `Resources/Info.plist` (macOS variant) | New file without `UIApplicationSceneManifest`; `LSUIElement = YES`; URL scheme registered. |

## New files

- `ProductivityOS/Features/MacCompanion/MacCompanionApp.swift` — `@main`
  `App` for the macOS target (replaces `App/ProductivityOSApp.swift` for
  that target only).
- `ProductivityOS/Features/MacCompanion/MenuBarContentView.swift` —
  `MenuBarExtra` content tree.
- `ProductivityOS/Features/MacCompanion/FocusPopoverView.swift` — popover
  body covering auth, idle, active, and error states.
- `ProductivityOS/Features/MacCompanion/ActiveSessionCard.swift` —
  task title + elapsed timer + End button.
- `ProductivityOS/Features/MacCompanion/FocusCompanionState.swift` —
  `@Observable` view-model driving the popover.
- `ProductivityOS/Features/MacCompanion/FocusPoller.swift` — actor
  encapsulating the polling loop and backoff.
- `ProductivityOS/Resources/Info-macOS.plist` — macOS Info.plist.
- `ProductivityOSTests/FocusCompanionStateTests.swift` — view-model logic
  with a stubbed `FocusService`.
- `ProductivityOSTests/FocusPollerTests.swift` — cadence and
  low-power-mode behavior.

## Reused files (no changes)

- `Core/Networking/APIClient.swift` — already sends Bearer + cookie auth.
- `Core/Networking/Endpoint.swift` — already includes `qrExchange` and
  `endFocusSession` cases. May need new cases for the focus active
  endpoint; check first.
- `Core/Services/FocusService.swift` — `end(sessionId:)` and any active
  fetch methods.
- `Core/Services/QRAuthenticationService.swift` — `authenticate(challenge:)`
  is exactly the Mac flow.

## New Xcode project entries

- New target `ProductivityOSMac` (macOS 14, App, SwiftUI lifecycle).
- New scheme `ProductivityOSMac`.
- `ProductivityOSMac` target depends on the shared `ProductivityOSCore`
  library.
- New build configuration `Mac-Debug` / `Mac-Release` (or share
  `Debug` / `Release` with platform conditionals — TBD during
  implementation).

## Backend assumptions (verified)

The following endpoint contracts were verified against the running
backend at `http://localhost:8080` on 2026-09-04. Results:

| Endpoint | Method | Auth | Verified response |
|----------|--------|------|-------------------|
| `/api/v1/auth/register` | POST | none | 201 with `{ id, email, timezone }` |
| `/api/v1/auth/login` | POST | none | 200 with `{ accessToken, user }` + refresh cookie |
| `/api/v1/auth/qr/challenge` | POST | Bearer | 200 with `{ challenge, expiresAt }` (2 min TTL) |
| `/api/v1/auth/qr/exchange` | POST | none | 200 with `{ accessToken, user }` + refresh cookie |
| `/api/v1/focus/active` | GET | Bearer | 200 with `FocusSessionResponse` if active, **404** otherwise |
| `/api/v1/focus/{id}/end` | POST | Bearer | 200 with `FocusSessionResponse` (endedAt populated) |

Password validation: minimum 12 characters. Bearer token required for
all focus endpoints and for challenge creation.

## Acceptance Criteria

| ID | Requirement |
|----|-------------|
| AC-MAC-01 | The macOS app launches as a menu bar item with no Dock icon. |
| AC-MAC-02 | Clicking a `productivityos://auth?challenge=...` link in any browser routes to the Mac app and authenticates it within 2 seconds of the click. |
| AC-MAC-03 | After authentication, the popover shows "Idle — no focus session active" if `GET /api/v1/focus/active` returns 404. |
| AC-MAC-04 | Active session: elapsed time ticks every second and matches server `startedAt` within ±1 second. |
| AC-MAC-05 | Tapping End calls `POST /api/v1/focus/{id}/end` and the popover returns to "Idle" within 5 seconds. |
| AC-MAC-06 | Network error keeps the last known state visible and shows a "Reconnecting…" badge. |
| AC-MAC-07 | A 401 response clears `AuthSession` and returns the popover to the unauthenticated state. |
| AC-MAC-08 | macOS build compiles cleanly with no UIKit references in the produced binary. |
| AC-MAC-09 | iOS build still compiles and behaves unchanged. |
| AC-MAC-10 | The Mac companion never exposes a Start button. |
| AC-MAC-11 | Reusing a challenge via `/api/v1/auth/qr/exchange` a second time is rejected with 401; the Mac popover shows an inline error. |

## Risks

1. **Clock drift.** Elapsed time computed locally from server `startedAt`
   assumes the Mac clock is reasonably accurate (within seconds). On a
   wildly skewed clock, the timer could show wrong elapsed time.
   Acceptable for v1; mitigated by re-fetching on every poll tick.
2. **URL scheme collision.** Other apps could register `productivityos`.
   Apple's first-registered-wins behavior is acceptable for v1. A future
   spec could use a more unique scheme like `productivityos-mac-v1`.
3. **`LSUIElement = YES`** means the app does not appear in the Dock
   and `Cmd+Tab` skips it. Users must learn to quit via the menu bar.
   Standard for menu bar apps, but document it in the README.
4. **Notarization.** Out of scope. For local development, Gatekeeper
   will require `xattr -dr com.apple.quarantine` or running from Xcode.
5. **Challenge expiry race.** The web app issues a 2-minute challenge.
   If the user takes longer than that to click the link on their Mac,
   the exchange fails. The Mac popover must surface this with a clear
   "challenge expired, generate a new one on the web app" message.

## Follow-ups

- Mac-side session start (separate spec).
- Push notifications for focus milestones (separate spec).
- Menu bar customization (hide on idle, change icon).
- Signed + notarized distribution.
- Replace the third-party `api.qrserver.com` dependency in the web app
  with the same Core Image QR generator used on iOS, for full offline
  pairing.
