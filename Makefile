.PHONY: dev run db-up db-down build test clean docs web web-install

web-install:
	cd apps/web && pnpm install

web:
	cd apps/web && pnpm dev

dev: db-up
	./gradlew :apps:api:bootRun &
	sleep 8
	open http://localhost:8080/docs
	wait

run: db-up
	./gradlew :apps:api:bootRun

db-up:
	docker compose up -d

db-down:
	docker compose down

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
