-- V6: Projects (Plan 003).
-- Project lifecycle: Draft → Active → Completed → Archived.
-- Spec: docs/specs/projects/project-managment.md

CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    goal_id UUID,
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

CREATE INDEX idx_projects_user_id ON projects (user_id);

ALTER TABLE tasks ADD COLUMN project_id UUID REFERENCES projects(id);
CREATE INDEX idx_tasks_project_id ON tasks (project_id);
