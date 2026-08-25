.PHONY: dev run db-up db-down build test clean docs web web-mock web-install preview kill

web-install:
	cd apps/web && pnpm install

# Full mock preview: every feature serves mock data, no backend needed.
web-mock:
	cd apps/web && VITE_USE_MOCK_DATA=true pnpm dev

# Design review without the backend: mock auth only.
web:
	cd apps/web && VITE_USE_MOCK_AUTH=true pnpm dev

# End-to-end run against the real backend: DB + API + web with real auth
# (every feature defaults to the real API — no env vars needed).
preview: db-up
	./gradlew :apps:api:bootRun &
	sleep 8
	cd apps/web && pnpm dev

dev: db-up
	./gradlew :apps:api:bootRun &
	sleep 8
	open http://localhost:8080/docs
	wait

run: db-up
	( sleep 8 && open http://localhost:8080/docs ) &
	./gradlew :apps:api:bootRun

db-up:
	docker compose up -d

db-down:
	docker compose down

kill:
	-lsof -ti :8080 | xargs kill
	-lsof -ti :8081 | xargs kill
	-lsof -ti :5173 | xargs kill

build:
	./gradlew :apps:api:compileKotlin :apps:api:compileTestKotlin

# Release: build + push + deploy the API to Cloud Run, then health-check it.
deploy-api:
	./scripts/deploy-api.sh

# Validate the deploy configuration without building.
deploy-check:
	./scripts/deploy-api.sh --check

test: db-up
	./gradlew :apps:api:test

clean:
	./gradlew clean

docs: db-up
	./gradlew :apps:api:bootRun &
	sleep 8
	open http://localhost:8080/docs
