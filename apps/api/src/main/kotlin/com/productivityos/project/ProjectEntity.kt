package com.productivityos.project

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table
import jakarta.persistence.Version
import java.time.Instant
import java.time.LocalDate
import java.util.UUID

@Entity
@Table(name = "projects")
class ProjectEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    val id: UUID? = null,

    @Column(name = "user_id", nullable = false)
    val userId: UUID,

    @Column(name = "goal_id")
    val goalId: UUID? = null,

    @Column(nullable = false)
    val title: String,

    @Column
    val description: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var status: ProjectStatus = ProjectStatus.DRAFT,

    @Column
    val deadline: LocalDate? = null,

    @Column(name = "completed_at")
    var completedAt: Instant? = null,

    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: Instant,

    @Column(name = "updated_at", nullable = false)
    var updatedAt: Instant = Instant.now(),

    @Version
    var version: Long = 0
) {
    fun toDomain(): Project = Project(
        id = id!!,
        userId = userId,
        title = title,
        description = description,
        goalId = goalId,
        status = status,
        deadline = deadline,
        completedAt = completedAt
    )

    companion object {
        fun from(userId: UUID, title: String, description: String?, goalId: UUID?, deadline: LocalDate?, now: Instant): ProjectEntity =
            ProjectEntity(
                userId = userId,
                title = title,
                description = description,
                goalId = goalId,
                deadline = deadline,
                createdAt = now,
                updatedAt = now
            )
    }
}
