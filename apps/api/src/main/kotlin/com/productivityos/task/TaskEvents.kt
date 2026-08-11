package com.productivityos.task

import java.util.UUID

data class TaskDeletedEvent(
    val taskId: UUID,
    val userId: UUID
)

data class TaskRestoredEvent(
    val taskId: UUID,
    val userId: UUID
)
