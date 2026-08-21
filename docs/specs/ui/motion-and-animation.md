# Motion & Animation Specification

**Status:** Draft

## 1. Purpose

Define the motion and animation behavior for Productivity OS.

The purpose of motion is to make the interface feel:

- Alive.
- Responsive.
- Smooth.
- Premium.
- Natural.
- Easy to understand.

Motion must support usability and visual continuity.

It must never become the focus of the interface.

## 2. Design Principle

Productivity OS uses **subtle functional motion**.

The interface should feel responsive without making users consciously notice
the animation.

The desired feeling is:

    "The interface responds naturally."

Not:

    "The interface is animated."

## 3. Motion Principles

### M1. Purposeful

Every animation must have a reason.

Valid reasons include:

- Showing that something changed.
- Connecting cause and effect.
- Helping the user understand navigation.
- Providing feedback.
- Establishing hierarchy.
- Making state transitions feel natural.

Decorative animation without a functional purpose should be avoided.

### M2. Fast

Most interactions should feel immediate.

Animations should normally complete within:

    150–350ms

Longer animations should be reserved for larger transitions such as entering
Focus Mode.

### M3. Subtle

Motion should use:

- Small translations.
- Soft fades.
- Small scale changes.
- Opacity changes.
- Height transitions where appropriate.
- Gentle color changes.

Avoid aggressive movement.

### M4. Consistent

Similar interactions should use similar motion.

For example:

- Opening any contextual panel should use the same transition.
- Opening any dialog should use the same transition.
- Hover states should behave consistently.
- Buttons should use consistent feedback.

### M5. Hierarchy

Important elements may receive stronger motion than secondary elements.

For example:

    Focus Mode
        ↓
    stronger transition

while:

    Checkbox
        ↓
    subtle transition

## 4. Motion Timing

### Micro interaction

Typical duration:

    120–180ms

Use for:

- Hover.
- Focus.
- Button feedback.
- Icon changes.
- Small color transitions.

### Standard transition

Typical duration:

    180–280ms

Use for:

- Panels.
- Dialogs.
- Dropdowns.
- Filter changes.
- Task list changes.

### Large transition

Typical duration:

    280–450ms

Use sparingly for:

- Focus Mode entry.
- Focus Mode exit.
- Major workspace transitions.
- Large contextual changes.

Animations longer than approximately 450ms should require a specific
interaction reason.

## 5. Easing

Use natural easing.

Preferred:

- `ease-out` for elements entering.
- `ease-in` for elements leaving.
- `ease-in-out` for state changes.

Avoid:

- Bounce.
- Elastic.
- Strong overshoot.
- Repeated oscillation.

The product should feel calm rather than playful.

## 6. Page Navigation

Navigating between major application pages should use a subtle transition.

Preferred behavior:

    Current page
        ↓
    slight fade / movement
        ↓
    New page

The transition must be short enough that navigation still feels immediate.

Do not use dramatic page transitions.

## 7. Sidebar Navigation

When selecting a navigation item:

- Active background transitions smoothly.
- Icon/text emphasis transitions subtly.
- Content does not dramatically shift.

The active indicator should feel like it belongs to the navigation rather
than appearing suddenly.

## 8. Hover States

Interactive elements should respond subtly to pointer movement.

Examples:

### Buttons

- Slight background change.
- Small elevation/glow change.
- Optional 1–2px upward movement.

### Task rows

- Slight surface elevation.
- Border contrast increase.
- Action controls fade into view.

### Project/Goal surfaces

- Slight elevation.
- Slight border/accent enhancement.

Avoid large scale changes.

Typical scale:

    1.00 → 1.01

Never use large zoom effects for normal UI controls.

## 9. Focus States

Keyboard focus should be visually obvious.

Focus indicators may animate subtly when appearing, but accessibility takes
priority over animation.

Focus states must remain visible even when reduced motion is enabled.

## 10. Buttons

Buttons should provide immediate interaction feedback.

