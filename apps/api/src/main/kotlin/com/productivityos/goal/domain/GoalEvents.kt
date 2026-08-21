package com.productivityos.goal.domain

import java.util.UUID

data class GoalCompletedEvent(
    val goalId: UUID,
    val userId: UUID
)

data class GoalReopenedEvent(
    val goalId: UUID,
    val userId: UUID,
    val projectIds: List<UUID>
)

data class GoalDeletedEvent(
    val goalId: UUID,
    val userId: UUID
)
