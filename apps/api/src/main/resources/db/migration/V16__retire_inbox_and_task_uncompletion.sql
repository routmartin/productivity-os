-- V16: Retire Inbox and default new tasks to Planned
-- Task Management spec update (Inbox retired, Planned is initial status)

UPDATE tasks SET status = 'PLANNED' WHERE status = 'INBOX';

ALTER TABLE tasks ALTER COLUMN status SET DEFAULT 'PLANNED';
