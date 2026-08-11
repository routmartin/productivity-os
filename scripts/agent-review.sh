#!/usr/bin/env bash
set -euo pipefail

readonly EXIT_PASS=0
readonly EXIT_CHANGES_REQUIRED=10
readonly EXIT_BLOCKED=20
readonly EXIT_EXECUTION_FAILED=30

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

REVIEW_FILE="$REPO_ROOT/docs/reviews/current-review.md"
RULES_FILE="$REPO_ROOT/.cline/rules/reviewer.md"

if [[ ! -f "$RULES_FILE" ]]; then
  echo "[agent-review] ERROR: Reviewer rules not found at $RULES_FILE" >&2
  exit $EXIT_EXECUTION_FAILED
fi

SYSTEM_PROMPT="$(cat "$RULES_FILE")"

REVIEW_PROMPT='Review the current git working tree changes in this repository.

Steps:
1. Run `git diff` to see all changes.
2. Read `AGENTS.md` for project principles and source-of-truth priority.
3. Read relevant architecture documents under `docs/architecture/`.
4. Read relevant specifications under `docs/specs/` matching the changed code.
5. Read relevant ADRs under `docs/decisions/`.
6. Read the current implementation plan under `docs/plans/`.
7. Inspect all modified source files thoroughly.
8. Produce your review using the format defined in your system rules.
9. Output the complete review as your final response — do NOT write it to a file.
   Output the review directly to stdout.'

echo "[agent-review] Starting Cline review..."
echo "[agent-review] Repository: $REPO_ROOT"
echo ""

if ! command -v cline &>/dev/null; then
  echo "[agent-review] ERROR: cline CLI not found in PATH" >&2
  exit $EXIT_EXECUTION_FAILED
fi

CLINE_OUTPUT_FILE="$(mktemp)"

set +e
cline \
  -c "$REPO_ROOT" \
  -p \
  -t 600 \
  -s "$SYSTEM_PROMPT" \
  "$REVIEW_PROMPT" >"$CLINE_OUTPUT_FILE" 2>&1
CLINE_EXIT=$?
set -e

CLINE_OUTPUT="$(cat "$CLINE_OUTPUT_FILE")"
rm -f "$CLINE_OUTPUT_FILE"

echo "$CLINE_OUTPUT" > "$REVIEW_FILE"
echo "[agent-review] Review saved to $REVIEW_FILE"

if [[ $CLINE_EXIT -ne 0 ]]; then
  echo "[agent-review] REVIEW_EXECUTION_FAILED: Cline CLI exited with code $CLINE_EXIT" >&2
  exit $EXIT_EXECUTION_FAILED
fi

VERDICT=$(echo "$CLINE_OUTPUT" | sed -n '/^## Verdict/,/^## /p' | grep -oE 'PASS|CHANGES_REQUIRED|BLOCKED' | head -1)

case "$VERDICT" in
  PASS)
    echo "[agent-review] Verdict: PASS"
    exit $EXIT_PASS
    ;;
  CHANGES_REQUIRED)
    echo "[agent-review] Verdict: CHANGES_REQUIRED"
    exit $EXIT_CHANGES_REQUIRED
    ;;
  BLOCKED)
    echo "[agent-review] Verdict: BLOCKED"
    exit $EXIT_BLOCKED
    ;;
  *)
    echo "[agent-review] REVIEW_EXECUTION_FAILED: could not extract valid verdict" >&2
    exit $EXIT_EXECUTION_FAILED
    ;;
esac
