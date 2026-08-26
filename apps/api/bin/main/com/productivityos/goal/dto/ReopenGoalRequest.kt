package com.productivityos.goal.dto

import java.util.UUID

data class ReopenGoalRequest(
    val projectIds: List<UUID>
)
