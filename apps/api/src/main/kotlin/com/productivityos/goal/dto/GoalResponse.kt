package com.productivityos.goal.dto

import java.time.Instant
import java.time.LocalDate
import java.util.UUID
import com.productivityos.goal.domain.GoalStatus
import com.productivityos.goal.persistence.GoalEntity

data class GoalResponse(
    val id: UUID,
    val userId: UUID,
    val title: String,
    val description: String?,
    val status: GoalStatus,
    val deadline: LocalDate?,
    val completedAt: Instant?,
    val createdAt: Instant,
    val updatedAt: Instant
) {
    companion object {
        fun from(entity: GoalEntity): GoalResponse = GoalResponse(
            id = entity.id!!,
            userId = entity.userId,
            title = entity.title,
            description = entity.description,
            status = entity.status,
            deadline = entity.deadline,
            completedAt = entity.completedAt,
            createdAt = entity.createdAt,
            updatedAt = entity.updatedAt
        )
    }
}
