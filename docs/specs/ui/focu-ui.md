# Focus UI Specification

**Status:** Draft

## 1. Problem

Productivity OS needs a dedicated Focus experience that helps users stop
organizing and start working.

The Focus interface should remove distractions and make the currently
focused task the dominant piece of information.

## 2. Goal

Create a focused working environment that allows users to:

- Select a task to work on.
- Start a Focus Session.
- See elapsed focus time clearly.
- Pause a session.
- End a session.
- See the currently focused task.
- Access only the minimum contextual information needed while focusing.
- Review recent Focus history outside an active session.

The Focus experience should feel like entering a different mode of the
application.

## 3. Design Principle

Normal Productivity OS:

    ORGANIZE → PLAN → REVIEW

Focus Mode:

    EXECUTE

The UI should become visually simpler when a session starts.

## 4. Design Direction

Use the existing Productivity OS visual language:

**Calm Command Center**

But Focus should be more immersive.

The experience should feel:

- Calm
- Immersive
- Focused
- Minimal
- Premium
- Quiet

Avoid:

- Dense dashboards.
- Large navigation areas.
- Unnecessary metadata.
- Excessive controls.
- Gamification.
- Distracting notifications.

## 5. Focus States

The Focus UI has three primary states:

### Idle

No active session.

    FOCUS

    What do you want to work on?

    [ Select a task ]

    [ Start Focus ]

### Active

A Focus Session is currently running.

    FOCUS

    Finish authentication

    Productivity OS

              42:18

        [ Pause ]   [ Stop ]

### Paused

The active session exists but the timer is paused.

    PAUSED

    Finish authentication

              42:18

        [ Resume ]  [ Stop ]

The visual difference between Active and Paused must be immediately obvious.

## 6. Focus Entry Screen

When no session is active, show:

- Page title.
- Short explanation.
- Task selector.
- Recent or recommended tasks.
- Start Focus action.
- Recent focus history.

The task selector should prioritize:

- In-progress tasks.
- Planned tasks.
- Other eligible active tasks.

The first UI milestone uses mock data.

## 7. Task Selection

The user chooses a task before starting a Focus Session.

Task selection may use:

- Search.
- Recent tasks.
- Top tasks.
- Planned tasks.

The selected task should be visually obvious.

Example:

    SELECT TASK

    ○ Finish authentication
      Productivity OS

    ○ Build task dashboard
      Productivity OS

    ○ Review API implementation
      Productivity OS

    [ Start Focus ]

## 8. Active Focus Screen

When a session starts, the interface should simplify.

The focus area should visually dominate the page.

Conceptually:

    ┌────────────────────────────────────────────┐
    │                                            │
    │                  FOCUS                     │
    │                                            │
    │            Finish authentication           │
    │                                            │
    │              Productivity OS               │
    │                                            │
    │                  42:18                     │
    │                                            │
    │         [ Pause ]     [ Stop ]             │
    │                                            │
    └────────────────────────────────────────────┘

The timer should be the strongest visual element.

## 9. Timer

The timer displays elapsed focus duration.

Format:

    HH:MM:SS

The timer must remain visually readable from a distance.

Use subtle animation, but do not animate every digit aggressively.

The first implementation may use a local mock timer.

## 10. Active Navigation

While Focus is active:

- The user may leave the Focus route.
- The application should preserve the active session state visually.
- Returning to Focus should show the current session.

The first UI milestone may simulate this behavior locally.

## 11. Focus Actions

The active session provides:

- Pause.
- Resume.
- Stop.

The Stop action should require a clear visual distinction from Pause/Resume.

A destructive confirmation may be used when appropriate.

## 12. Stop Session

Stopping a session should communicate that the focus period has ended.

Example:

    Focus complete

    Finish authentication

    42m 18s

    Nice work.

    [ Done ]

The first milestone may show a completion state without persisting anything.

Avoid excessive celebration or gamification.

## 13. Focus History

Outside an active session, provide recent history.

Example:

    RECENT FOCUS

    Finish authentication       42m
    Build task dashboard        31m
    Review API implementation   54m
    Documentation               27m

History should remain lightweight.

## 14. Focus Statistics Preview

The Focus screen may show a small summary:

    TODAY

    2h 47m focused

    3 sessions

    48m average

These are mock values for the UI milestone.

Do not turn Focus into an analytics dashboard.

## 15. Task Context

The current task may show minimal context:

- Project.
- Goal.
- Priority.

Only show information useful for focusing.

The Focus screen should not become another Task detail page.

## 16. Optional Context Panel

The existing contextual panel system may be hidden or simplified while
Focus is active.

The active Focus experience should have the largest possible visual
workspace.

## 17. Idle Empty State

If there are no eligible tasks:

    Nothing to focus on yet.

    Create or plan a task first.

    [ Go to Tasks ]

## 18. Loading States

Use lightweight loading states for:

- Task selection.
- Focus history.
- Session state.

Avoid a full-page spinner.

## 19. Error States

Use concise errors:

- Unable to load focus session.
- Unable to start focus.
- Unable to stop focus.

Do not expose raw backend errors.

## 20. Responsive Behavior

Desktop is the primary experience.

Focus should work well at:

- Laptop widths.
- Large desktop displays.

At smaller widths:

- Reduce secondary content.
- Preserve the timer and current task as the primary content.

The timer must remain prominent.

## 21. Motion

Allowed:

- Smooth transition into Focus Mode.
- Timer emphasis.
- Pause/resume state transition.
- Completion transition.
- Subtle background motion.

Avoid:

- Constant particle effects.
- Excessive glow.
- Large animated illustrations.
- Distracting motion.

## 22. Mock Data

Use realistic tasks:

- Finish authentication
- Build task dashboard
- Review API implementation
- Write documentation
- Review database schema

Example history:

    Finish authentication       42m
    Build task dashboard        31m
    Review API implementation   54m
    Documentation               27m

Example current summary:

    Today
    2h 47m focused
    3 sessions
    48m average

## 23. First Implementation Scope

Build:

- Focus route.
- Idle state.
- Task selector.
- Active session state.
- Paused session state.
- Timer.
- Start/Pause/Resume/Stop interactions.
- Session completion state.
- Recent focus history.
- Lightweight statistics.
- Loading states.
- Empty states.
- Error states.
- Responsive desktop behavior.

Use mock data and local state only.

## 24. First Implementation Exclusions

Do not implement:

- Real Focus API integration.
- Real session persistence.
- Backend changes.
- Automatic session expiration.
- Background activity tracking.
- Pomodoro configuration.
- Break scheduling.
- Productivity scoring.
- AI focus recommendations.
- Focus streaks.
- Device/app usage tracking.

## 25. Reusable Components

Potential components:

- FocusTimer
- FocusTaskSelector
- FocusControls
- FocusSessionCard
- FocusHistory
- FocusSummary
- FocusCompletion
- EmptyState
- LoadingState

Reuse existing UI primitives.

Do not create a separate UI framework.

## 26. Architecture

Use the existing feature structure:

    features/
      focus/
        components/
        pages/
        data/
        types/

The Focus feature should reuse shared layout, typography, buttons,
dialogs, and contextual components from the existing application.

## 27. Dependencies

- frontend-ui.md
- Task Management Specification
- Focus Management Specification
- Projects UI
- Goals UI
- ADR-002
- ADR-005
- ADR-006

## 28. UI Milestone Constraint

This is a UI-only milestone.

**Mock data and local state only.**

Do not connect backend APIs.

Do not modify backend code.

## 29. Change History

- Initial Draft created for the Focus frontend experience.
