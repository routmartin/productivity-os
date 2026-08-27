-- V10: Daily Planning rollover + capacity (Plan 006).
-- Lazy auto-rollover with max 3 per chain. Daily capacity overrides.

ALTER TABLE daily_plans ADD COLUMN rollover_from_date DATE;

CREATE TABLE daily_capacities (
    user_id UUID NOT NULL REFERENCES users(id),
    calendar_date DATE NOT NULL,
    capacity_hours INT NOT NULL,
    PRIMARY KEY (user_id, calendar_date)
);
