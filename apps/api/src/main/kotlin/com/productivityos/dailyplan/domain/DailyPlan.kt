package com.productivityos.dailyplan.domain

import java.time.LocalDate
import java.util.UUID

data class DailyPlan(
    val id: UUID,
    val userId: UUID,
    val taskId: UUID,
    val calendarDate: LocalDate,
    val remark: String? = null
)
