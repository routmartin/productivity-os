# Productivity OS — Context Snapshot

**Generated:** 2026-08-11T10:21:06Z
**Repository:** /Users/metamartin/Desktop/productivity-os

## Files

### Source (user module)

- `apps/api/src/main/kotlin/com/productivityos/user/AuthController.kt`
- `apps/api/src/main/kotlin/com/productivityos/user/AuthExceptionHandler.kt`
- `apps/api/src/main/kotlin/com/productivityos/user/ClockConfig.kt`
- `apps/api/src/main/kotlin/com/productivityos/user/CurrentUser.kt`
- `apps/api/src/main/kotlin/com/productivityos/user/DuplicateEmailException.kt`
- `apps/api/src/main/kotlin/com/productivityos/user/JwtAuthenticationFilter.kt`
- `apps/api/src/main/kotlin/com/productivityos/user/LoginRequest.kt`
- `apps/api/src/main/kotlin/com/productivityos/user/LoginResponse.kt`
- `apps/api/src/main/kotlin/com/productivityos/user/LoginService.kt`
- `apps/api/src/main/kotlin/com/productivityos/user/PasswordEncoderConfig.kt`
- `apps/api/src/main/kotlin/com/productivityos/user/RefreshToken.kt`
- `apps/api/src/main/kotlin/com/productivityos/user/RefreshTokenRepository.kt`
- `apps/api/src/main/kotlin/com/productivityos/user/RefreshTokenService.kt`
- `apps/api/src/main/kotlin/com/productivityos/user/RegisterRequest.kt`
- `apps/api/src/main/kotlin/com/productivityos/user/RegistrationService.kt`
- `apps/api/src/main/kotlin/com/productivityos/user/SecurityConfig.kt`
- `apps/api/src/main/kotlin/com/productivityos/user/TokenService.kt`
- `apps/api/src/main/kotlin/com/productivityos/user/User.kt`
- `apps/api/src/main/kotlin/com/productivityos/user/UserRepository.kt`
- `apps/api/src/main/kotlin/com/productivityos/user/UserResponse.kt`

### Source (task module)

- `apps/api/src/main/kotlin/com/productivityos/task/CompleteTaskService.kt`
- `apps/api/src/main/kotlin/com/productivityos/task/CreateTaskRequest.kt`
- `apps/api/src/main/kotlin/com/productivityos/task/CreateTaskService.kt`
- `apps/api/src/main/kotlin/com/productivityos/task/DeleteTaskService.kt`
- `apps/api/src/main/kotlin/com/productivityos/task/ListTasksService.kt`
- `apps/api/src/main/kotlin/com/productivityos/task/RestoreTaskService.kt`
- `apps/api/src/main/kotlin/com/productivityos/task/Task.kt`
- `apps/api/src/main/kotlin/com/productivityos/task/TaskController.kt`
- `apps/api/src/main/kotlin/com/productivityos/task/TaskEntity.kt`
- `apps/api/src/main/kotlin/com/productivityos/task/TaskRepository.kt`
- `apps/api/src/main/kotlin/com/productivityos/task/TaskResponse.kt`
- `apps/api/src/main/kotlin/com/productivityos/task/TaskStatus.kt`
- `apps/api/src/main/kotlin/com/productivityos/task/TransitionTaskService.kt`

### Source (other)

- `apps/api/src/main/kotlin/com/productivityos/ProductivityOsApplication.kt`

- `apps/api/src/main/kotlin/com/productivityos/api/HealthController.kt`

### Migrations

- `apps/api/src/main/resources/db/migration/V1__baseline.sql`
- `apps/api/src/main/resources/db/migration/V2__users.sql`
- `apps/api/src/main/resources/db/migration/V3__tasks.sql`

### Config

- `apps/api/build.gradle.kts`
- `apps/api/src/main/resources/application.yml`
- `docker-compose.yml`
- `settings.gradle.kts`
- `build.gradle.kts`

### Agent infrastructure

- `.cline/rules/reviewer.md`
- `.opencode/commands/review.md`
- `scripts/agent-review.sh`

## Database Tables

| Migration | Tables |
|-----------|--------|
| V1__baseline.sql | pgcrypto extension |
| V2__users.sql | users, refresh_tokens |
| V3__tasks.sql | tasks |

## API Endpoints

### Public

| Method | Path | Response |
|--------|------|----------|
| POST | /api/v1/auth/register | 201 { id, email, timezone } |
| POST | /api/v1/auth/login | 200 { accessToken, user } + Set-Cookie: refresh_token |
| POST | /api/v1/auth/refresh | 200 { accessToken } + Set-Cookie: refresh_token |
| POST | /api/v1/auth/logout | 204 + Set-Cookie: refresh_token= (cleared) |
| GET | /api/v1/health | 200 { status: "ok" } |

### Protected (Authorization: Bearer \<jwt\>)

| Method | Path | Response |
|--------|------|----------|
| POST | /api/v1/tasks | 201 { id, ownerId, title, status: "INBOX", ... } |
| GET | /api/v1/tasks?page=&size= | 200 [ { ... } ] |
| POST | /api/v1/tasks/{id}/plan | 200 { ... status: "PLANNED" } |
| POST | /api/v1/tasks/{id}/start | 200 { ... status: "IN_PROGRESS" } |
| POST | /api/v1/tasks/{id}/completion | 200 { ... status: "COMPLETED", completedAt } |
| DELETE | /api/v1/tasks/{id} | 204 |
| POST | /api/v1/tasks/{id}/restoration | 200 { ... deletedAt: null } |

## Error Handling

| Exception | HTTP | Code |
|-----------|------|------|
| AuthenticationException | 401 | invalid_credentials |
| InvalidRefreshTokenException | 401 | invalid_token |
| DuplicateEmailException | 409 | EMAIL_TAKEN |
| DataIntegrityViolationException | 409 | EMAIL_TAKEN |
| DateTimeException | 400 | INVALID_TIMEZONE |
| MethodArgumentNotValidException | 400 | VALIDATION_ERROR (per-field) |
| TaskNotFoundException | 404 | NOT_FOUND |
| IllegalArgumentException | 409 | CONFLICT |

## Build

**BUILD: PASS** — compileKotlin + compileTestKotlin

## Local Run

```bash
docker compose up -d
./gradlew :apps:api:bootRun
```
