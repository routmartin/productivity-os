package com.productivityos.focus.persistence

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.time.Instant
import java.util.UUID
import com.productivityos.focus.domain.FocusSession

@Entity
@Table(name = "focus_sessions")
class FocusSessionEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    val id: UUID? = null,

    @Column(name = "user_id", nullable = false)
    val userId: UUID,

    @Column(name = "task_id", nullable = false)
    val taskId: UUID,

    @Column(name = "started_at", nullable = false)
    val startedAt: Instant,

    @Column(name = "ended_at")
    var endedAt: Instant? = null,

    @Column(name = "configured_duration_seconds")
    val configuredDurationSeconds: Int? = null,

    @Column
    val note: String? = null
) {

    fun toDomain(): FocusSession = FocusSession(
        id = id!!,
        userId = userId,
        taskId = taskId,
        startedAt = startedAt,
        endedAt = endedAt,
        configuredDurationSeconds = configuredDurationSeconds,
        note = note
    )
}
