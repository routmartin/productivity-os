---
name: write-system-spec
description: Write or update Productivity OS specifications and implementation plans following the SDD workflow. Use when the user asks to "write a spec", "create a plan", "finalize spec/plan docs", "write docs and spec", or mentions acceptance criteria, change history, or spec status (Draft/Proposed/Approved). Encodes the repo's spec template, plan template, ADR references, and the rule that endpoint contracts must be verified against the backend before being written.
---

# Write System Spec / Plan (SDD Workflow)

For the Productivity OS repository. Specifications are the source of truth for
product behavior; plans describe how an approved spec will be implemented.
Specification always comes before implementation (ADR-001).

Specs are living documents: implementation (including human vibe-coding)
drifts from them, and the sync workflow below keeps them truthful.

## Before Writing Anything

1. Read `AGENTS.md` at the repo root — it defines the source-of-truth
   priority and the agent workflow. Follow it.
2. Read the templates:
   - `docs/specs/README.md` — spec lifecycle + template
   - `docs/plans/README.md` — plan template
3. Read the existing spec(s) for the domain you are touching (see Location
   Conventions below) so the new document extends rather than duplicates.
4. Check `git status`/`git log` for in-progress work — a spec or plan may
   already exist as an untracked file.
5. For plans: read the governing spec fully and list which acceptance
   criteria are in scope.

## Spec Lifecycle

```text
Draft -> Proposed -> Approved -> Implementing -> Verified -> Deprecated
```

