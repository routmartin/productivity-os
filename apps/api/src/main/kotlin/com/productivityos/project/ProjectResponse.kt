package com.productivityos.project

import java.time.Instant
import java.time.LocalDate
import java.util.UUID

data class ProjectResponse(
    val id: UUID,
    val userId: UUID,
    val title: String,
    val description: String?,
    val goalId: UUID?,
    val status: ProjectStatus,
    val deadline: LocalDate?,
    val completedAt: Instant?,
    val createdAt: Instant,
    val updatedAt: Instant
) {
    companion object {
        fun from(entity: ProjectEntity): ProjectResponse = ProjectResponse(
            id = entity.id!!,
            userId = entity.userId,
            title = entity.title,
            description = entity.description,
            goalId = entity.goalId,
            status = entity.status,
            deadline = entity.deadline,
            completedAt = entity.completedAt,
            createdAt = entity.createdAt,
            updatedAt = entity.updatedAt
        )
    }
}
