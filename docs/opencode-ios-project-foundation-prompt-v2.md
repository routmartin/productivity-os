# OpenCode — Productivity OS iOS Project Foundation

Read and follow:

docs/specs/ios/productivity-os-ios-project-spec-v2.md

## REQUIRED VISUAL REFERENCES

Before implementation, inspect the approved images:

- docs/design/references/ios-today-approved.png
- docs/design/references/ios-focus-flow-approved.png

These are NOT loose inspiration. They are the visual source of truth.

Use them to match:

- composition
- typography scale
- spacing
- color relationships
- card proportions
- navigation
- button style
- Focus Mode colors
- clipping/ring clock concept
- visual density

Do not invent a generic SwiftUI design.

If either reference file is missing, STOP and report the missing asset instead of inventing a design.

## TASK

Set up the iOS project foundation only.

Do not implement the complete Focus feature yet.

First inspect:

1. Existing Xcode project
2. Deployment target
3. Current Swift/Xcode configuration
4. Existing architecture
5. Existing networking
6. Existing models
7. Existing shared UI
8. Existing dependencies

Preserve correct work and avoid restructuring unrelated code.

## MODERN SWIFTUI

Use current stable SwiftUI APIs supported by the project's deployment target.

Prefer:

- SwiftUI
- NavigationStack
- TabView
- sheet
- fullScreenCover
- toolbar
- SF Symbols
- Dynamic Type
- safe-area APIs
- async/await
- URLSession
- Observation or the appropriate modern state API
- SwiftUI transitions/animations
- native accessibility APIs

Do not introduce third-party UI or architecture frameworks unless already justified by the repository.

This is also a SwiftUI learning project. Prefer clear, idiomatic native SwiftUI.

## FOUNDATION

Prepare:

- SwiftUI App entry
- TabView: Today / Focus / Tasks / Profile
- Feature scaffolding
- Core networking foundation
- Environment configuration
- Authentication foundation
- Shared design system
- Core models
- FocusSessionState
- Preview/sample data
- Test foundation

Suggested structure:

ProductivityOS/
├── App/
├── Core/
│   ├── Networking/
│   ├── DesignSystem/
│   ├── Extensions/
│   └── Utilities/
├── Features/
│   ├── Today/
│   ├── Focus/
│   ├── Tasks/
│   └── Profile/
├── Models/
└── Resources/

Adapt it to existing project conventions.

Do not create empty architecture layers just for appearance.

## DESIGN SYSTEM

Create only the reusable primitives necessary to reproduce the approved references:

- Colors
- Typography
- Spacing
- Corner radii
- Surfaces/cards
- Primary/secondary buttons
- Task row
- Section header
- Bottom navigation
- Focus clock foundation

Do not create the full screens yet.

## NETWORKING

Use native URLSession + async/await unless an appropriate existing networking layer already exists.

Target:

View
→ Feature State
→ Feature Service
→ API Client
→ URLSession
→ Existing Productivity OS API

Do not invent endpoints.

Do not hardcode production API URLs.

## AUTHENTICATION

Prepare authenticated API support using appropriate iOS secure storage.

Do not store sensitive tokens in plain UserDefaults.

Do not implement a complete authentication UI unless the existing project requires it for the foundation.

## MODELS

Prepare models for:

- User
- Task
- FocusSession
- FocusSessionState
- FocusDuration

Focus states:

PREPARING
RUNNING
PAUSED
COMPLETED
CANCELLED

Do not implement the full timer yet.

Design the state so future timing uses timestamps and survives backgrounding/suspension.

## PREVIEWS

Provide preview/sample data for:

- Today
- Task list
- Focus preparation
- Running Focus
- Paused Focus
- Completed Focus

Previews must not require the backend.

The previews should be visually compared with the approved image references.

## ACCESSIBILITY

Use native SwiftUI accessibility features:

- Dynamic Type
- VoiceOver
- Labels/values
- Comfortable touch targets
- Contrast
- Reduce Motion

## TESTING

Set up practical tests for:

- Models
- Focus state transitions
- Future timer calculations
- API decoding

Add a small meaningful example rather than empty tests.

## VISUAL VALIDATION

Before finishing:

1. Build and run the app in Simulator.
2. Open Today.
3. Open Focus.
4. Compare against ios-today-approved.png and ios-focus-flow-approved.png.
5. Check typography.
6. Check spacing.
7. Check surface/card proportions.
8. Check navigation.
9. Check color direction.
10. Check that the visual density is comfortable.

Do not report "visual match" without actually looking at the references.

## SCOPE LIMIT

Do not implement:

- full Focus session behavior
- full Today behavior
- full Tasks behavior
- full Profile behavior
- AI
- Widgets
- Live Activities
- Apple Watch
- advanced offline architecture
- backend changes

## VERIFICATION

Run:

- iOS build
- available tests
- SwiftUI preview compilation

Confirm:

- App launches
- Navigation works
- No unnecessary dependencies
- No unrelated code changed

## FINAL REPORT

Report:

1. Existing project structure discovered.
2. New structure.
3. SwiftUI APIs/patterns used.
4. Design-system foundation.
5. Exactly how the approved visual references were used.
6. Networking/configuration foundation.
7. Models/state.
8. Preview strategy.
9. Tests.
10. Build/test results.
11. Any visual mismatches or missing assets.
12. Recommended next step.

Explain important SwiftUI concepts briefly so the developer can learn from the implementation.
