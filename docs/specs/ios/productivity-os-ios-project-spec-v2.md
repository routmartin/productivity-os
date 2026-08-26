# Productivity OS iOS — Project Specification

**Version:** 0.1  
**Status:** Approved  
**Platform:** iOS  
**UI Framework:** SwiftUI  
**Primary V1 Feature:** Focus Sessions

## 1. Product Overview

Productivity OS iOS is a mobile companion for the existing Productivity OS platform.

It helps users move from:

> **What matters → What should I work on → Focus → Make progress**

The app is a personal focus companion, not a full replacement for the desktop/web productivity workspace.

### Product principles

- Calm
- Focused
- Simple
- Premium
- Fast
- Native to iOS
- Minimal distraction

## 2. V1 Scope

Primary areas:

- Today
- Focus
- Tasks
- Profile

### Today

- Greeting
- Daily inspiration / intention
- Today's focus / priority
- Important tasks
- Basic focus progress
- Quick start action

### Focus

- Select task
- Prepare session
- Choose duration
- Start
- Run
- Pause
- Resume
- Stop/cancel
- Complete
- Completion summary

### Tasks

- Fetch existing Productivity OS tasks
- Browse tasks
- View task information
- Select a task for Focus

The iOS app does not replace full web task management.

### Profile

- User information
- Lightweight preferences
- Appearance/settings where appropriate
- Basic account actions

## 3. Primary User Journey

```text
Open App
   ↓
Today
   ↓
Choose something meaningful
   ↓
Focus Preparation
   ↓
Choose duration
   ↓
Start Focus
   ↓
Active Focus Session
   ↓
Pause / Resume
   ↓
Complete
   ↓
Focus Summary
   ↓
Return to Today
```

## 4. Navigation

Primary navigation:

```text
Today | Focus | Tasks | Profile
```

Use native SwiftUI navigation.

During an active Focus Session, unnecessary navigation should disappear so the user feels they entered a dedicated focus environment.

## 5. Approved Visual Direction

The visual direction is already approved.

Normal application:

- Soft warm white / lavender background
- Purple primary accent
- Large readable typography
- Generous spacing
- Rounded surfaces
- Soft elevation
- Minimal metadata
- Clear hierarchy

Focus Mode:

- Deep navy / purple environment
- Large clipping/ring clock
- Minimal controls
- Subtle glow
- Large timer
- Minimal distraction

Avoid:

- Dense dashboards
- Tiny text
- Excessive cards
- Heavy gradients
- Excessive glassmorphism
- Constant decoration
- Gamification-heavy UI

## 6. Approved Visual Reference Assets

The reference images are part of this specification and are mandatory visual sources of truth.

Repository paths:

```text
docs/design/references/
├── ios-today-approved.png
└── ios-focus-flow-approved.png
```

### Today reference

`ios-today-approved.png` defines:

- Overall composition
- Typography scale
- Spacing rhythm
- Card proportions
- Background treatment
- Bottom navigation
- Today's Intention presentation
- Top 3 presentation
- Focus Today presentation
- Visual density

### Focus reference

`ios-focus-flow-approved.png` defines:

- Focus preparation
- Active Focus
- Paused Focus
- Focus-mode color transition
- Clipping/ring timer
- Focus controls
- Completion transition

### Visual fidelity rule

When implementing a screen:

1. Open the appropriate reference image.
2. Match composition and layout geometry.
3. Match typography scale.
4. Match spacing.
5. Match colors and surface relationships.
6. Match card proportions.
7. Match navigation placement.
8. Match interaction hierarchy.
9. Only then make small changes required by native iOS behavior.

Do not replace the approved visual direction with a generic iOS dashboard or an agent-created redesign.

If a reference asset is missing, report it instead of inventing a new visual interpretation.

## 7. Today Screen

Hierarchy:

```text
Greeting
   ↓
Daily Inspiration
   ↓
Today's Focus / Priority
   ↓
Important Tasks
   ↓
Focus Progress
```

The screen should feel like a calm daily command center.

