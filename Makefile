.PHONY: dev run db-up db-down build test clean docs web web-mock web-install preview kill

web-install:
	cd apps/web && pnpm install

# Full mock preview: every feature serves mock data, no backend needed.
web-mock:
	cd apps/web && \
	VITE_USE_MOCK_AUTH=true VITE_USE_MOCK_TASKS=true VITE_USE_MOCK_PROJECTS=true \
	VITE_USE_MOCK_GOALS=true VITE_USE_MOCK_PLANNING=true VITE_USE_MOCK_FOCUS=true \
	pnpm dev

# Design review without the backend: mock auth only.
web:
	cd apps/web && VITE_USE_MOCK_AUTH=true pnpm dev

# End-to-end run against the real backend: DB + API + web with real auth.
preview: db-up
	./gradlew :apps:api:bootRun &
	sleep 8
	cd apps/web && VITE_USE_MOCK_AUTH=false pnpm dev

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

test: db-up
	./gradlew :apps:api:test

clean:
	./gradlew clean

docs: db-up
	./gradlew :apps:api:bootRun &
	sleep 8
	open http://localhost:8080/docs
