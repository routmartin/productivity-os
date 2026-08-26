# Productivity OS iOS — Project Specification

**Version:** 0.1  
**Status:** Approved  
**Platform:** iOS  
**UI Framework:** SwiftUI  
**Product:** Productivity OS  
**Primary V1 Feature:** Focus Sessions

## 1. Product Overview

Productivity OS iOS is a mobile companion for the existing Productivity OS platform.

The app helps users move from:

> **What matters → What should I work on → Focus → Make progress**

The iOS app is primarily designed around the user's daily workflow and focused work sessions.

It should feel like a personal productivity companion rather than another complex productivity-management application.

### Product Principles

- Calm
- Focused
- Simple
- Premium
- Fast
- Native to iOS
- Minimal distraction

## 2. Product Goals

The iOS application should allow users to:

1. See what matters today.
2. Receive a small moment of daily inspiration.
3. Browse existing Productivity OS tasks.
4. Select a task to work on.
5. Start a focused work session.
6. Pause and resume a session.
7. Stop or cancel a session.
8. Complete a session.
9. Record the session with the Productivity OS backend.
10. Review basic focus progress.

The primary experience is:

> **Choose something meaningful → Focus → Finish.**

## 3. V1 Scope

The first version contains four primary areas:

```text
Today
Focus
Tasks
Profile
```

### 3.1 Today

The Today screen is the user's daily starting point.

It should contain:

- Greeting
- Daily inspiration
- Today's focus / priority
- Important tasks
- Basic focus progress
- Quick access to starting a focus session

The screen should feel like a calm daily command center rather than an analytics dashboard.

### 3.2 Focus

Focus is the primary feature.

The Focus experience includes:

- Selecting a task
- Focus preparation
- Duration selection
- Starting a session
- Active focus session
- Pause
- Resume
- Stop / cancel
- Session completion
- Basic completion summary

The Focus experience should be immersive and intentionally remove unnecessary UI.

### 3.3 Tasks

Tasks are retrieved from the existing Productivity OS backend.

Users should be able to:

- Browse tasks
- View task information
- Select a task
- Start a Focus session from a task

The iOS application does not attempt to replace the full task-management experience of the web application.

### 3.4 Profile

Profile is intentionally lightweight in V1.

It may contain:

- User information
- Basic application preferences
- Appearance settings where appropriate
- Basic account actions

Complex account-management functionality is outside the initial scope.

## 4. Primary User Journey

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

This flow should require minimal interaction.

## 5. Navigation

Primary navigation:

- Today
- Focus
- Tasks
- Profile

Use native SwiftUI navigation patterns.

During an active Focus Session, unnecessary navigation should be hidden so the user feels they have entered a dedicated focus environment.

## 6. Approved Visual Direction

The visual direction has already been approved.

The UI should feel:

- Clean
- Spacious
- Premium
- Calm
- Modern
- Comfortable
- Slightly alive through subtle motion

Avoid:

- Dense dashboards
- Tiny text
- Excessive cards
- Heavy gradients
- Excessive glassmorphism
- Excessive decoration
- Visual clutter
- Gamification-heavy UI

### Normal Application Visual Language

The normal application environment uses:

- Soft warm white / lavender background
- Purple primary accent
- Large readable typography
- Generous spacing
- Rounded surfaces
- Soft elevation
- Minimal metadata
- Clear visual hierarchy

The Today screen is the visual reference for the rest of the normal application.

## 7. Today Screen

The Today screen should follow this hierarchy:

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

The user should immediately understand:

> **What should I focus on today?**

Daily inspiration should display one short quote or intention.

For V1, inspiration may be stored locally and selected deterministically by date.

## 8. Focus Preparation

The preparation screen is a transition from planning into focused work.

It should display:

- Selected task
- Project/category context when available
- Duration selection
- Small focus suggestion
- Start Focus action

The presentation uses the approved light lavender / soft-card style.

## 9. Active Focus Experience

The Active Focus screen is the hero experience.

When a session starts, the visual environment transitions into:

**Deep navy / purple Focus Mode**

It should contain:

