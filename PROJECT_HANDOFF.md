# PROJECT HANDOFF — Productivity OS + SDD Experiment

We are building a Personal Productivity OS.

The product goal is to help a person:

1. Know what matters.
2. Plan ahead.
3. Know what to do next.
4. Focus on meaningful work.
5. Track meaningful progress.
6. Review what happened.
7. Improve future planning.

This project is ALSO an experimental laboratory for Spec-Driven Development (SDD)
with AI. The goal is not only to build the product, but to experiment with
human + AI software development workflows.

---

# CORE PRODUCT PHILOSOPHY

- Outcomes over activity
- Focus over task volume
- Planning over reacting
- Reality over optimism
- Progress over completion
- Reflection over guilt
- Automation over administration
- AI assists judgment; AI should not silently make important decisions

The system should reduce cognitive load rather than become another system
the user has to constantly manage.

---

# SDD DEVELOPMENT PHILOSOPHY

The default development lifecycle is:

Idea
→ Specification
→ Specification Review
→ Architecture / ADR
→ Implementation Plan
→ Implementation
→ Verification
→ Human Review
→ Ship
→ Experiment / Learn

IMPORTANT:

Specification = WHAT + WHY
Implementation Plan = HOW

Specifications are the source of truth for product behavior.

AI must not silently invent requirements when the specification is ambiguous.

---

# AI ROLES

We eventually want these roles:

1. Product Agent
   Idea → Specification
2. Specification Reviewer
   Challenge specification for ambiguity, missing behavior, edge cases,
   testability, and scope problems.
3. Architect Agent
   Specification → Architecture / ADR / Implementation Plan
4. Developer Agent
   Approved Plan → Code + Tests
5. Reviewer Agent
   Specification + Implementation → Verify implementation against spec

We are NOT starting with a fully autonomous multi-agent system.
We want to first establish a controlled, observable workflow.

---

# HUMAN RESPONSIBILITY

Human decides:

- Why are we building this?
- What behavior do we want?
- What tradeoffs are acceptable?
- Important architecture decisions
- Whether a feature is good enough

AI handles:

- Finding ambiguity
- Proposing implementation approaches
- Writing implementation code
- Writing tests
- Reviewing implementation against specification

---

# REPOSITORY

The repository already contains the SDD foundation:

AGENTS.md
README.md

docs/
product/
vision.md
principles.md
roadmap.md

specs/
README.md
planning/
daily-top-three.md

architecture/
system.md

decisions/
README.md
ADR-001-sdd-workflow.md

plans/
README.md

experiments/
README.md
EXP-001-specification-before-implementation.md

The application code has NOT been started yet.

---

# AGENTS.md RULES

Important rules already established:

- Specification before implementation.
- Read relevant specification before coding.
- Read architecture documentation.
- Inspect existing implementation.
- Produce an implementation plan before coding.
- Implement only approved scope.
- Do not silently change requirements.
- Prefer existing patterns.
- Keep changes small and reviewable.
- Add/update tests for behavioral changes.
- Significant architecture changes require an ADR.
- Verify acceptance criteria before completion.
- Report:
  - summary
  - specification
  - changed files
  - acceptance criteria
  - tests
  - deviations
  - risks
  - follow-ups

---

# FIRST SDD FEATURE

The first feature is:

## Daily Top 3

Purpose:

Help the user identify up to three most important actions for a day.

The specification went through multiple rounds of AI review and product decisions.

The agent should inspect the CURRENT FILE:

docs/specs/planning/daily-top-three.md

Do not assume the text below is newer than the repository file.
The repository file is the current source of truth.

---

# FINAL PRODUCT DECISIONS FOR DAILY TOP 3

These are the decisions agreed during the SDD discussion:

1. Eligible tasks:
   Any active, incomplete task that is not in an archived project.
2. Calendar day:
   User's configured timezone.
   Day boundary is 00:00:00–23:59:59.
3. Unfinished tasks:
   Top 3 tasks do NOT automatically carry over to the next day.
4. Completed tasks:
   A completed task already in that day's Top 3 remains in the Top 3
   and continues occupying its slot.
5. Ordering:
   Top 3 is ordered:
   Position 1 = highest priority
   Position 2
   Position 3
6. Date editing:
   Today and future dates are editable.
   Past dates are view-only.
7. Deleted task:
   Remove immediately from active Top 3.
   Free its slot.
   Preserve historical selection.
8. Archived project:
   Existing Top 3 selection remains visible.
   It cannot be newly selected.
9. Reopened task:
   If a Top 3 task is completed and later reopened,
   it remains in that day's Top 3.
10. History:
    No separate history system.
    Viewing previous dates is the history.
11. Persistence:
    Top 3 selections are server-persisted and associated with
    user + calendar date.