### Daily inspiration

Show one short quote or intention.

Example:

> Protect your attention. Focus on what matters now.

For V1, this can be local data selected deterministically by date.

## 8. Focus Preparation

Show:

- Selected task
- Project/category context when available
- Duration selection
- Small focus suggestion
- Start Focus action

Use the approved light lavender / soft-card visual style.

Initial duration options:

- 25 min
- 45 min
- 60 min
- Unlimited

## 9. Active Focus

Active Focus is the hero experience.

Transition from the normal light UI into deep navy/purple Focus Mode.

Show:

- Task title
- Large clipping/ring clock
- Remaining time
- Focus status
- Pause
- Stop/cancel
- Complete
- Optional ambient-sound control if implemented

Keep the UI intentionally sparse.

## 10. Clipping Clock

Use a circular/clipping clock as the visual centerpiece.

The circular progress communicates the passage of time.

Requirements:

- Smooth
- Continuous
- Accurate
- Calm
- Non-distracting
- Correct across backgrounding and suspension

The user should feel time moving rather than watch a flashy animation.

## 11. Focus Session States

```text
PREPARING
    ↓
RUNNING
    ↓
PAUSED
    ↓
RUNNING
    ↓
COMPLETED
```

Cancellation:

```text
RUNNING → CANCELLED
PAUSED  → CANCELLED
```

### Running

- Timer progresses
- Ambient treatment may be active
- Pause/Stop/Complete controls available

### Paused

- Timer stops
- Clock progression stops
- Ambient motion reduces/stops
- Status changes to Paused
- Resume becomes primary action

### Completed

Show a calm acknowledgement:

```text
Well done.

42 minutes focused.

[ Done ]
```

No aggressive celebration.

## 12. Timer Behavior

Timer accuracy must be timestamp-based.

Do not depend on a UI timer decrementing an integer every second.

Account for:

- Backgrounding
- Screen locking
- App suspension
- Rendering delays
- Pause duration

The UI clock is a visualization of the underlying session timestamps/state.

## 13. Task Selection

Fetch tasks from the existing Productivity OS backend.

Prefer:

```text
Recommended
Continue
Other active tasks
```

Useful task context may include:

- Title
- Project/category
- Goal
- Priority
- Estimated duration

Do not create a separate task-management system.

## 14. Backend Integration

Use the existing Productivity OS API.

Conceptually:

```text
API
 ↓
Fetch tasks
 ↓
Select task
 ↓
Start Focus session
 ↓
Local session timing/state
 ↓
Pause / resume
 ↓
Complete
 ↓
Persist result
```

The coding agent must inspect existing API contracts first.

Do not invent equivalent endpoints.

If functionality is missing, report it before changing the contract.

## 15. Authentication

Integrate with the existing Productivity OS authentication system.

Use appropriate iOS secure storage for sensitive authentication material.

Do not store sensitive tokens in plain UserDefaults.

Handle:

- Authenticated requests
- Expiration
- Logout
- Refresh according to the existing backend contract

## 16. Network Resilience

An active Focus Session must continue correctly during temporary network loss.

```text
Network unavailable
        ↓
Focus continues locally
        ↓
Network returns
        ↓
Session synchronizes
```

A complete offline-first architecture is out of scope for V1.

## 17. Backgrounding

When the app returns to the foreground:

1. Read persisted session state/timestamps.
2. Calculate actual elapsed time.
3. Restore the correct UI state.
4. Continue the active session if appropriate.

Never use continuous UI timer ticks as the source of truth.

## 18. SwiftUI Technology Direction

This is also a SwiftUI learning project.

Use current stable SwiftUI APIs supported by the project's deployment target.

Prefer native Apple technologies:

- SwiftUI
- NavigationStack
- TabView
- sheet
- fullScreenCover
- toolbar
- SF Symbols
- Dynamic Type
- Safe-area APIs
- Swift concurrency / async-await
- Observation or the appropriate modern state API
- SwiftUI animations/transitions
- Native accessibility APIs

