# ADR-009: Home Screen Widget Data Sharing via App Group Snapshot

## Status

Accepted

## Context

The iOS Home Screen widget (`FocusHomeWidget`) originally rendered a static
placeholder. Users expect it to show their real tasks — the same data the app
shows on Today and Tasks, which is fetched from the authenticated API
(`GET /api/v1/tasks`, `GET /api/v1/daily-top-three`) using the session token
stored in the Keychain (`AuthSession`, ADR-004).

A WidgetKit extension runs in its own process, sandboxed from the host app. It
cannot read `AuthSession`, the app's Keychain, `APICache`, or any in-memory
state, and the API requires authentication. There is also no existing shared
storage between the app and the extension.

Per ADR-001 and `AGENTS.md`, choosing how the widget obtains app data is an
architectural decision and requires an approved direction before implementation.

## Decision Drivers

- **Security**: the widget must never hold the user's access/refresh token, and
  no credentials should leave the app process.
- **Single source of truth**: the app already fetches and caches tasks; the
  widget should display that data, not a parallel fetch with divergent rules.
- **Simplicity**: one writer, one reader, no duplicated networking or auth.
- **Freshness**: the widget must refresh when the underlying tasks change.
- **Decoupling**: the extension must not compile app models that drag in the
  design system or networking stack.
- **Reversibility**: the mechanism should be removable without touching product
  behavior.

## Options

- **Option A — App Group snapshot (chosen).** The app writes a small,
  display-ready snapshot of the latest tasks to a shared App Group container
  (`UserDefaults(suiteName:)`) and calls `WidgetCenter.reloadTimelines`. The
  widget reads and renders the snapshot.
- **Option B — Widget fetches the API itself.** The extension performs its own
  authenticated requests, obtaining a token from shared Keychain via the App
  Group.
- **Option C — Static placeholder (previous state).** The widget shows no real
  data.

## Decision

1. **Adopt Option A.** Introduce a shared App Group, `group.com.productivityos.app`,
   enabled for both the `ProductivityOS` app target and the `FocusLiveActivity`
   extension target.
2. **Shared contract.** A single file (`Shared/FocusWidgetShared.swift`) is
   compiled into both targets and defines the App Group id, the widget kind, and
   the flat, display-ready `FocusWidgetSnapshot` / `FocusWidgetTask` Codable
   types. It imports only Foundation.
3. **App is the only writer.** `FocusWidgetPublisher` (app target) maps
   `[TaskItem]` to the snapshot — active, non-deleted tasks, newest first,
   capped at three — saves it, and reloads the widget timeline. It is invoked
   after a successful task fetch in `TodayViewModel` and `TasksViewModel`.
4. **Logout clears the snapshot** (`FocusWidgetPublisher.clear()`) so the widget
   never shows a previous user's tasks.
5. **Widget is a pure reader.** The `TimelineProvider` decodes the snapshot and
   renders it; `policy: .never` because the app drives all invalidations. The
   widget shows an explicit empty/never-synced state.
6. **No credentials cross the boundary.** The snapshot contains only task id,
   title, project name, priority, and completion state.

## Reasoning

- **Security (A over B).** Option B puts a bearer token inside a second process
  and duplicates refresh logic; a compromise there is a compromise of auth.
  Option A never exposes credentials.
- **Consistency and simplicity (A over B).** The app already owns fetch, cache,
  and refresh semantics. One writer keeps widget content aligned with the app
  and avoids a second network path, retry policy, and base-URL configuration.
- **Decoupling.** The shared file is intentionally flat so the extension does
  not depend on app-only types (`TaskItem`, `AppColors`, `APIClient`).
- **Widgets are not real-time.** `reloadTimelines` on meaningful changes gives
  pragmatic freshness without polling or background work.

## Consequences

### Positive

- The widget shows real tasks from the authenticated API without handling auth.
- One data pipeline; widget rules mirror the app's.
- The snapshot schema is versionable and independent of app internals.
- Clearing on logout prevents cross-user leakage on the Home Screen.

### Negative

- Requires the App Group capability to be enabled for the team and registered in
  the Apple Developer portal; device builds fail to sign without it.
- The widget is only as fresh as the last app fetch + reload; it does not fetch
  on its own schedule.
- "Latest 3" is defined in the app (`createdAt` descending, active only) and is
  a client convention, not a backend contract.

## Rejected Alternatives

- **Option B (widget fetches API):** exposes a token to the extension, duplicates
  networking/auth, and conflicts with ADR-004 (user isolation lives in the app's
  session). Rejected.
- **Option C (static placeholder):** does not satisfy the requirement. Rejected.
- **Reading the app's Keychain/UserDefaults directly:** impossible across the
  sandbox without an App Group; also unsafe. Rejected.

## Related Specifications and ADRs

- `docs/decisions/ADR-001-sdd-workflow.md`
- `docs/decisions/ADR-004-authentication-user-isolation.md`
- `docs/decisions/ADR-005-api-architecture.md`
- `docs/specs/tasks/task-management.md` (active/completed/deleted definitions)
- `docs/specs/planning/daily-top-three.md` (Today dashboard context)