- Task title
- Large clipping/ring clock
- Remaining time
- Focus status
- Pause
- Stop / cancel
- Complete
- Optional ambient-sound control if implemented

The purpose is to remove distractions and keep attention on the work.

## 10. Focus Clock

The timer uses a circular / clipping clock design.

The circular progress visually communicates the passage of time.

Requirements:

- Progress smoothly
- Represent actual elapsed time
- Remain visually calm
- Avoid distracting animation
- Remain accurate across app backgrounding and suspension

The user should feel time moving rather than watch an animation.

## 11. Focus Session States

Supported states:

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
- Ambient visual treatment may be active
- Pause / Stop / Complete controls are available

### Paused

- Timer stops
- Clock progression stops
- Ambient motion reduces or stops
- Status changes to Paused
- Resume becomes the primary action

### Completed

Show a simple acknowledgement.

Example:

```text
Well done.

42 minutes focused.

[ Done ]
```

Do not use aggressive gamification.

## 12. Timer Behavior

The timer must be based on real timestamps.

Do not implement session accuracy by simply decrementing an integer every second.

The implementation must account for:

- App backgrounding
- Screen locking
- App suspension
- Rendering delays
- Pause duration

The UI timer is only a visual representation of the underlying session state and timestamps.

## 13. Focus Duration

Initial duration options:

```text
25 min
45 min
60 min
Unlimited
```

The exact presentation may be refined during implementation, but duration selection should remain lightweight.

## 14. Task Selection

The iOS application fetches tasks from the existing Productivity OS API.

Task selection should prioritize useful work instead of presenting an overwhelming database list.

Recommended ordering:

```text
Recommended
Continue
Other active tasks
```

Task information may include:

- Task title
- Project/category
- Goal when available
- Priority
- Estimated duration when available

Use the existing backend task model.

Do not create a separate local task-management system.

## 15. Backend Integration

The iOS application consumes the existing Productivity OS backend.

Conceptually:

```text
Productivity OS API
        ↓
Fetch tasks
        ↓
iOS task selection
        ↓
Start focus session
        ↓
Local session state / timer
        ↓
Pause / resume
        ↓
Complete session
        ↓
Persist result through API
```

The coding agent must inspect existing backend API contracts before implementing networking.

Do not invent a new API contract when equivalent functionality already exists.

If required Focus functionality is missing from the backend, report the gap before changing the contract.

## 16. Authentication

The iOS application must integrate with the existing Productivity OS authentication system.

It should:

- Authenticate against the existing backend
- Store sensitive authentication material using appropriate iOS secure storage
- Avoid storing sensitive credentials in plain UserDefaults
- Add authentication to protected API calls
- Handle expired authentication appropriately
- Support logout

Use native iOS security facilities where appropriate.

## 17. Network Resilience

An active Focus Session must not depend on network availability.

If connectivity becomes unavailable:

```text
Network unavailable
        ↓
Focus continues locally
        ↓
Network becomes available
        ↓
Session synchronizes
```

V1 does not require a complete offline-first data architecture.

The most important guarantee is:

> **Temporary network loss must not corrupt Focus timing.**

## 18. App Backgrounding

When the application becomes active again:

1. Read persisted session state/timestamps.
2. Calculate actual elapsed time.
3. Reconstruct the correct UI state.
4. Continue the session if it is still active.

The timer must not depend on a continuously running UI timer.

## 19. Completion / Reflection

After a session completes, show a small completion state.

V1 may optionally provide:

```text
How did it go?

Great
Good
Difficult
```

Reflection must remain optional and quick.

## 20. SwiftUI Technology Direction

This is also a SwiftUI learning project.

Use current stable SwiftUI APIs supported by the project's current Xcode/iOS deployment target.

Prefer native APIs and modern Swift practices:

- SwiftUI
- NavigationStack
- TabView
- sheet
- fullScreenCover
- toolbar
- SF Symbols
- Dynamic Type
- Safe-area APIs
- Swift concurrency
- async/await
- Observation / modern state-management APIs
- SwiftUI animations and transitions
- Native accessibility APIs

