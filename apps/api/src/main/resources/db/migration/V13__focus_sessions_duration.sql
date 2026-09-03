-- V13: Persist focus session duration.
-- Before this migration, duration was derived in-memory at response time
-- (`ended_at - started_at`) and never stored, so SQL aggregates and any
-- server-side reporting had no column to read. This migration:
--   1. adds the column (null while active, required once ended),
--   2. backfills ended rows from ended_at - started_at,
--   3. enforces the invariant: ended_at present ⇒ duration_seconds present.

ALTER TABLE focus_sessions
    ADD COLUMN duration_seconds BIGINT;

UPDATE focus_sessions
SET duration_seconds = (EXTRACT(EPOCH FROM (ended_at - started_at)))::bigint
WHERE ended_at IS NOT NULL
  AND duration_seconds IS NULL;

ALTER TABLE focus_sessions
    ADD CONSTRAINT focus_sessions_duration_when_ended_chk
    CHECK (ended_at IS NULL OR duration_seconds IS NOT NULL);