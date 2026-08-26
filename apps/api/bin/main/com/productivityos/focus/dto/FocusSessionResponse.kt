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
            val endedAt = entity.endedAt
            val duration = if (endedAt != null) {
                endedAt.epochSecond - entity.startedAt.epochSecond
            } else null
            return FocusSessionResponse(
                id = entity.id!!,
                taskId = entity.taskId,
                taskTitle = taskTitle,
                startedAt = entity.startedAt,
                endedAt = endedAt,
                durationSeconds = duration,
                configuredDurationSeconds = entity.configuredDurationSeconds,
                note = entity.note,
                isActive = entity.endedAt == null
            )
        }
    }
}
