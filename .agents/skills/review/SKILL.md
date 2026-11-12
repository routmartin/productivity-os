---
name: review
description: "Run independent code review on the current git diff against specs, ADRs, architecture docs, and AGENTS.md. Uses scripts/agent-review.sh or the code-reviewer subagent."
---

# Code Review Workflow

Execute an independent review of the working tree changes before completing any milestone or submitting for testing.

## Review Steps

1. **Self-Inspection**: Run `git diff` or `git status` to verify changed files and eliminate extraneous edits.
2. **Review Execution**:
   - Primary: Run `scripts/agent-review.sh` to execute the headless reviewer.
   - Antigravity Native: If `scripts/agent-review.sh` is unavailable or `cline` CLI is missing, invoke the `code-reviewer` subagent:
     ```
     invoke_subagent(
       TypeName: "code-reviewer",
       Role: "Independent Code Reviewer",
       Prompt: "Review the current git working tree changes in this repository against AGENTS.md, docs/specs/, docs/plans/, and ADRs."
     )
     ```
3. **Inspect Output**: Read `docs/reviews/current-review.md` (or the `code-reviewer` report).
4. **Evaluate Verdict**:
   - **PASS**: Report success. Review passed with no blocking issues.
   - **CHANGES_REQUIRED**: Review Critical and High issues. Fix valid issues and re-run review (maximum 2 fix cycles).
   - **BLOCKED**: Stop immediately. Escalate product or architecture decision to the human. Never invent a resolution.

## Constraints
- Reviewers are read-only; they do not modify application code.
- Never edit specs or ADRs simply to make a review pass.
