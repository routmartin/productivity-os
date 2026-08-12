package com.productivityos.dailyplan

import java.util.UUID

data class PlanTaskRequest(
    val taskId: UUID,
    val remark: String? = null
)
