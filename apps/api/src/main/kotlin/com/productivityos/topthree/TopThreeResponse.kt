package com.productivityos.topthree

import java.time.Instant
import java.time.LocalDate
import java.util.UUID

data class TopThreeResponse(
    val id: UUID,
    val taskId: UUID?,
    val taskTitle: String?,
    val calendarDate: LocalDate,
    val position: Int,
    val selectedAt: Instant,
    val isCompleted: Boolean,
    val isDeleted: Boolean,
    val isCancelled: Boolean
) {
    companion object {
        fun from(
            entity: DailyTopThreeEntity,
            taskTitle: String?,
            completedAt: Instant?
        ): TopThreeResponse = TopThreeResponse(
            id = entity.id!!,
            taskId = entity.taskId,
            taskTitle = taskTitle,
            calendarDate = entity.calendarDate,
            position = entity.position,
            selectedAt = entity.selectedAt,
            isCompleted = completedAt != null,
            isDeleted = entity.deletedAt != null,
            isCancelled = false
        )

        fun deleted(entity: DailyTopThreeEntity, originalPosition: Int): TopThreeResponse = TopThreeResponse(
            id = entity.id!!,
            taskId = null,
            taskTitle = "Deleted task",
            calendarDate = entity.calendarDate,
            position = originalPosition,
            selectedAt = entity.selectedAt,
            isCompleted = false,
            isDeleted = true,
            isCancelled = false
        )
    }
}
