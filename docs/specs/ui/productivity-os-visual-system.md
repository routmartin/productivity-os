# Productivity OS Visual System & Today Workspace

**Status:** Draft

## 1. Purpose

Define the visual system and primary Today workspace for Productivity OS.

This specification is intentionally visual and implementation-oriented.

The approved visual reference image is:

```
docs/design/references/productivity-os-today-v2.png
```

The reference image is the visual source of truth for the overall composition,
layout proportions, spacing rhythm, typography scale, visual hierarchy,
surface treatment, and color relationships.

The implementation must visually match the reference rather than merely
implementing the same content.

## 2. Design Direction

Productivity OS is a premium desktop-first productivity workspace.

The visual character is:

- Spacious.
- Comfortable to read.
- Premium.
- Calm.
- Focused.
- Intelligent.
- Modern.
- Dark.
- Content-oriented rather than dashboard-oriented.

The interface must not feel:

- Dense.
- Tiny.
- Administrative.
- Enterprise-heavy.
- Overly gamified.
- Visually noisy.

## 3. Primary Design Principle

The interface should prioritize:

1. Readability.
2. Visual breathing room.
3. Strong hierarchy.
4. Large meaningful content surfaces.
5. Few competing elements.
6. Clear relationships between related information.

The user should understand the page at a glance without needing to inspect
small text or tightly packed controls.

## 4. Desktop Baseline

The primary design target is a 1600 × 900 desktop viewport.

The UI must remain visually coherent around:

- 1440 × 900.
- 1536 × 864.
- 1600 × 900.
- 1920 × 1080.

Do not optimize the first implementation around mobile.

Desktop is the primary product experience.

## 5. Global Layout

The authenticated workspace consists of:

```
┌─────────────────────────────────────────────────────────────┐
    │ Sidebar │ Global Header                                    │
    ├─────────┼───────────────────────────────────────────────────┤
    │ Sidebar │ Main Workspace                                   │
    │         │                                                   │
    │         │                                                   │
    └─────────┴───────────────────────────────────────────────────┘
```

### Sidebar

Approximate width:

```
230–250px
```

Target:

```
236px
```

The sidebar remains fixed on desktop.

### Global header

Approximate height:

```
72px
```

The header contains:

- Current page.
- Search.
- Notifications.
- Theme/settings utility.
- User context where appropriate.

The global header should remain visually quiet.

## 6. Sidebar

The sidebar uses the same dark surface as the overall application.

It contains:

### Brand

```
Productivity OS
```

The brand icon uses the primary purple accent.

### Main navigation

- Today
- Inbox
- Tasks
- Projects
- Goals
- Focus
- AI

Today is the primary entry point.

The active navigation item uses:

- Subtle elevated surface.
- Purple accent.
- Stronger text.
- Rounded background.

### Favorites

Show favorite projects/goals using small accent indicators.

Example:

```
● Productivity OS
    ● Mobile App
    ● Personal Growth
```

### Views

Secondary navigation may include:

- Calendar
- Timeline

These are navigation concepts, not necessarily fully implemented in V1.

### Bottom navigation

- Settings.
- Log out.
- User profile.

## 7. Background

Primary application background:

```

```

#0B0D12

The background should remain visually quiet.

Avoid strong gradients across the entire page.

Localized gradients and ambient light may be used inside special surfaces.

## 8. Surface System

Use a small number of dark surfaces.

### Base

```

```

#0B0D12

### Surface

```

```

#11141B

### Elevated Surface

```

```

#151925

### Strong Surface

```

```

#1B2030

### Border

```
rgba(255,255,255,0.07)
```

### Strong Border

```
rgba(255,255,255,0.11)
```

Surfaces should have subtle separation rather than heavy shadows.

## 9. Accent System

Primary accent:

```

```

#6C5CE7

Secondary purple:

```

```

#8B6CFF

Blue:

```

```

#3B82F6

Green:

```

```

#39C58A

Amber:

```

```

#F4B740

Red:

```

```

#F05A5A

Purple is strongly associated with AI and Focus.

Color is semantic.

Do not use many unrelated colors simply for decoration.

## 10. Typography

The application must use a modern UI sans-serif.

Preferred:

- Inter
- Geist
- Equivalent high-quality system UI font

### Scale

#### Page hero

```
42–48px
```

Weight:

