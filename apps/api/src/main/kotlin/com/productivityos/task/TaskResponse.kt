package com.productivityos.task

import java.time.Instant
import java.time.LocalDate
import java.util.UUID

data class TaskResponse(
    val id: UUID,
    val ownerId: UUID,
    val title: String,
    val description: String?,
    val dueDate: LocalDate?,
    val status: TaskStatus,
    val completedAt: Instant?,
    val deletedAt: Instant?,
    val createdAt: Instant,
    val updatedAt: Instant
) {

    companion object {
        fun from(entity: TaskEntity): TaskResponse = TaskResponse(
            id = entity.id!!,
            ownerId = entity.userId,
            title = entity.title,
            description = entity.description,
            dueDate = entity.dueDate,
            status = entity.status,
            completedAt = entity.completedAt,
            deletedAt = entity.deletedAt,
            createdAt = entity.createdAt,
            updatedAt = entity.updatedAt
        )
    }
}
