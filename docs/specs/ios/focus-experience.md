# Productivity OS iOS — Focus Experience Specification

## 1. Purpose

Focus is the primary execution experience of the Productivity OS iOS app.

The purpose of this experience is to help the user move from:

Task selected
→ intentional preparation
→ deep focus
→ completion
→ reflection

The experience should feel:

- Calm
- Premium
- Focused
- Minimal
- Responsive
- Native to iOS

Focus should feel like a special state of Productivity OS, not a completely different application.

---

# 2. Focus Flow

The complete flow is:

Today / Tasks
↓
Focus Preparation
↓
Active Focus
↓
Pause
↓
Resume
↓
Complete
↓
Focus Completion
↓
Today / Progress

The user must always understand:

1. What they are working on.
2. How much time remains.
3. What state the session is currently in.
4. What action they can take next.

---

# 3. Focus Preparation

## Purpose

Give the user a short intentional moment before starting.

The screen should display:

- Selected task
- Project/category context
- Selected duration
- Optional focus tip/inspiration
- Start action

Example structure:

    Focus

    Finish authentication
    Productivity OS

    Duration

    [25 min] [50 min] [90 min]

    "One task. One session."

             [ Start Focus ]

## Interaction

Selecting a duration should provide a subtle selection animation.

Starting Focus should NOT immediately hard-cut into the active timer.

Use a short transition:

Preparation
↓
Start interaction
↓
Focus transition
↓
Active Focus

---

# 4. Active Focus

## Visual Goal

The active Focus screen should remove unnecessary information.

The user should primarily see:

1. Current task
2. Timer
3. Session progress
4. Pause/finish controls

The visual hierarchy is:

Task
↓
Timer
↓
Progress
↓
Controls

Avoid excessive secondary information.

---

# 5. Focus Visual Theme

Normal Productivity OS uses the shared light visual system.

Active Focus transitions into the Focus visual state:

- Deep navy / dark background
- Light typography
- Brand accent
- High contrast timer
- Minimal controls

The transition should feel intentional.

Do not simply navigate to a completely unrelated screen.

---

# 6. Clipping Clock

The timer is the signature Focus interaction.

The clock should use a visual clipping/ring treatment rather than being only a text countdown.

Conceptually:

          ┌───────────────┐
       ╭──                 ──╮
     ╭─                         ─╮
    │           42:18            │
    │                            │
     ╰─                         ─╯
       ╰──                 ──╯
          └───────────────┘

The progress arc represents the remaining/elapsed session.

The implementation must be driven by actual session timestamps.

Do NOT increment a local integer every second.

---

# 7. Timer Calculation

The timer must be derived from:

- session start timestamp
- paused duration
- current timestamp
- configured session duration

Conceptually:

remaining =
sessionDuration

- activeElapsedDuration

The displayed value must remain accurate after:

- SwiftUI view redraw
- app backgrounding
- device locking
- device unlocking
- screen transitions

The timer must not drift because the UI refresh rate changes.

---

# 8. Timer Animation

The progress ring should continuously animate as time passes.

The animation should feel smooth rather than ticking once per second.

The numerical time should update at an appropriate cadence.

The progress ring may use a smooth continuous representation while the displayed text remains readable.

Avoid visually distracting animation.

---

# 9. Start Transition

When the user taps:

    Start Focus

The following sequence should occur:

1. Button press feedback.
2. Optional light haptic.
3. Focus background begins transitioning.
4. Timer becomes the visual focal point.
5. Progress ring appears/activates.
6. Controls settle into their final position.

The transition should be approximately 300–500ms.

Avoid excessive effects.

---

# 10. Pause

When the user pauses:

The timer must stop progressing.

The visual state should clearly communicate:

    PAUSED

The progress ring remains at its current position.

The task remains visible.

The primary action changes to:

    Resume Focus

The pause transition should be subtle.

No destructive confirmation is required.

---

# 11. Resume

When the user taps Resume:

1. Provide subtle haptic feedback.
2. Recalculate the timer from timestamps.
3. Resume the progress animation.
4. Remove the paused state.
5. Return focus to the timer.

The timer must not continue from an outdated locally stored counter.

---

# 12. Background / Foreground

Focus must support normal iOS lifecycle changes.

When the app moves to the background:

- Stop unnecessary animation work.
- Preserve the session state.
- Preserve timestamps.

