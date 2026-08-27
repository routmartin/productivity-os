-- V11: Focus Sessions (Plan 007).
-- Manual and Pomodoro modes. One active session per user.
-- Spec: docs/specs/focus/focus-management.md

CREATE TABLE focus_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    task_id UUID NOT NULL REFERENCES tasks(id),
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,
    configured_duration_seconds INT,
    note TEXT
);

CREATE UNIQUE INDEX idx_fs_user_active
    ON focus_sessions (user_id)
    WHERE ended_at IS NULL;

CREATE INDEX idx_fs_user_id ON focus_sessions (user_id);
CREATE INDEX idx_fs_task_id ON focus_sessions (task_id);
