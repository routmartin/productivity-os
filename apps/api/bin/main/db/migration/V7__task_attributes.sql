-- V7: Task optional attributes (Plan 004).
-- Priority, energy level, estimated duration per Task Management spec AC-002.
-- Value domains are provisional; may be refined later.

ALTER TABLE tasks ADD COLUMN priority VARCHAR(10);
ALTER TABLE tasks ADD COLUMN energy VARCHAR(10);
ALTER TABLE tasks ADD COLUMN estimated_duration_minutes INT;
