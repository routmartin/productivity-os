package com.productivityos.task.dto

import java.time.Instant
import java.time.LocalDate
import java.util.UUID
import com.productivityos.task.domain.Energy
import com.productivityos.task.domain.Priority
import com.productivityos.task.domain.TaskStatus
import com.productivityos.task.persistence.TaskEntity

data class TaskResponse(
    val id: UUID,
    val ownerId: UUID,
    val title: String,
    val description: String?,
    val dueDate: LocalDate?,
    val priority: Priority?,
    val energy: Energy?,
    val estimatedDurationMinutes: Int?,
    val status: TaskStatus,
    val completedAt: Instant?,
    val deletedAt: Instant?,
    val projectId: UUID?,
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
            priority = entity.priority,
            energy = entity.energy,
            estimatedDurationMinutes = entity.estimatedDurationMinutes,
            status = entity.status,
            completedAt = entity.completedAt,
            deletedAt = entity.deletedAt,
            projectId = entity.projectId,
            createdAt = entity.createdAt,
            updatedAt = entity.updatedAt
        )
    }
}