Examples:

    Idle
      ↓
    Hover
      ↓
    Press
      ↓
    Completed

Press feedback may include:

- Small scale reduction.
- Surface change.
- Accent intensity change.

Keep the effect subtle.

Do not use large button animations.

## 11. Task Interaction

### Selecting a task

When selecting a task:

- Selection state appears smoothly.
- Border/accent transitions.
- Contextual details may fade/slide into view.

### Completing a task

Task completion may use:

1. Checkbox/state transition.
2. Short visual confirmation.
3. Reduced visual emphasis.
4. Optional movement into the completed section.

The animation should communicate:

> "This task is now complete."

It should not celebrate excessively.

### Deleting a task

A deleted task may:

- Fade slightly.
- Collapse from the list.
- Preserve surrounding layout where practical.

Avoid sudden disappearance.

### Restoring a task

Restoration may use a short fade/slide into its appropriate position.

## 12. List Changes

When items are:

- Added.
- Removed.
- Reordered.
- Filtered.

Use smooth positional transitions where practical.

The goal is to preserve spatial continuity.

Example:

    Task A
    Task B
    Task C

Task B removed:

    Task A
    Task C

Task C should smoothly move into its new position rather than instantly
jumping.

## 13. Filters

Changing filters should feel immediate.

Preferred:

- Content transitions smoothly.
- No full-page reload animation.
- No large loading overlay.

Use subtle fade/position changes for the changing results.

## 14. Search

Search results should update naturally.

Avoid aggressive animation for every keystroke.

Search result changes may use:

- Small opacity transition.
- Position transition.

The interface should remain responsive.

## 15. Dialogs

Dialogs should enter with:

- Slight fade.
- Slight scale.

Example:

    opacity: 0 → 1
    scale: 0.98 → 1.00

The background overlay may fade in slightly.

Dialogs should exit slightly faster than they enter.

Avoid dramatic zoom effects.

## 16. Contextual Panels

The right-side contextual panel is an important interaction pattern.

Opening:

    panel enters from the side
    + opacity transition

Closing:

    panel exits smoothly
    + surrounding content remains stable where practical

Typical duration:

    220–300ms

The panel should feel connected to the workspace.

## 17. Cards and Surfaces

Cards should not constantly animate.

Motion should occur primarily when:

- Hovering.
- Entering the viewport.
- Changing state.
- Becoming selected.

Avoid continuous floating or pulsing cards.

## 18. Toasts and Notifications

Notifications should appear quickly and unobtrusively.

Preferred:

    fade + small vertical movement

Example:

    opacity: 0 → 1
    translateY: 8px → 0

Dismissal should be faster.

Do not make notifications bounce.

## 19. Loading

Loading states should feel calm.

Preferred:

- Skeleton shimmer.
- Subtle opacity pulse.
- Local loading indicators.

Avoid large spinning loaders unless absolutely necessary.

Skeleton animation should remain low contrast.

## 20. Progress

Progress indicators may animate when a value changes.

Example:

    42% → 48%

The progress bar should smoothly move between values rather than jump.

The animation should remain short and subtle.

## 21. Calendar

Calendar interactions may use:

- Smooth selected-date transition.
- Subtle date highlighting.
- Small horizontal transition when switching date ranges.

Avoid large calendar page animations.

## 22. Focus Mode

Focus Mode is the strongest motion experience in Productivity OS.

Entering Focus Mode may use:

- Workspace simplification.
- Sidebar reduction.
- Fade of secondary content.
- Expansion of the focus surface.
- Timer appearing with a subtle scale/fade.

Conceptually:

    Normal Workspace
          ↓
    Secondary content fades/reduces
          ↓
    Focus workspace expands
          ↓
    Timer becomes dominant

The total transition should remain approximately:

    300–450ms

Focus Mode should feel immersive without feeling theatrical.

## 23. Focus Timer

The timer itself should remain visually stable.

Do not animate every digit unnecessarily.

