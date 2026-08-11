package com.productivityos.goal

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
@Table(name = "goals")
class GoalEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    val id: UUID? = null,

    @Column(name = "user_id", nullable = false)
    val userId: UUID,

    @Column(nullable = false)
    val title: String,

    @Column
    val description: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var status: GoalStatus = GoalStatus.DRAFT,

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
    fun toDomain(): Goal = Goal(
        id = id!!,
        userId = userId,
        title = title,
        description = description,
        status = status,
        deadline = deadline,
        completedAt = completedAt
    )

    companion object {
        fun from(
            userId: UUID,
            title: String,
            description: String?,
            deadline: LocalDate?,
            now: Instant
        ): GoalEntity = GoalEntity(
            userId = userId,
            title = title,
            description = description,
            deadline = deadline,
            createdAt = now,
            updatedAt = now
        )
    }
}