```
600–700
```

#### Major section title

```
22–26px
```

Weight:

```
600
```

#### Regular heading

```
18–20px
```

Weight:

```
600
```

#### Body

```
15–17px
```

Weight:

```
400–500
```

#### Metadata

```
13–14px
```

Weight:

```
400–500
```

The minimum normal body size should generally be 15px.

Do not use the compact 11–12px metadata-heavy style from typical SaaS
dashboards.

## 11. Line Height

Use generous line height:

- Large headings: 1.1–1.2
- Body: 1.45–1.6
- Metadata: 1.4

## 12. Spacing

Use a generous spacing system.

Primary spacing units:

```
8
    12
    16
    24
    32
    40
    48
    64
```

Sections should generally be separated by at least:

```
24–32px
```

Major workspace sections:

```
32–48px
```

Avoid tightly stacking unrelated sections.

## 13. Border Radius

Use large but controlled rounding:

### Small

```
10px
```

### Standard

```
14px
```

### Large panel

```
18–20px
```

### Pill

```
999px
```

Avoid extreme rounded "bubble" interfaces.

## 14. Buttons

Primary buttons should be comfortable desktop targets.

Minimum height:

```
42px
```

Preferred:

```
44–48px
```

Primary action:

- Purple background.
- White text.
- Medium/semibold text.
- Soft glow on hover.

Secondary action:

- Dark elevated surface.
- Subtle border.
- Light text.

Buttons should never feel tiny.

## 15. Inputs

Minimum height:

```
44px
```

Preferred:

```
48px
```

Input text:

```
15–16px
```

Placeholder text should remain readable.

## 16. Today Workspace

The Today screen is the visual center of the product.

The upper area contains:

```
Good morning, [Name] 👋
```

```
Let's make today count.
```

```
Focus on your priorities and progress will follow.
```

The first line is contextual.

The second line is the main hero heading.

The hero heading should be large and comfortable to read.

## 17. Today Layout

The main content uses a spacious multi-column workspace.

Conceptually:

```
┌─────────────────────────────────────┬─────────────────────┐
    │ AI Briefing                         │ Calendar            │
    ├──────────────────────┬──────────────┼─────────────────────┤
    │ Today's Schedule      │ Top          │ Focus Today         │
    │                       │ Priorities   │                     │
    ├──────────────────────┴──────────────┼─────────────────────┤
    │ Recent Activity                     │ Daily Summary       │
    └────────────────────────────────────┴─────────────────────┘
```

The right column is narrower than the main workspace.

The main workspace receives the majority of horizontal space.

## 18. AI Briefing

The AI Briefing is a major visual surface near the top of Today.

It should:

- Span the majority of the main content width.
- Have a dark purple-tinted surface.
- Use subtle ambient purple lighting.
- Include a small AI indicator.
- Contain one strong insight.
- Have one primary action.

Example:

```
AI BRIEFING
```

```
You have 3 important things to focus on today.
```

```
Based on your tasks, goals, and recent progress.
```

```
[ Plan My Day ]
```

Do not fill the briefing with several paragraphs.

The visual reference contains an ambient AI orb illustration on the right side
of this surface. Preserve that visual concept.

## 19. Today's Schedule

This is a timeline-oriented workspace.

It should visually communicate time instead of presenting another flat list.

Example:

```
09:00   ●   Finish authentication
                 Productivity OS · High Priority     90m
```

```
10:30   ●   Review API implementation
                 Productivity OS · Medium Priority   45m
```

```
12:00   ●   Lunch Break
                 Take a break and recharge            60m
```

```
14:00   ●   Build task dashboard
                 Productivity OS · High Priority    120m
```

```
16:00   ●   Write documentation
                 Productivity OS · Low Priority      60m
```

Tasks should use lightly tinted surfaces.

Do not make the timeline visually dense.

## 20. Top Priorities

This is the compact high-priority task list.

Show exactly three primary priorities.

Each item includes:

- Rank.
- Title.
- Project.
- Priority.
- Completion control.

The ranking must be immediately visible.

Example:

```
1  Finish authentication flow
    2  Review API implementation
    3  Build task dashboard
```

The three items should not be tiny.

## 21. Calendar

Calendar sits in the upper-right workspace.

It should use a horizontal date selector.

Example:

