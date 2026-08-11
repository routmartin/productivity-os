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

  echo "## Files"
  echo ""
  echo "### Source (user module)"
  echo ""
  find apps/api/src/main/kotlin/com/productivityos/user -name "*.kt" | sort | while read f; do
    echo "- \`$f\`"
  done
  echo ""
  echo "### Source (task module)"
  echo ""
  find apps/api/src/main/kotlin/com/productivityos/task -name "*.kt" | sort | while read f; do
    echo "- \`$f\`"
  done
  echo ""
  echo "### Source (other)"
  echo ""
  find apps/api/src/main/kotlin/com/productivityos -maxdepth 1 -name "*.kt" | sort | while read f; do
    echo "- \`$f\`"
  done
  echo ""
  find apps/api/src/main/kotlin/com/productivityos/api -name "*.kt" | sort | while read f; do
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

  echo ""
  echo "## API Endpoints"
  echo ""
  echo "### Public"
  echo ""
  echo "| Method | Path | Response |"
  echo "|--------|------|----------|"
  echo "| POST | /api/v1/auth/register | 201 { id, email, timezone } |"
  echo "| POST | /api/v1/auth/login | 200 { accessToken, user } + Set-Cookie: refresh_token |"
  echo "| POST | /api/v1/auth/refresh | 200 { accessToken } + Set-Cookie: refresh_token |"
  echo "| POST | /api/v1/auth/logout | 204 + Set-Cookie: refresh_token= (cleared) |"
  echo "| GET | /api/v1/health | 200 { status: \"ok\" } |"
  echo ""
  echo "### Protected (Authorization: Bearer \<jwt\>)"
  echo ""
  echo "| Method | Path | Response |"
  echo "|--------|------|----------|"
  echo "| POST | /api/v1/tasks | 201 { id, ownerId, title, status: \"INBOX\", ... } |"
  echo "| GET | /api/v1/tasks?page=&size= | 200 [ { ... } ] |"
  echo "| POST | /api/v1/tasks/{id}/plan | 200 { ... status: \"PLANNED\" } |"
  echo "| POST | /api/v1/tasks/{id}/start | 200 { ... status: \"IN_PROGRESS\" } |"
  echo "| POST | /api/v1/tasks/{id}/completion | 200 { ... status: \"COMPLETED\", completedAt } |"
  echo "| DELETE | /api/v1/tasks/{id} | 204 |"
  echo "| POST | /api/v1/tasks/{id}/restoration | 200 { ... deletedAt: null } |"

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
  echo "| MethodArgumentNotValidException | 400 | VALIDATION_ERROR (per-field) |"
  echo "| TaskNotFoundException | 404 | NOT_FOUND |"
  echo "| IllegalArgumentException | 409 | CONFLICT |"

  echo ""
  echo "## Build"
  echo ""

  if ./gradlew --no-daemon --no-build-cache compileKotlin compileTestKotlin -q 2>&1; then
    echo "**BUILD: PASS** — compileKotlin + compileTestKotlin"
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
