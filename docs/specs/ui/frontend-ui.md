# Frontend UI Specification

**Status:** Draft

## 1. Problem

Productivity OS needs a frontend workspace that makes it easy for users to
understand what matters, organize their work, and enter a focused working
state.

The interface should feel like a premium productivity workspace rather than
a generic SaaS administration dashboard.

## 2. Goal

Create a premium, desktop-first productivity workspace with:

- Today as the primary workspace.
- Fast access to tasks and productivity areas.
- Clear visual hierarchy.
- A calm and focused visual language.
- Contextual information without unnecessary navigation.
- A dedicated Focus experience.
- A distinct but restrained AI visual language.

The first frontend milestone focuses on the application shell and Today
experience using realistic mock data.

## 3. Design Direction

The visual direction is:

**Calm Command Center**

The interface should feel:

- Calm
- Focused
- Intelligent
- Premium
- Fast

The design should be visually polished without becoming visually noisy.

### Avoid

- Generic enterprise dashboards.
- Excessive cards.
- Excessive gradients.
- Excessive shadows.
- Large decorative illustrations.
- Excessive colors.
- Gamification-heavy UI.
- Unnecessary animations.

## 4. Platform

The V1 frontend is desktop-first.

The UI should support common desktop workspace sizes and remain usable at
smaller widths.

Responsive behavior should be considered from the beginning, but mobile
optimization is not the primary focus of this milestone.

## 5. Technology

The frontend uses the technology selected by ADR-002:

- Vue 3
- TypeScript
- Vite

The frontend must remain compatible with the existing repository structure
and backend architecture.

## 6. Application Shell

The authenticated application uses a three-zone workspace:

1. Left navigation sidebar.
2. Main workspace.
3. Contextual right panel.

Conceptually:

```
┌────────────┬─────────────────────────────┬─────────────────┐
    │            │                             │                 │
    │ Navigation │       Main Workspace         │ Context Panel   │
    │            │                             │                 │
    │            │                             │                 │
    └────────────┴─────────────────────────────┴─────────────────┘
```

The right panel is contextual and should not unnecessarily consume the
workspace when no context is selected.

## 7. Navigation

The primary navigation contains:

- Today
- Inbox
- Tasks
- Projects
- Goals
- Focus
- Settings

Today is the primary destination and should have the strongest visual
emphasis.

The navigation should remain visually simple and easy to scan.

## 8. Today

Today is the primary screen of Productivity OS.

The screen should provide an immediate answer to:

> What matters today?

The initial Today layout contains:

1. Date and greeting.
2. AI Briefing.
3. Today's Top 3.
4. Planned tasks.
5. Unplanned tasks.
6. Focus section.
7. AI Insights.
8. Calendar/context information.
9. Recent tasks.

The first implementation may use realistic mock data.

## 9. Today Header

The Today header should display:

- Current calendar date.
- Greeting.
- Short contextual message.

Example:

```
Wednesday
    August 12
```

```
Good afternoon.
```

```
3 things matter today.
```

The exact copy is implementation content and may change.

## 10. Today's Top 3

The Top 3 section visually emphasizes the user's three most important
tasks for the day.

Each item should clearly communicate:

- Position.
- Task title.
- Task status.
- Relevant metadata.

Example:

```
TODAY'S TOP 3
```

```
① Finish authentication
       IN PROGRESS
```

```
② Build task dashboard
       PLANNED
```

```
③ Review API implementation
       PLANNED
```

Top 3 ordering should be visually obvious.

The first frontend milestone uses mock data.

## 11. Tasks

Tasks should be represented primarily as lightweight rows rather than large
cards.

Example:

```
○ Finish authentication                 Today
      Productivity OS                       1h 30m
```

Hovering a task may reveal secondary actions.

Selecting a task may open its details in the contextual right panel.

The UI should avoid requiring navigation to a separate page for simple task
inspection.

## 12. Task Detail Panel

The contextual task panel may contain:

- Task title.
- Status.
- Description.
- Project.
- Goal.
- Priority.
- Estimated duration.
- Due information.
- Focus action.
- Other relevant actions.

The first milestone does not need full task functionality.

The panel may use mock data.

## 13. Focus

The Today screen should contain a clear Focus entry point.

Example:

```
FOCUS
```

```
Ready to focus?
```

```
[ Start Focus ]
```

The first milestone does not implement actual Focus functionality.

The UI should establish the visual language for the future Focus feature.

## 14. Focus Mode

The eventual Focus Mode should be intentionally minimal.

Conceptually:

```
FOCUS
```

```
Build Task Dashboard
```

```
42:18
```

```
[ Pause ]    [ Stop ]
```

Normal navigation and unrelated information should be visually reduced
during active Focus Mode.

Actual Focus behavior is outside the scope of the first frontend milestone.

## 15. AI Visual Language

AI should have a distinct visual identity without dominating the product.

