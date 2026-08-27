-- V4: Add Cancelled lifecycle state (Plan 002, Milestone 1).
-- Task Management spec AC-013-016, AC-020.

ALTER TABLE tasks DROP CONSTRAINT tasks_status_check;

ALTER TABLE tasks ADD CONSTRAINT tasks_status_check
    CHECK (status IN ('INBOX', 'PLANNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'));
