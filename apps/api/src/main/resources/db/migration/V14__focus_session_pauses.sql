-- V14: Focus session pauses (ADR-008).
-- Pause intervals make the recorded duration equal active focus time:
--   duration = max(0, (ended_at - started_at) - sum(pause intervals))
-- At most one open pause (ended_at IS NULL) per session.
-- Spec: docs/specs/focus/focus-management.md

CREATE TABLE focus_session_pauses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES focus_sessions(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,
    CONSTRAINT focus_session_pauses_interval_chk
        CHECK (ended_at IS NULL OR ended_at >= started_at)
);

CREATE UNIQUE INDEX idx_fsp_session_open
    ON focus_session_pauses (session_id)
    WHERE ended_at IS NULL;

CREATE INDEX idx_fsp_session_id ON focus_session_pauses (session_id);
