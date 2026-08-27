-- V5: Daily Top 3 (Plan 002, Milestone 2).
-- Daily prioritization: (user, date, task, position) with soft-delete
-- for historical preservation. Spec: docs/specs/planning/daily-top-three.md

CREATE TABLE daily_top_three (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    task_id UUID NOT NULL REFERENCES tasks(id),
    calendar_date DATE NOT NULL,
    position INT NOT NULL CHECK (position BETWEEN 1 AND 3),
    selected_at TIMESTAMPTZ NOT NULL,
    deleted_at TIMESTAMPTZ,
    version BIGINT NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX idx_dt3_user_date_pos_active
    ON daily_top_three (user_id, calendar_date, position)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_dt3_task_id ON daily_top_three (task_id);
CREATE INDEX idx_dt3_user_date ON daily_top_three (user_id, calendar_date);
