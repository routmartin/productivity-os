package com.productivityos.task

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
@Table(name = "tasks")
class TaskEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    val id: UUID? = null,

    @Column(name = "user_id", nullable = false)
    val userId: UUID,

    @Column(nullable = false)
    val title: String,

    @Column
    val description: String? = null,

    @Column(name = "due_date")
    val dueDate: LocalDate? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var status: TaskStatus = TaskStatus.INBOX,

    @Column(name = "completed_at")
    var completedAt: Instant? = null,

    @Column(name = "deleted_at")
    var deletedAt: Instant? = null,

    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: Instant,

    @Column(name = "updated_at", nullable = false)
    var updatedAt: Instant = Instant.now(),

    @Version
    var version: Long = 0
) {

    fun toDomain(): Task = Task(
        id = id!!,
        ownerId = userId,
        title = title,
        description = description,
        dueDate = dueDate,
        status = status,
        completedAt = completedAt,
        deletedAt = deletedAt
    )

    companion object {
        fun from(ownerId: UUID, title: String, description: String?, dueDate: LocalDate?, now: Instant): TaskEntity =
            TaskEntity(
                userId = ownerId,
                title = title,
                description = description,
                dueDate = dueDate,
                createdAt = now,
                updatedAt = now
            )
    }
}
