#!/usr/bin/env bash
#
# Run the k6 API performance test with prerequisite checks.
#
# Usage:
#   ./scripts/perf/run.sh                              # local defaults (20 VUs)
#   ./scripts/perf/run.sh -e PEAK_VUS=100              # heavier run
#   BASE_URL=https://<host> CREDS_FILE=./creds.csv \
#     CONFIRM_PROD=1 ./scripts/perf/run.sh -e PEAK_VUS=100 -e HOLD=3m
#
# All arguments are forwarded to `k6 run`, so any -e KEY=VALUE or k6 flag works.
#
# Options (env vars): BASE_URL, CREDS_FILE, PEAK_VUS, HOLD, RAMP_UP, RAMP_DOWN,
# NUM_USERS, TOKEN_TTL_SECONDS, THINK_TIME, DATE, RUN_ID, TEST_PASSWORD.
#
# SAFETY: against a non-local BASE_URL the script requires CONFIRM_PROD=1 and,
# unless ALLOW_REGISTER=true, a CREDS_FILE so no accounts are created on the
# target environment.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/perf/api-load-test.js"

export BASE_URL="${BASE_URL:-http://localhost:8080}"
[ -n "${CREDS_FILE:-}" ] && export CREDS_FILE
[ -n "${ALLOW_REGISTER:-}" ] && export ALLOW_REGISTER

if ! command -v k6 >/dev/null 2>&1; then
  echo "k6 is not installed." >&2
  echo "Install it with:  brew install k6" >&2
  echo "Or see:           https://grafana.com/docs/k6/latest/set-up/install-k6/" >&2
  exit 1
fi

IS_LOCAL=0
if printf '%s' "$BASE_URL" | grep -qE '^https?://(localhost|127\.0\.0\.1|\[::1\])(:[0-9]+)?$'; then
  IS_LOCAL=1
fi

if [ "$IS_LOCAL" -eq 0 ]; then
  echo "WARNING: targeting a NON-LOCAL API: $BASE_URL" >&2
  if [ "${CONFIRM_PROD:-0}" != "1" ]; then
    echo "Refusing to run. Re-run with CONFIRM_PROD=1 to confirm." >&2
    exit 1
  fi
  if [ -z "${CREDS_FILE:-}" ] && [ "${ALLOW_REGISTER:-}" != "true" ]; then
    echo "Set CREDS_FILE=/abs/path/creds.csv so the test does not create accounts" >&2
    echo "on the target, or ALLOW_REGISTER=true to allow it explicitly." >&2
    exit 1
  fi
fi

if ! curl -fsS -o /dev/null --max-time 15 "${BASE_URL}/api/v1/health"; then
  echo "API not reachable at ${BASE_URL}/api/v1/health" >&2
  exit 1
fi

echo "Running k6 load test against ${BASE_URL}"
exec k6 run "$@" "$SCRIPT"