AI may use a restrained purple accent.

AI UI should visually communicate:

> Recommendation, not authority.

Example:

```
✦ AI Briefing
```

```
You have more planned work than available
    focus time today.
```

```
Consider moving "Write documentation"
    to tomorrow.
```

```
[ Apply ]    [ Ignore ]
```

The first milestone uses mock AI content only.

No real AI functionality is implemented.

## 16. Color

The interface is dark-first.

The base palette should remain primarily neutral.

Conceptual palette:

- Deep dark background.
- Slightly lighter surface.
- Elevated surface.
- Subtle border.
- Primary light text.
- Secondary gray text.
- Muted gray text.

A restrained primary blue/purple accent may be used for primary actions.

Purple is primarily associated with AI.

Semantic colors may communicate:

- Success/completed.
- Attention.
- Error/destructive actions.

Color should communicate meaning rather than act as decoration.

## 17. Typography

Typography should provide strong hierarchy.

Preferred direction:

- Inter, Geist, or an equivalent modern UI typeface.
- Clear heading hierarchy.
- Medium-weight task titles.
- Smaller metadata.
- Avoid excessive bold text.

Spacing and hierarchy should carry more of the visual structure than heavy
borders or containers.

## 18. Surfaces and Components

The UI should not place every piece of information inside a card.

Prefer:

- Sections.
- Rows.
- Panels.
- Dividers.
- Inline controls.
- Contextual surfaces.

Cards should be reserved for information that is genuinely independent or
important.

## 19. Motion

Animations should be subtle and purposeful.

Appropriate uses include:

- Opening contextual panels.
- Sidebar transitions.
- Task completion.
- Focus transitions.
- AI recommendation appearance.
- Top 3 reordering.

Avoid continuous or decorative animation.

## 20. Loading States

Every data-driven area should have an appropriate loading state.

Loading states should preserve the layout rather than causing large layout
shifts.

The first milestone may implement representative loading states even when
using mock data.

## 21. Empty States

Empty states should be useful and action-oriented.

Example:

```
No tasks yet.
```

```
Capture something you're thinking about.
```

```
[ Create Task ]
```

Avoid empty screens with no explanation or next action.

## 22. Error States

Errors should be:

- Clear.
- Concise.
- Non-technical where possible.
- Recoverable when possible.

The UI should not expose raw backend exceptions.

## 23. Responsive Behavior

At smaller desktop widths:

- The right contextual panel may collapse.
- The sidebar may reduce to an icon-based navigation.
- Main workspace remains the priority.

At mobile widths, the implementation may use a simplified navigation pattern.

Full mobile optimization is not required for the first milestone.

## 24. Accessibility

The frontend should provide:

- Keyboard-accessible interactive controls.
- Visible focus states.
- Semantic buttons and links.
- Sufficient text contrast.
- Meaningful labels for icon-only controls.
- No information conveyed by color alone.

## 25. First Milestone Scope

The first implementation milestone is:

**Login → Authenticated App Shell → Today Dashboard**

It includes:

- Vue application bootstrap.
- Routing.
- Login screen.
- Authenticated application shell.
- Sidebar navigation.
- Header.
- Today dashboard.
- Top 3 mock data.
- Task mock data.
- AI briefing mock data.
- Focus mock section.
- Contextual task panel.
- Loading states.
- Empty states.
- Basic error states.
- Responsive desktop behavior.

## 26. First Milestone Exclusions

The first milestone does not implement:

- Real task API integration.
- Real Daily Planning API integration.
- Real Top 3 API integration.
- Real Focus functionality.
- Real AI functionality.
- Projects.
- Goals.
- Settings functionality.
- Backend modifications.
- Mobile-specific optimization.

The UI should be structured so these features can be connected later without
redesigning the application shell.

## 27. Architecture

Frontend code should be organized around product capabilities.

Preferred direction:

```
apps/web/
      src/
        app/
          router/
          layouts/
```

```
features/
          auth/
          tasks/
          planning/
          focus/
          ai/
```

```
components/
          ui/
          shared/
```

```
lib/
          api/
          auth/
          utils/
```

```
pages/
```

The exact implementation structure may evolve as the frontend grows.

## 28. Dependencies

- ADR-002 — Technology Stack
- ADR-005 — API Architecture
- ADR-006 — Time and Timezone
- Task Management Specification
- Daily Planning Specification
- Daily Top 3 Specification
- Focus Management Specification
- AI Management Specification

## 29. Open Questions

1. Final font selection.
2. Final accent color values.
3. Exact Today layout after the first interactive prototype.
4. Final mobile navigation pattern.
5. Whether the contextual panel should become a permanent desktop feature.
6. Final component/design-token system.

These questions should be resolved through visual iteration rather than
extended upfront architecture work.

## 30. Change History

- Initial Draft created for the first frontend implementation milestone.
