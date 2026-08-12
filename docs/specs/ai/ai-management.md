# AI Capabilities

**Status:** Draft

## Purpose

Define how AI capabilities integrate with the Productivity OS. AI is an external intelligence service that operates on domain data and produces recommendations. It never silently modifies user data.

Per `docs/architecture/system.md` and `docs/architecture/domain.md`: AI is not a domain module — it is an external capability behind an explicit service boundary. The product works entirely without it.

## Capabilities (Phase 5 — Roadmap)

- **Task breakdown:** AI suggests breaking a goal or project into smaller tasks.
- **Planning recommendations:** AI suggests which tasks to plan for a given day based on deadlines, priorities, and capacity.
- **Next-action recommendations:** AI suggests the next task to work on.
- **Weekly review:** AI analyzes completed work, planned vs actual, and patterns.
- **Progress analysis:** AI evaluates goal/project progress from task completion data.

## Constraints

1. AI recommendations never silently modify user data. Every AI-suggested change requires explicit user confirmation.
2. Deterministic product behavior is fully testable without an LLM.
3. AI operates on read models flowing out of the domain; recommendations flow back in.
4. Domain data passed to AI must be user-scoped and never cross user boundaries.

## Dependencies

- All domain modules (Tasks, Projects, Goals, Daily Plan, Top 3, Focus Sessions)
- Weekly Review specification (future)
- Progress specification (future)

## Open Questions

1. Which AI provider/model to use?
2. How to structure the AI service boundary (REST endpoint, separate service, in-process)?
3. What prompt templates and context windows are needed per capability?
4. Should the AI service have access to historical data or only current state?
5. How to measure AI recommendation quality?

## Change History

- Placeholder created. Detailed behavioral specifications for each capability will be written when Phase 5 begins.
