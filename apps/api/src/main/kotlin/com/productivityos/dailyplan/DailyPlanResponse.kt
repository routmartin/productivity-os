package com.productivityos.dailyplan

import java.time.LocalDate
import java.util.UUID

data class DailyPlanResponse(
    val id: UUID,
    val taskId: UUID,
    val taskTitle: String?,
    val calendarDate: LocalDate,
    val remark: String?,
    val isDeleted: Boolean
) {
    companion object {
        fun from(entity: DailyPlanEntity, taskTitle: String?): DailyPlanResponse = DailyPlanResponse(
            id = entity.id!!,
            taskId = entity.taskId,
            taskTitle = taskTitle,
            calendarDate = entity.calendarDate,
            remark = entity.remark,
            isDeleted = entity.deletedAt != null
        )
    }
}