When the app returns to the foreground:

- Recalculate the current timer.
- Restore the correct visual progress.
- Do not simply resume from the last displayed number.

Example:

App shows:

    42:18

User locks phone.

Five minutes later:

    37:18

The UI must correctly reflect the elapsed time.

---

# 13. App Termination

The Focus session must not depend exclusively on in-memory SwiftUI state.

If the backend supports persisted session state:

- Restore the session from the backend.

If the existing API contract does not support restoration after termination:

- Do not invent new backend behavior.
- Clearly document the limitation.

The local client must never claim a session is completed unless the backend contract confirms it.

---

# 14. Completion

When the timer reaches zero:

The session transitions into completion.

The transition should feel calm and rewarding.

Recommended sequence:

Timer reaches zero
↓
Progress completes
↓
Subtle completion animation
↓
Completion screen

Avoid excessive celebration.

Do not use:

- Confetti
- Large reward popups
- XP
- Gamification
- Loud animations

The feeling should be:

    "I made progress."

---

# 15. Focus Completion Screen

Display:

- Completion state
- Total focus duration
- Completed task
- Optional reflection
- Done action

Example:

    ✓

    Well done

    You stayed focused.

          42m 18s

    Finish authentication
    Productivity OS

    How did it feel?

    🙂     😐     😮‍💨
    Great  Good  Difficult

             [ Done ]

The reflection must be optional.

The user can complete the flow without selecting a mood.

---

# 16. Haptics

Use haptics intentionally.

Recommended events:

Start:

- light / subtle feedback

Pause:

- light feedback

Resume:

- light feedback

Completion:

- success-style feedback

Do not trigger haptics every second.

Do not use haptics for purely visual timer updates.

---

# 17. Accessibility

The Focus experience must support:

- Dynamic Type where practical
- VoiceOver labels
- Sufficient contrast
- Minimum touch target sizes
- Reduced Motion

When Reduce Motion is enabled:

- Reduce large transitions.
- Remove decorative animation.
- Keep timer functionality intact.
- Preserve essential state transitions.

The timer must remain understandable without relying solely on animation.

---

# 18. Design System

Focus must reuse:

- existing color tokens
- typography tokens
- spacing tokens
- button components
- animation definitions

Do not introduce random hardcoded colors or spacing values inside Focus views.

Focus may define specialized tokens where necessary, but they should live in the DesignSystem.

---

# 19. Architecture

Keep the existing architecture:

View
↓
FocusSessionViewModel
↓
Focus Service / Repository
↓
APIClient
↓
Backend

The ViewModel owns:

- session state
- timer state
- pause/resume state
- lifecycle coordination
- user actions

The View owns:

- presentation
- animation
- accessibility
- interaction

The API layer owns:

- network communication
- request/response handling

---

# 20. Testing

Test:

### Timer

- correct initial duration
- elapsed time calculation
- remaining time calculation
- pause duration
- resume
- completion
- background/foreground recalculation

### Focus state

- preparing
- running
- paused
- resumed
- completed

### UI

- correct controls for each state
- Reduce Motion behavior
- accessibility labels

### API

- start session
- update/complete session where supported
- API failure
- authentication expiration

---

# 21. Acceptance Criteria

The Focus experience is complete when:

- [ ] Preparation screen works with a real selected task.
- [ ] Starting Focus creates/uses the correct backend session.
- [ ] Active Focus displays an animated clipping/ring timer.
- [ ] Timer is timestamp-driven.
- [ ] Timer remains accurate after background/foreground transitions.
- [ ] Pause works.
- [ ] Resume works.
- [ ] Completion occurs correctly.
- [ ] Completion is persisted according to the existing API contract.
- [ ] Completion screen is implemented.
- [ ] Optional reflection works.
- [ ] Haptics are implemented appropriately.
- [ ] Reduce Motion is respected.
- [ ] Accessibility labels exist.
- [ ] No excessive animation exists.
- [ ] No gamification has been introduced.
- [ ] Existing approved UI remains intact.
- [ ] SwiftUI previews continue working.
- [ ] Tests pass.

---

# 22. Out of Scope

Do not implement:

- Apple Watch
- Live Activities
- Dynamic Island integration
- Push notifications
- Focus Mode integration with Apple's system Focus
- Background audio
- New backend APIs
- AI coaching
- Gamification
- XP/rewards
- Social features

These can be considered later.
