-- V9: Daily Planning (Plan 006).
-- Task planning per calendar date with soft-delete for history.
-- Spec: docs/specs/planning/daily-planning.md

CREATE TABLE daily_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    task_id UUID NOT NULL REFERENCES tasks(id),
    calendar_date DATE NOT NULL,
    remark TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX idx_dp_user_task_date_active
    ON daily_plans (user_id, task_id, calendar_date)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_dp_user_date ON daily_plans (user_id, calendar_date);
