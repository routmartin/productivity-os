-- V15: Daily Schedule Link-Map and Habit Tracker
-- Spec: docs/specs/planning/daily-schedule-linkmap.md
-- ADRs: ADR-003 (Persistence), ADR-004 (User Isolation), ADR-006 (Timezones)

CREATE TABLE schedule_habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    subtitle TEXT,
    icon VARCHAR(64) NOT NULL DEFAULT 'sun.max',
    phase VARCHAR(32) NOT NULL,
    target_time VARCHAR(8),
    duration_minutes INT NOT NULL DEFAULT 15 CHECK (duration_minutes > 0),
    order_index INT NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_schedule_habits_user_id ON schedule_habits (user_id);
CREATE INDEX idx_schedule_habits_user_active ON schedule_habits (user_id, phase) WHERE deleted_at IS NULL;

CREATE TABLE schedule_habit_occurrences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    habit_id UUID NOT NULL REFERENCES schedule_habits(id) ON DELETE CASCADE,
    calendar_date DATE NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_habit_occurrence_user_habit_date UNIQUE (user_id, habit_id, calendar_date)
);

CREATE INDEX idx_sho_user_date ON schedule_habit_occurrences (user_id, calendar_date);
CREATE INDEX idx_sho_habit_date ON schedule_habit_occurrences (habit_id, calendar_date);

CREATE TABLE schedule_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    calendar_date DATE NOT NULL,
    step_type VARCHAR(32) NOT NULL,
    phase VARCHAR(32) NOT NULL,
    title VARCHAR(255) NOT NULL,
    subtitle TEXT,
    time_label VARCHAR(32),
    duration_minutes INT NOT NULL DEFAULT 30 CHECK (duration_minutes >= 0),
    in_focus BOOLEAN NOT NULL DEFAULT FALSE,
    completed_minutes INT NOT NULL DEFAULT 0 CHECK (completed_minutes >= 0),
    order_index INT NOT NULL DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_schedule_entries_user_date ON schedule_entries (user_id, calendar_date) WHERE deleted_at IS NULL;
