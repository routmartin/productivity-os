package com.productivityos.focus.dto

import java.time.Instant
import java.util.UUID
import com.productivityos.focus.persistence.FocusSessionEntity

data class FocusSessionResponse(
    val id: UUID,
    val taskId: UUID,
    val taskTitle: String?,
    val startedAt: Instant,
    val endedAt: Instant?,
    val durationSeconds: Long?,
    val configuredDurationSeconds: Int?,
    val note: String?,
    val isActive: Boolean
) {
    companion object {
        fun from(entity: FocusSessionEntity, taskTitle: String?): FocusSessionResponse {
            // Prefer the persisted duration_seconds; fall back to deriving from
            // timestamps for any pre-V13 row that hasn't been backfilled yet.
            val duration = entity.durationSeconds ?: entity.endedAt?.let { endedAt ->
                endedAt.epochSecond - entity.startedAt.epochSecond
            }
            return FocusSessionResponse(
                id = entity.id!!,
                taskId = entity.taskId,
                taskTitle = taskTitle,
                startedAt = entity.startedAt,
                endedAt = entity.endedAt,
                durationSeconds = duration,
                configuredDurationSeconds = entity.configuredDurationSeconds,
                note = entity.note,
                isActive = entity.endedAt == null
            )
        }
    }
}
