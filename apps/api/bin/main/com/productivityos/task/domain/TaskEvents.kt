package com.productivityos.task.domain

import java.util.UUID

data class TaskCompletedEvent(
    val taskId: UUID,
    val userId: UUID
)

data class TaskCancelledEvent(
    val taskId: UUID,
    val userId: UUID
)

data class TaskDeletedEvent(
    val taskId: UUID,
    val userId: UUID
)

data class TaskRestoredEvent(
    val taskId: UUID,
    val userId: UUID
)
