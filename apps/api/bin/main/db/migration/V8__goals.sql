-- V8: Goals (Plan 005).
-- Goal lifecycle: Draft → Active → Completed → Archived.
-- Completed can be reopened. Archived is terminal.
-- Spec: docs/specs/goals/goal-management.md

CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    title VARCHAR(500) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT'
        CHECK (status IN ('DRAFT', 'ACTIVE', 'COMPLETED', 'ARCHIVED')),
    deadline DATE,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0
);

CREATE INDEX idx_goals_user_id ON goals (user_id);

ALTER TABLE projects ADD CONSTRAINT fk_projects_goal
    FOREIGN KEY (goal_id) REFERENCES goals(id);