12. Synchronization:
    Multi-device synchronization is expected.
13. Sync conflict:
    Last-write-wins for now, based on server receipt time.
    This is a known limitation.
14. Default position:
    When no position is explicitly specified, put the task into
    the lowest available position.
15. Removal:
    Removing/deleting a task causes remaining tasks to shift upward.

    Example:
    [A, B, C]
    remove A
    → [B, C]
    → B becomes position 1
    → C becomes position 2

16. Historical completion:
    Historical completion state should be frozen as it was
    at the end of that calendar day.
17. Same-day deletion:
    A deleted task disappears from today's active view.
    Its historical record becomes visible when that date is viewed
    as history.
18. User feedback:
    If the Top 3 is full, show clear feedback explaining why another
    task cannot be selected.
19. Ineligible task:
    Show clear feedback explaining why it cannot be selected.
20. Deleted task in historical view:
    Display something like "Deleted task" while preserving its
    original historical position.
21. Visual prominence:
    Exact UI placement is a design concern, not a product-spec requirement.
22. Cross-spec dependencies:
    Terms such as active, incomplete, archived project, and task
    depend on future Task / Project specifications.
    They should not cause unnecessary implementation assumptions.

---

# IMPORTANT SDD LESSON

The Daily Top 3 specification started as a small feature but AI review uncovered
many hidden product decisions.

This is intentional.

We want to prove that:

Specification
→ AI challenge
→ Human decisions
→ Revised specification
→ Architecture
→ Implementation

is better than:

Prompt
→ AI writes code
→ Human discovers hidden decisions afterward.

Do not skip this workflow just because the feature is simple.

---

# CURRENT STATE

The Daily Top 3 specification has been revised multiple times.

The last AI report claimed:

- 15 rules
- 3 constraints
- 24 acceptance criteria
- no remaining major product ambiguity after the final decisions

However, the agent repeatedly failed to change the status from Draft to Proposed.

Therefore:

FIRST inspect the actual current file.

If the current file is still Draft, perform a final consistency review and,
if all decisions above are represented correctly, change the specification
status to:

Proposed

Do NOT implement code yet.

---

# NEXT SDD STAGE

After Daily Top 3 reaches Proposed and has no product-level blockers:

Move to:

## Architecture + Implementation Plan

BUT:

Do not immediately code.

First:

1. Inspect the existing repository.
2. Determine the application technology stack.
3. Identify domain boundaries.
4. Identify Task / Project dependencies.
5. Determine data model implications.
6. Determine API requirements.
7. Determine frontend requirements.
8. Determine testing strategy.
9. Identify architecture decisions requiring ADRs.
10. Produce an implementation plan.

The plan must be based on the approved specification.

Do not invent additional product requirements.

---

# IMPORTANT ARCHITECTURAL PRINCIPLE

Keep deterministic product behavior independent from AI.

AI functionality should eventually sit behind a clear service boundary.

The product should work without an LLM.

AI will later help with:

- breaking goals into projects/tasks
- daily planning
- recommending next actions
- weekly review
- progress analysis

But AI must not be required for the basic productivity system.

---

# FUTURE PRODUCT ROADMAP

Phase 1:
Goals
Projects
Tasks

Phase 2:
Weekly planning
Daily planning
Capacity
Priority
Next Action
Daily Top 3

Phase 3:
Focus mode
Timer
Distraction capture
Focus sessions

Phase 4:
Goal progress
Planned vs actual
Focus hours
Weekly review

Phase 5:
AI task breakdown
AI planning
AI next-action recommendation
AI weekly review
AI progress analysis

Phase 6:
AI engineering experiments

- single agent
- planner + developer
- planner + developer + reviewer
- multi-agent workflow
- measure quality/rework/human review effort

---

# SDD EXPERIMENT

Current experiment:

EXP-001 — Specification Before Implementation

Hypothesis:

Writing and approving a specification before implementation will reduce
AI implementation rework and make changes easier for humans to review.

Metrics we eventually want to measure:

- implementation iterations
- development time
- files changed
- bugs found during review
- specification changes after implementation begins
- human review time
- acceptance criteria pass rate
- unrelated AI changes

Do not fabricate experiment results.

---

# YOUR CURRENT TASK

You are operating in PLAN MODE.

Do NOT write application code yet.

Start by:

1. Inspecting the repository.
2. Reading AGENTS.md.
3. Reading product vision/principles.
4. Reading the Daily Top 3 specification.
5. Checking its current status.
6. Checking whether the final product decisions are represented.
7. If the spec is still Draft but all decisions are resolved, update only
   the specification status to Proposed.
8. Then analyze the architecture required to implement Daily Top 3.
9. Identify dependencies that need specifications first.
10. Produce a detailed implementation plan.

- [ ] Do not implement the plan until explicitly approved.