Avoid third-party UI frameworks unless there is a strong technical reason.

Do not introduce architectural frameworks merely for demonstration.

## 21. Project Structure Direction

Use a practical feature-oriented structure, adapting to any existing project conventions:

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

Do not restructure unrelated code without a reason.

## 22. Design System Foundation

Create reusable SwiftUI primitives for:

- Colors
- Typography
- Spacing
- Corner radii
- Surface/card styles
- Primary buttons
- Secondary buttons
- Task rows
- Section headers
- Focus clock
- Common controls

Do not create a giant design-system framework.

## 23. State Management

Use simple, explicit data flow.

Prefer:

- Native SwiftUI state
- Observation where appropriate
- Small focused state models
- Explicit dependency flow
- Initializer-based dependency injection where useful

Avoid:

- Global mutable state
- Singleton-heavy architecture
- Massive ViewModels
- Massive SwiftUI Views
- Generic abstractions without a real use case
- Premature architecture frameworks

## 24. Networking

Use native Swift concurrency and URLSession unless the existing project already contains an appropriate networking layer.

Target structure:

```text
SwiftUI View
      ↓
Feature State / ViewModel
      ↓
Feature Service
      ↓
API Client
      ↓
URLSession
      ↓
Productivity OS API
```

Keep API models and UI state models separate when useful.

Do not build an unnecessarily generic networking framework.

## 25. Configuration

Production API URLs must not be hardcoded into Swift source.

Support appropriate:

- Development configuration
- Production configuration

Do not commit secrets.

The API base URL should be configurable per build environment.

## 26. Preview / Sample Data

SwiftUI previews must work without a live backend.

Provide sample data for:

- User
- Task
- Project/category
- Focus session
- Preparing state
- Running state
- Paused state
- Completed state

UI development should not require authentication or network access.

## 27. Accessibility

Support:

- Dynamic Type
- VoiceOver
- Accessibility labels
- Accessibility values
- Comfortable tap targets
- Sufficient contrast
- Reduce Motion

Accessibility must not depend on animation being enabled.

## 28. Animation

The motion principle is:

> **Make the application feel alive, not animated for the sake of animation.**

Use:

- Smooth screen transitions
- Subtle fades
- Gentle scale
- Progress animation
- Soft glow
- Native SwiftUI spring interactions

Focus-specific motion:

- Normal → Focus environment transition
- Smooth clock progress
- Running → Paused transition
- Paused → Running transition
- Gentle completion transition

Avoid:

- Excessive bounce
- Flashing
- Long transitions
- Constant background movement
- Particle-heavy effects
- Gamification

## 29. Testing

Establish a practical testing foundation.

Important unit-test areas:

- Focus state transitions
- Timer calculations
- Pause/resume calculations
- Completion calculation
- API decoding
- Authentication state behavior

Important UI-flow coverage:

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

## 30. V1 Non-Goals

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

## 31. Initial Project Setup Definition of Done

The project foundation is complete when:

- [ ] iOS application builds successfully
- [ ] SwiftUI application launches
- [ ] Primary navigation exists
- [ ] Today feature structure exists
- [ ] Focus feature structure exists
- [ ] Tasks feature structure exists
- [ ] Profile feature structure exists
- [ ] Networking foundation exists
- [ ] Authentication foundation exists
- [ ] API configuration exists
- [ ] Design-system foundation exists
- [ ] Preview/sample data exists
- [ ] Focus domain models exist
- [ ] Testing structure exists
- [ ] Accessibility foundation exists
- [ ] No unnecessary third-party UI dependencies exist
- [ ] Production API URLs are configurable
- [ ] Existing unrelated project code remains untouched
- [ ] Application builds and runs successfully

The complete Focus feature does not need to be implemented during project setup.

This milestone establishes the foundation for the actual feature implementation.

## 32. Development Philosophy

This project prioritizes shipping, learning, and product quality over architectural perfection.

Use:

> **Simple first → understand the problem → introduce structure when complexity requires it.**

The project should demonstrate modern SwiftUI development in a real product context.

Architecture exists to support the product, not become the product.
