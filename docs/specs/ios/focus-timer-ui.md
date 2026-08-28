# iOS Focus Timer UI Specification

## Purpose

Redesign the Active Focus timer to make the passage of time visually clear, calm, and glanceable.

The timer should feel like a dedicated focus instrument rather than a normal application screen.

Visual reference:

`design/references/focus-timer-reference.png`

The reference defines the visual direction, not exact dimensions or a literal copy.

---

## 1. Visual Direction

The Active Focus screen should communicate:

> What am I focusing on?
> How much time is left?
> Keep going.

The screen should be:

- Minimal
- Premium
- Calm
- High contrast
- Glanceable
- Animation-driven
- Native-feeling SwiftUI

Avoid unnecessary information during an active session.

---

## 2. Layout

Use a two-panel composition when the available width allows it.

### Left

- Small `Timer` label
- Large countdown
- Stop button

### Right

Large rounded timer card containing:

- Circular progress ring
- Center pause/resume control

Example:

    ┌─────────────────────────────────────────────┐
    │                                             │
    │   Timer                 ┌───────────────┐   │
    │                         │               │   │
    │   16:15                 │      ◯◯◯      │   │
    │                         │    ◯   II  ◯   │   │
    │   ┌─────────────┐       │      ◯◯◯      │   │
    │   │    Stop     │       │               │   │
    │   └─────────────┘       └───────────────┘   │
    │                                             │
    └─────────────────────────────────────────────┘

On smaller iPhones, adapt to a vertical composition while preserving the same hierarchy.

---

## 3. Countdown

The countdown is the primary information.

Requirements:

- Large typography
- High contrast
- Stable digit width
- Easy to read at a glance
- Use the existing Productivity OS typography system where possible

Example:

    16:15

Do not introduce unnecessary secondary timer information.

---

## 4. Timer Ring

The circular ring represents the passage of time.

The ring must be visually animated.

Requirements:

- Active progress uses the Productivity OS cyan/blue accent direction from the reference.
- Remaining progress uses a darker track.
- Ring should have subtle depth/glow where appropriate.
- Progress moves smoothly and linearly.
- No springing or jitter.
- Ring must remain synchronized with the actual Focus session.

The ring is visual feedback only.

The existing FocusSessionState remains the source of truth.

---

## 5. Time Animation

The timer should visibly communicate time passing.

The countdown must not simply replace text every second.

Use a subtle digit transition such as:

- vertical clipping/rolling
- sliding digit replacement
- another native SwiftUI transition that creates a clock-like effect

The animation should be:

- subtle
- continuous
- predictable
- non-distracting

Avoid:

- bouncing
- exaggerated scaling
- flashy effects
- excessive spring animation

The goal is:

> Make time feel like it is moving.

---

## 6. Source of Truth

Do NOT implement timer arithmetic using an incrementing counter.

Continue using the existing timestamp-based FocusSessionState.

Conceptually:

    elapsed =
        currentTime
        - start
        - totalPausedTime

For fixed-duration sessions:

    remaining =
        duration - elapsed

The display and ring progress must be derived from timestamps.

The ticker may trigger UI refreshes, but must not become the source of timer truth.

This preserves correct behavior across:

- background/foreground
- screen transitions
- redraws
- lock/unlock
- delayed execution
- app lifecycle changes

---

## 7. Pause / Resume

The center of the ring is the primary pause/resume control.

Running:

    ||

Paused:

    ▶

When paused:

- timer freezes
- ring freezes
- pause state is visually obvious
- transition is animated

When resumed:

- timer continues from the correct timestamp
- ring continues smoothly

Use existing FocusSessionViewModel pause/resume behavior.

Do not create a second timer implementation.

---

## 8. Stop

The Stop button is secondary to the timer.

Style:

- rounded
- dark/neutral
- visually clear
- large enough for comfortable interaction

Tapping Stop must use the existing Focus session completion/end flow.

Do not introduce a new session lifecycle.

---

## 9. Colors

Follow the attached visual reference.

Primary direction:

- black / near-black
- white
- soft gray
- dark blue-gray
- cyan/electric blue for progress

Use the existing Productivity OS DesignSystem tokens where possible.

Do not introduce arbitrary colors without updating the design system.

---

## 10. Motion

Use the existing AppMotion tokens.

Recommended:

- Ring progress: linear `ringTick`
- Digit transition: subtle clock-like transition
- Pause/resume: standard transition
- Button interaction: existing button motion

Motion must communicate time and state.

---

## 11. Reduce Motion

When Reduce Motion is enabled:

- Disable digit movement.
- Disable decorative ring animation.
- Keep timer updates functional.
- Keep state changes immediately visible.

The timer must remain completely usable without animation.

---

## 12. Accessibility

VoiceOver must communicate:

- Focus timer
- Current remaining/elapsed time
- Current task
- Running/paused state
- Pause/resume action
- Stop action

Decorative ring/glow must not create unnecessary VoiceOver elements.

Dynamic Type should continue using the existing design system.

---

## 13. Responsive Behavior

The UI must work across supported iPhone sizes.

Wide:

    horizontal two-panel layout

Compact:

    vertical layout

Do not hardcode the reference image dimensions.

Preserve:

- hierarchy
- spacing
- touch targets
- visual balance

---

## 14. Existing Behavior Must Remain

Do not regress:

- FocusSessionState
- timestamp-based timer calculations
- pause/resume
- background handling
- foreground recovery
- natural completion
- backend-confirmed completion
- retry after failed completion
- haptics
- accessibility
- existing Focus API integration

This is a UI/interaction refinement, not a Focus architecture rewrite.