```
MON   TUE   WED   THU   FRI   SAT   SUN
     23    24    25   [26]   27    28    29
```

The selected day should use the purple accent.

Below the dates, show the selected day's important calendar/event context.

The calendar surface should feel spacious rather than like a tiny month widget.

## 22. Focus Today

The Focus surface is positioned on the right side.

Show:

```
Focus Today
```

```
2h 47m
```

```
Total focused time
```

```
↑ 22% vs yesterday
```

Include a restrained circular visualization.

Do not make the chart dominate the panel.

## 23. Daily Summary

Show a compact summary surface:

```
2h 47m       3             48m
    Focused      Sessions      Average
```

Use three clear values.

These are secondary metrics.

## 24. Recent Activity

Show recent productivity activity.

Example:

```
Completed "Database schema design"
    2 hours ago
```

```
Created new task "Fix validation issue"
    3 hours ago
```

```
Completed "Setup CI/CD pipeline"
    Yesterday
```

Each item should use a recognizable icon and comfortable vertical spacing.

## 25. Focus Tip

The bottom-right area may contain a small Focus Tip.

Example:

```
Focus Tip
```

```
Turn off notifications and stay in the zone.
```

The panel may contain a restrained purple ambient illustration.

Do not make the tip visually dominant.

## 26. General Card Rules

Cards are used to group meaningful information.

Cards must have:

- Generous internal padding.
- Large enough text.
- Clear title.
- Clear grouping.
- Comfortable spacing.

Avoid:

- Tiny cards.
- Five cards squeezed into one row.
- Several layers of cards inside cards.
- Excessive metadata.

## 27. Density Rule

A desktop viewport should not feel like a compressed information dashboard.

The user should be able to comfortably scan the screen from normal monitor
distance.

Prefer:

```
fewer + larger elements
```

over:

```
more + smaller elements
```

## 28. Information Hierarchy

Priority order:

1. Page hero.
2. AI briefing.
3. Schedule / priorities.
4. Focus / calendar.
5. Recent activity.
6. Secondary statistics.

Text must visually reflect this hierarchy.

## 29. Task Visual Language

Tasks should use large readable titles.

Example:

```
Finish authentication
```

```
Productivity OS · High Priority
```

Metadata must remain secondary.

Avoid putting too many tiny badges next to the task title.

## 30. Empty States

Empty states should use:

- Large heading.
- Short explanation.
- Clear primary action.

Avoid tiny empty-state text.

## 31. Loading

Use spacious skeletons matching the final surface dimensions.

Do not replace entire pages with a tiny spinner.

## 32. Responsive Behavior

Desktop-first.

At smaller desktop widths:

- Reduce secondary content.
- Collapse the right column.
- Preserve the main schedule and priorities.
- Keep typography readable.
- Reduce the amount of information before reducing font size.

Do not solve responsiveness by shrinking everything.

## 33. Accessibility

Minimum goals:

- Body text 15px or larger.
- Strong text contrast.
- Visible keyboard focus.
- Minimum 42–44px interactive controls.
- Do not communicate meaning through color alone.
- Clear heading hierarchy.

## 34. Animation

Animations are subtle.

Use:

- Fade.
- Small slide.
- Soft scale.
- Progress transitions.
- Hover illumination.

Avoid:

- Continuous motion.
- Flashing.
- Large parallax.
- Distracting decorative animation.

## 35. Visual Reference Priority

When the written description and implementation interpretation conflict,
follow this order:

1. `docs/design/references/productivity-os-today-v2.png`
2. This visual specification.
3. Existing shared components.
4. General frontend conventions.

Do not redesign the page according to personal interpretation.

## 36. Future Screen Patterns

This visual system establishes five UI patterns:

### Workspace

Today / Projects / Goals

### List

Tasks / Inbox

### Timeline

Daily Planning / Calendar

### Immersive

Focus

### Intelligence

AI

Future screens should preserve the same typography, spacing, surfaces,
controls, and visual hierarchy.

## 37. Implementation Constraint

This specification defines the visual system.

During the current UI phase:

- Use mock data.
- Do not connect APIs unless explicitly requested.
- Do not modify backend code.
- Do not introduce a new design system.

## 38. Change History

- Visual system revised after review of multiple external visual references
  and the approved Productivity OS visual concept.
- Design direction changed from compact dashboard-oriented UI toward a
  spacious productivity workspace.
