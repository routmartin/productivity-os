---
description: "Sync specifications with the current implementation: detect AC drift (vibe-coded or manual changes), draft spec amendments, update the plan's AC status table, and get human approval before changing any spec. Use when implementation has diverged from docs/specs/ or acceptance criteria changed mid-development."
---

# Spec Sync — keep docs/specs and implementation in sync

Drift happens: a human vibe-codes a UI, an AC turns out to be impractical, a
design changes mid-build. The spec is the source of truth for behavior, but
it must stay truthful. This workflow classifies every mismatch and routes it
to the right fix — never silently. Per AGENTS.md, specs change only with
human approval.

## 1. Scope

$ARGUMENTS may name a spec path (e.g. `docs/specs/ui/goals-ui.md`) or a
domain. Default: every spec governing code that changed in the working tree.

## 2. Drift check (per AC)

For each acceptance criterion of each governing spec, determine its status
against the current implementation:

| Status | Meaning |
|--------|---------|
| PASS | implemented and verified (code + tests or manual evidence) |
| FAIL | implementation exists but behavior differs from the AC |
| NOT VERIFIED | no evidence yet — do not guess |
| UNREACHABLE | AC impossible/unverifiable as written (broken test, missing backend) |

Evidence sources: `git diff`, component/store code, tests, manual checks,
`docs/reviews/current-review.md` findings.

## 3. Classify each FAIL/UNREACHABLE

For every mismatch, decide which bucket it is:

- **Defect** — the code does not meet the (still valid) spec. Fix the code.
  Do NOT touch the spec. If out of scope for the current change, report it.
- **Intended change** — the human (or human-driven vibe-coding) deliberately
  changed the behavior, or the AC is no longer realistic. The spec must be
  amended — but only after human approval. Do NOT revert working code to
  satisfy a stale AC.
- **Ambiguous** — cannot tell which. STOP and ask the human. Never pick a
  side silently.

## 4. Draft the amendment (do not apply yet)

When you find intended changes, draft:

1. **AC edits** — keep AC IDs stable (renumbering breaks traceability).
   Changed ACs keep their number and get a marker, e.g.
   `### AC-003 — Goal card shows archive status *(amended)*` with the new
   Given/When/Then text.
2. **Behavior / Rules / Constraints edits** — only the sections the change
   touches; do not rewrite the spec wholesale.
3. **Change History entry** — one bullet, e.g.:

   `- Amended per human-driven UI rework: AC-003 now requires an explicit
     archive button (was: auto-archive on completion); Behavior §8 updated.
     All other ACs unchanged.`

4. **Plan update** — in the governing plan's traceability matrix (or its
   AC table), set each AC's status column: `PASS`, `FAIL`, `NOT VERIFIED`,
   or `AMENDED` (with the amendment reference). Add the new date.

## 5. Human approval gate

Present: the status table, the proposed AC diffs, and the Change History
entry. Then STOP.

- Approved → apply the amendment to the spec, move the spec status along the
  lifecycle if justified (Implementing → **Verified** only when every AC is
  PASS; superseded specs → **Deprecated**).
- Rejected / different intent → do exactly what the human says; discard the
  draft otherwise.

## 6. Never

- Change specs/ADRs to make a review pass or to silence the reviewer.
- Self-approve a spec amendment (human owns product decisions).
- Renumber ACs. 
- Mark FAIL or NOT VERIFIED as PASS to make the table look complete.
- Edit the spec to match code that is actually a defect.

## Related

- `write-system-spec` skill — templates, ADR reference, endpoint verification
- `/review` — independent review; its findings are drift evidence
- `docs/specs/README.md` — lifecycle (Draft → Proposed → Approved → Implementing → Verified → Deprecated)