Avoid third-party UI frameworks and architecture frameworks unless there is a strong project-specific reason.

## 19. Project Structure Direction

Use a practical feature-oriented structure:

```text
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
```

The agent must inspect the existing project first and adapt this structure rather than blindly restructuring existing code.

## 20. Design System Foundation

Create reusable SwiftUI primitives for:

- Colors
- Typography
- Spacing
- Corner radii
- Surface/card styles
- Primary/secondary buttons
- Task rows
- Section headers
- Bottom navigation
- Focus clock

Do not create a giant framework.

## 21. State Management

Prefer:

- Native SwiftUI state
- Observation where appropriate
- Small focused state models
- Explicit data flow
- Initializer-based dependency injection where useful

Avoid:

- Global mutable state
- Singleton-heavy architecture
- Massive views
- Massive view models
- Premature architecture frameworks
- Generic abstractions without a real use case

## 22. Networking Foundation

Use URLSession + async/await unless a suitable existing networking layer is already present.

Target:

```text
SwiftUI View
  ↓
Feature State
  ↓
Feature Service
  ↓
API Client
  ↓
URLSession
  ↓
Productivity OS API
```

Do not build an unnecessarily generic networking framework.

## 23. Configuration

Production API URLs must be configurable and must not be hardcoded in Swift source.

Support development and production configuration.

Never commit secrets.

## 24. Preview / Sample Data

Previews must work without a live backend.

Provide sample data for:

- User
- Task
- Project/category
- Preparing Focus
- Running Focus
- Paused Focus
- Completed Focus

## 25. Accessibility

Support:

- Dynamic Type
- VoiceOver
- Accessibility labels/values
- Comfortable touch targets
- Sufficient contrast
- Reduce Motion

Accessibility must remain usable when animations are reduced.

## 26. Animation

Principle:

> **Make the app feel alive, not animated for the sake of animation.**

Use:

- Smooth screen transitions
- Subtle fades
- Gentle scale
- Progress animation
- Soft glow
- Native SwiftUI spring interactions

Focus-specific:

- Normal → Focus environment transition
- Smooth clock progress
- Running → Paused
- Paused → Running
- Completion transition

Avoid:

- Excessive bounce
- Flashing
- Long transitions
- Constant background motion
- Particle-heavy effects
- Gamification

## 27. Testing

Establish practical tests for:

- Focus state transitions
- Timer calculations
- Pause/resume calculations
- Completion
- API decoding
- Authentication state

Important UI flow:

```text
Open App
→ Select Task
→ Choose Duration
→ Start Focus
→ Pause
→ Resume
→ Complete
```

Also verify:

```text
Start Focus
→ Background App
→ Return
→ Timer remains accurate
```

## 28. V1 Non-Goals

Do not implement initially:

- AI assistant
- AI-generated planning
- Advanced analytics
- Goal management
- Project management
- Social features
- Gamification
- Leaderboards
- Advanced notification system
- Widgets
- Live Activities
- Apple Watch
- iPad-specific optimization
- Complex offline database
- Advanced ambient sound system

## 29. Initial Project Setup Definition of Done

- [ ] iOS app builds
- [ ] SwiftUI app launches
- [ ] Primary navigation exists
- [ ] Today structure exists
- [ ] Focus structure exists
- [ ] Tasks structure exists
- [ ] Profile structure exists
- [ ] Networking foundation exists
- [ ] Authentication foundation exists
- [ ] API configuration exists
- [ ] Design-system foundation exists
- [ ] Preview/sample data exists
- [ ] Focus domain state exists
- [ ] Testing structure exists
- [ ] Accessibility foundation exists
- [ ] No unnecessary third-party UI dependencies
- [ ] Production API URLs are configurable
- [ ] Existing unrelated code is untouched
- [ ] App builds and runs successfully

The complete Focus implementation is a subsequent milestone.

## 30. Development Philosophy

Prioritize shipping, learning, and product quality over architectural perfection.

> **Simple first → understand the problem → introduce structure when complexity requires it.**

Architecture supports the product; it is not the product.