Allowed:

- Subtle glow while active.
- Gentle state transition when paused/resumed.
- Smooth transition when session starts/stops.

Avoid:

- Pulsing every second.
- Constant scaling.
- Flashing.
- Large visual effects.

## 24. AI Motion

AI elements may use slightly more expressive motion than normal UI.

Examples:

- AI Briefing appearing with a subtle glow/fade.
- Recommendation appearing smoothly.
- AI-generated content entering incrementally.

However:

AI must still feel calm and premium.

Avoid:

- Typing-animation everywhere.
- Constant glowing AI surfaces.
- Floating particles.
- Large animated orbs constantly moving.

AI should feel intelligent, not theatrical.

## 25. Today Page

Today should use motion primarily to establish hierarchy.

Examples:

- AI briefing enters subtly.
- Today's priorities appear naturally.
- Schedule updates smoothly.
- Focus summary transitions when values change.
- Recent activity updates without abrupt movement.

Avoid animating every section simultaneously.

## 26. Projects

Projects may use:

- Smooth filter transitions.
- Project detail panel transitions.
- Progress bar animation.
- New project appearance.
- Archive/restore transitions.

Project cards should otherwise remain visually stable.

## 27. Goals

Goals may use:

- Progress transitions.
- Goal detail panel transitions.
- Completion state transition.
- Reopen flow transitions.
- Project selection transitions during goal reopening.

Avoid gamified celebration.

Completion should feel satisfying but understated.

## 28. Accessibility — Reduced Motion

The system must respect:

    prefers-reduced-motion

When reduced motion is enabled:

- Remove large transitions.
- Remove ambient animation.
- Remove unnecessary movement.
- Preserve state changes through opacity or instant transitions where
  necessary.
- Never hide important information because animation is disabled.

The application must remain fully usable without animation.

## 29. Performance

Animations must remain smooth on normal desktop hardware.

Avoid animating expensive layout properties unnecessarily.

Prefer GPU-friendly properties such as:

- `transform`
- `opacity`

Avoid frequent expensive animation of:

- Width.
- Height.
- Position through layout.
- Large box-shadow changes.

Do not introduce animation libraries unless there is a clear benefit.

## 30. No Continuous Motion

The application must not contain continuous decorative motion by default.

Examples explicitly discouraged:

- Floating cards.
- Constantly rotating icons.
- Moving gradients everywhere.
- Animated background particles.
- Constant pulsing buttons.
- Constantly moving AI illustrations.

The product should feel alive through interaction, not through constant movement.

## 31. Motion Hierarchy

Motion intensity should follow:

    Micro interaction
        ↓
    Component transition
        ↓
    Workspace transition
        ↓
    Focus Mode

The majority of interactions should use the first two levels.

## 32. Implementation Guidance

Create shared motion tokens rather than defining arbitrary durations in every
component.

Conceptually:

    motion-fast
    motion-standard
    motion-slow

And shared easing tokens.

Components should reuse these values.

Do not create independent animation styles for every feature.

## 33. Visual Quality Rule

Motion must never compensate for weak layout or visual hierarchy.

First ensure:

- typography
- spacing
- hierarchy
- contrast
- layout

are correct.

Then add motion.

Motion is enhancement, not structure.

## 34. First Implementation Scope

Apply motion to:

- Sidebar selection.
- Buttons.
- Inputs/focus.
- Task rows.
- Filters.
- Dialogs.
- Contextual panels.
- Toasts.
- Loading skeletons.
- Progress indicators.
- Page transitions.
- Focus Mode.
- AI surfaces.

Do not create complex animation systems.

## 35. Out of Scope

- Advanced physics animation.
- 3D animation.
- Particle systems.
- Lottie-heavy interfaces.
- Video backgrounds.
- Game-like effects.
- Continuous ambient animation throughout the application.

## 36. Change History

- Initial Motion & Animation specification created to add subtle,
  functional motion to the Productivity OS visual system.
