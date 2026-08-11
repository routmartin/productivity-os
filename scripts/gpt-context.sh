#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
OUTPUT_FILE="$REPO_ROOT/gpt/context-$(date -u +"%Y%m%d-%H%M%S").md"
LATEST_FILE="$REPO_ROOT/gpt/current.md"

{
  echo "# Productivity OS — Context Snapshot"
  echo ""
  echo "**Generated:** $TIMESTAMP"
  echo "**Repository:** $REPO_ROOT"
  echo ""

  for module in user task goal project topthree; do
    echo "### Source ($module module)"
    echo ""
    find "apps/api/src/main/kotlin/com/productivityos/$module" -name "*.kt" 2>/dev/null | sort | while read f; do
      echo "- \`$f\`"
    done
    echo ""
  done

  echo "### Source (api/other)"
  echo ""
  find apps/api/src/main/kotlin/com/productivityos -maxdepth 1 -name "*.kt" 2>/dev/null | sort | while read f; do
    echo "- \`$f\`"
  done
  echo ""
  find apps/api/src/main/kotlin/com/productivityos/api -name "*.kt" 2>/dev/null | sort | while read f; do
    echo "- \`$f\`"
  done

  echo ""
  echo "### Migrations"
  echo ""
  find apps/api/src/main/resources/db/migration -name "*.sql" | sort | while read f; do
    echo "- \`$f\`"
  done

  echo ""
  echo "### Config"
  echo ""
  echo "- \`apps/api/build.gradle.kts\`"
  echo "- \`apps/api/src/main/resources/application.yml\`"
  echo "- \`docker-compose.yml\`"
  echo "- \`settings.gradle.kts\`"
  echo "- \`build.gradle.kts\`"

  echo ""
  echo "### Agent infrastructure"
  echo ""
  echo "- \`.cline/rules/reviewer.md\`"
  echo "- \`.opencode/commands/review.md\`"
  echo "- \`scripts/agent-review.sh\`"

  echo ""
  echo "## Database Tables"
  echo ""
  echo "| Migration | Tables |"
  echo "|-----------|--------|"
  echo "| V1__baseline.sql | pgcrypto extension |"
  echo "| V2__users.sql | users, refresh_tokens |"
  echo "| V3__tasks.sql | tasks |"
  echo "| V4__task_cancelled.sql | (CHECK constraint update) |"
  echo "| V5__daily_top_three.sql | daily_top_three |"
  echo "| V6__projects.sql | projects, tasks.project_id |"
  echo "| V7__task_attributes.sql | tasks.priority, energy, estimated_duration_minutes |"
  echo "| V8__goals.sql | goals, projects FK |"

  echo ""
  echo "## API Endpoints"
  echo ""
  echo "### Public"
  echo ""
  echo "| Method | Path | Response |"
  echo "|--------|------|----------|"
  echo "| POST | /api/v1/auth/register | 201 { id, email, timezone } |"
  echo "| POST | /api/v1/auth/login | 200 { accessToken, user } |"
  echo "| POST | /api/v1/auth/refresh | 200 { accessToken } |"
  echo "| POST | /api/v1/auth/logout | 204 |"
  echo "| GET | /api/v1/health | 200 { status } |"

  echo ""
  echo "### Tasks (Authorization: Bearer \<jwt\>)"
  echo ""
  echo "| Method | Path | Purpose |"
  echo "|--------|------|---------|"
  echo "| POST | /api/v1/tasks | Create task |"
  echo "| GET | /api/v1/tasks?page=&size= | List active tasks |"
  echo "| POST | /api/v1/tasks/{id}/plan | Inbox→Planned |"
  echo "| POST | /api/v1/tasks/{id}/start | Planned→InProgress |"
  echo "| POST | /api/v1/tasks/{id}/completion | InProgress→Completed |"
  echo "| POST | /api/v1/tasks/{id}/cancellation | →Cancelled |"
  echo "| POST | /api/v1/tasks/{id}/reopening | Cancelled→Planned |"
  echo "| DELETE | /api/v1/tasks/{id} | Soft delete |"
  echo "| POST | /api/v1/tasks/{id}/restoration | Restore |"
  echo "| PUT | /api/v1/tasks/{id}/project | Assign to project |"

  echo ""
  echo "### Daily Top 3"
  echo ""
  echo "| Method | Path | Purpose |"
  echo "|--------|------|---------|"
  echo "| GET | /api/v1/daily-top-three/{date} | View Top 3 |"
  echo "| POST | /api/v1/daily-top-three/{date} | Select task |"
  echo "| PUT | /api/v1/daily-top-three/{date}/{id}/position | Reorder |"
  echo "| DELETE | /api/v1/daily-top-three/{date}/{id} | Remove |"

  echo ""
  echo "### Projects"
  echo ""
  echo "| Method | Path | Purpose |"
  echo "|--------|------|---------|"
  echo "| POST | /api/v1/projects | Create (Draft) |"
  echo "| GET | /api/v1/projects | List all |"
  echo "| GET | /api/v1/projects/{id} | Get by ID |"
  echo "| POST | /api/v1/projects/{id}/activation | Draft→Active |"
  echo "| POST | /api/v1/projects/{id}/completion | Active→Completed |"
  echo "| POST | /api/v1/projects/{id}/archival | Completed→Archived |"

  echo ""
  echo "### Goals"
  echo ""
  echo "| Method | Path | Purpose |"
  echo "|--------|------|---------|"
  echo "| POST | /api/v1/goals | Create (Draft) |"
  echo "| GET | /api/v1/goals | List all |"
  echo "| GET | /api/v1/goals/{id} | Get by ID |"
  echo "| POST | /api/v1/goals/{id}/activation | Draft→Active |"
  echo "| POST | /api/v1/goals/{id}/completion | Active→Completed |"
  echo "| POST | /api/v1/goals/{id}/reopening | Completed→Active |"
  echo "| POST | /api/v1/goals/{id}/archival | Completed→Archived |"

  echo ""
  echo "## Error Handling"
  echo ""
  echo "| Exception | HTTP | Code |"
  echo "|-----------|------|------|"
  echo "| AuthenticationException | 401 | invalid_credentials |"
  echo "| InvalidRefreshTokenException | 401 | invalid_token |"
  echo "| DuplicateEmailException | 409 | EMAIL_TAKEN |"
  echo "| DataIntegrityViolationException | 409 | EMAIL_TAKEN |"
  echo "| DateTimeException | 400 | INVALID_TIMEZONE |"
  echo "| MethodArgumentNotValidException | 400 | VALIDATION_ERROR |"
  echo "| TaskNotFoundException | 404 | NOT_FOUND |"
  echo "| IllegalArgumentException | 409 | CONFLICT |"
  echo "| Exception (fallback) | 500 | INTERNAL_ERROR |"

  echo ""
  echo "## Build"
  echo ""

  if ./gradlew --no-daemon --no-build-cache :apps:api:compileKotlin :apps:api:compileTestKotlin -q 2>&1; then
    echo "**BUILD: PASS**"
  else
    echo "**BUILD: FAIL**"
  fi

  echo ""
  echo "## Local Run"
  echo ""
  echo '```bash'
  echo "docker compose up -d"
  echo "./gradlew :apps:api:bootRun"
  echo '```'

} > "$OUTPUT_FILE"

cp "$OUTPUT_FILE" "$LATEST_FILE"

echo "[gpt] Context snapshot written to:"
echo "       $OUTPUT_FILE"
echo "       $LATEST_FILE (latest)"