- New specs are **Draft** (`## Status` + `Draft`, or `**Status:** Draft` —
  match the style of the domain's existing specs).
- Moving a spec to **Proposed/Approved** is a human decision. Mark it, then
  ask the human to confirm. Never self-approve a spec.
- Plans are gated on an Approved spec. A plan for a Draft spec stays Draft
  and must list the approval as its first pre-implementation decision.

## Spec Structure (exact headings)

```markdown
# Feature Name

## Status
Draft

## Problem

## Goal

## User Story

As a user, I want ..., so that ...

## Behavior

## Rules

Numbered rules, one invariant or contract per rule. Reference ADRs where
relevant.

## Constraints

## Acceptance Criteria

### AC-001 — Short name

Given ...
When ...
Then ...

(AC-002, AC-003, ... — every behavior must be testable)

## Edge Cases

## Out of Scope

## Dependencies

## Open Questions

## Change History

- Initial Draft created for ...
- <later entries describing what changed and why>
```

## Plan Structure (exact headings)

```markdown
# Plan: Feature Name

## Status
Draft / Approved for implementation

## Specification

Primary behavioral source of truth:
- docs/specs/... (Status)

Acceptance criteria in scope:
- AC-001 ...

Supporting decisions and constraints:
- ADR-...

## Architecture

## Step N — Title

**Status:** pending / IMPLEMENTED (add when the code exists)

- **Files/modules:** ...
- **Spec/AC:** ...
- **Behavior:** ...
- **Dependencies:** ...
- **Tests:** ...
- **Risks/ambiguities:** ...

## Tests

Traceability matrix: AC-001 -> Step N ...

## Verification

Per AGENTS.md: run lint/typecheck/tests, diff review, completion report.

## Pre-Implementation Decisions (must be resolved first)

- **D1:** ... (mark resolved/confirmed/open — never silently resolve a
  product decision; flag OPEN and ask the human)

## Out of Scope for This Plan

## Change History
```

## Endpoint Contract Rule (critical)

**Never invent endpoints, DTOs, or error codes.** Before writing any endpoint
table, verify it against the backend:

- Controllers: `apps/api/src/main/kotlin/com/productivityos/<module>/*Controller.kt`
  — grep for `@RequestMapping` / `@GetMapping` / `@PostMapping` / `@PutMapping` /
  `@DeleteMapping` to get the exact paths, HTTP methods, and response types
  (note plain-array vs `Page<T>` responses — V1 list endpoints return arrays).
- DTOs: read the `*Request.kt` / `*Response.kt` files for exact field names,
  validation constraints (`@Size`, `@NotBlank`), and nullability.
- Error codes: read `apps/api/src/main/kotlin/com/productivityos/api/GlobalExceptionHandler.kt`
  for the `code` values (`invalid_credentials`, `INVALID_TIMEZONE`,
  `VALIDATION_ERROR`, `NOT_FOUND`, `CONFLICT`, `INTERNAL_ERROR`, ...).
- Auth/session behavior: `AuthController` (register/login/refresh/logout),
  `UserController` (password/timezone), ADR-004 (refresh cookie, revocation).

If the UI needs something the backend does not expose, record the gap in the
spec (Open Questions or Constraints) — do not patch it client-side and do not
propose backend changes without human approval.

## ADR Quick Reference

| ADR | Topic | Use when |
|-----|-------|----------|
| ADR-001 | SDD workflow | gating implementation on approved specs |
| ADR-002 | Technology stack | stack constraints (Spring Boot, Vue 3, PostgreSQL) |
| ADR-003 | Database persistence | timestamps, transactions, user-scoped FKs |
| ADR-004 | Auth + user isolation | tokens, refresh cookie, password-change revocation, "never send a userId" |
| ADR-005 | API architecture | URL conventions, structured error model, pagination |
| ADR-006 | Time and timezone | IANA timezones, "today", prospective-only changes, ISO-8601 |

## Location Conventions

- Specs: `docs/specs/<domain>/<name>.md` where `<domain>` is one of
  `users`, `tasks`, `projects`, `goals`, `planning`, `focus`, `ai`, `ui`,
  or a new domain folder. Example: `docs/specs/users/account-settings.md`.
- Plans: `docs/plans/NNN-<slug>.md` — next number after the highest existing
  plan (currently 001, 002 -> new plans start at 003).
- ADRs: `docs/decisions/ADR-NNN-<slug>.md` — only for significant technical
  decisions; propose, do not silently add.

## Keeping Specs in Sync with Implementation (amendments)

Specs change along the way — UI design evolves, a human vibe-codes behavior,
an AC proves impractical. The sync procedure:

1. **Drift check per AC** — classify every AC against the implementation:
   `PASS` (verified), `FAIL` (behavior differs), `NOT VERIFIED` (no
   evidence), `UNREACHABLE` (impossible as written). Never guess.
2. **Classify each mismatch** — defect (fix the code, never the spec) vs
   intended change (the spec gets amended, never the working code reverted)
   vs ambiguous (STOP, ask the human — never pick a side silently).
3. **Draft the amendment** — keep AC IDs stable; mark changed ACs with
   `*(amended)*`; touch only the sections that changed; add one Change
   History bullet naming the ACs and the reason (e.g. "Amended per
   human-driven UI rework: AC-003 ..."); update the plan's traceability
   matrix with the AC status column (`PASS` / `FAIL` / `NOT VERIFIED` /
   `AMENDED`).
4. **Human approval gate** — present the status table + AC diffs, then
   STOP. Only after approval: apply the amendment and move the spec status
   (Implementing → **Verified** when every AC passes; superseded →
   **Deprecated**).
5. **Never** — change specs to make a review pass; self-approve amendments;
   renumber ACs; mark FAIL/NOT VERIFIED as PASS; amend the spec for what is
   actually a defect.

The `/spec-sync` command drives this workflow end-to-end. Review findings
(`docs/reviews/current-review.md`) are drift evidence — resolve them through
this procedure, not by editing the spec to silence the reviewer.

## Rules of Engagement

- Do not modify code while writing docs (analysis/planning phase).
- Do not add unrelated improvements; keep changes small and reviewable.
- If the source-of-truth chain conflicts, stop and report the conflict.
- Flag open decisions as **D-numbered items** or spec Open Questions; the
  human resolves them. Never silently choose a product interpretation.
- When asked to "finalize" docs: verify the docs against the actual code
  (endpoints, implemented steps, deviations), mark implemented steps
  `**Status: IMPLEMENTED**` in plans, record deviations in the step or
  Change History, resolve what the code proves, and keep human decisions
  open with a clear ask.
- Matching spec style: some specs use `## Status` + bare word, others
  `**Status:** Draft`. Match the style of neighboring specs in the same
  domain folder.