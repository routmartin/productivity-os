package com.productivityos.focus.persistence

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.time.Instant
import java.util.UUID

/**
 * A single pause interval for a focus session (ADR-008).
 *
 * A row with `endedAt == null` is the session's open pause; at most one such
 * row may exist per session (enforced by `idx_fsp_session_open`).
 */
@Entity
@Table(name = "focus_session_pauses")
class FocusSessionPauseEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    val id: UUID? = null,

    @Column(name = "session_id", nullable = false)
    val sessionId: UUID,

    @Column(name = "started_at", nullable = false)
    val startedAt: Instant,

    @Column(name = "ended_at")
    var endedAt: Instant? = null
)
