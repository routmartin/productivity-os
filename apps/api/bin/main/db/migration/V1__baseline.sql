-- V1: Baseline (Plan 001, Step 2).
-- Schema of record is the Flyway migration set (ADR-003).
-- Domain tables arrive in later migrations:
--   V2: users + refresh_tokens (Step 3)
--   V3: tasks (Step 11)

CREATE EXTENSION IF NOT EXISTS pgcrypto;
