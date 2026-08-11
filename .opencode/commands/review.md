# /review

Invoke the Cline CLI code reviewer against the current implementation.

## Steps

1. Run `scripts/agent-review.sh` to start the automated review.
   - The script invokes Cline CLI in headless (--plan) mode.
   - Cline inspects the diff, reads source-of-truth docs, and writes the review to
     `docs/reviews/current-review.md`.
   - Exit codes:
     - 0 = PASS
     - 10 = CHANGES_REQUIRED
     - 20 = BLOCKED
     - 30 = REVIEW_EXECUTION_FAILED
2. Read `docs/reviews/current-review.md`.
3. Summarize the review findings for the human.

## If exit code 0 (PASS)

Report: "Review passed. No blocking issues found."

List any Low issues for awareness.

## If exit code 10 (CHANGES_REQUIRED)

Report the Critical and High issues.
Explain what each fix requires.
Offer to fix them (ask first — do not auto-fix).

## If exit code 20 (BLOCKED)

Stop immediately.
Surface the product/architecture decision to the human.
Do not attempt to resolve or work around it.
The human must make the decision before implementation proceeds.

## If exit code 30 (REVIEW_EXECUTION_FAILED)

Report the failure — Cline CLI may have crashed, timed out, or produced unparseable output.
Do NOT fall back to an OpenCode subagent as a replacement.

## Constraints

- Always run `scripts/agent-review.sh` — do NOT use an OpenCode Cline subagent as a
  replacement for the Cline CLI.
- Do not modify code automatically during the review workflow.
- Do not change specifications, ADRs, or architecture docs to make the review pass.
- After fixing issues, run the review again (max 2 cycles before escalating to human).
