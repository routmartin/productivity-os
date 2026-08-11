package com.productivityos.task

import java.time.Instant
import java.time.LocalDate
import java.util.UUID

data class Task(
    val id: UUID,
    val ownerId: UUID,
    val title: String,
    val description: String? = null,
    val dueDate: LocalDate? = null,
    val priority: Priority? = null,
    val energy: Energy? = null,
    val estimatedDurationMinutes: Int? = null,
    val status: TaskStatus = TaskStatus.INBOX,
    val completedAt: Instant? = null,
    val deletedAt: Instant? = null,
    val projectId: UUID? = null
) {

    fun plan(): Task {
        requireTransition(TaskStatus.INBOX, TaskStatus.PLANNED)
        return copy(status = TaskStatus.PLANNED)
    }

    fun start(): Task {
        requireTransition(TaskStatus.PLANNED, TaskStatus.IN_PROGRESS)
        return copy(status = TaskStatus.IN_PROGRESS)
    }

    fun complete(now: Instant): Task {
        requireTransition(TaskStatus.IN_PROGRESS, TaskStatus.COMPLETED)
        return copy(status = TaskStatus.COMPLETED, completedAt = now)
    }

    fun cancel(): Task {
        require(canBeCancelled) { "Cannot cancel a task in $status state" }
        require(deletedAt == null) { "Cannot cancel a deleted task" }
        return copy(status = TaskStatus.CANCELLED)
    }

    fun reopen(): Task {
        requireTransition(TaskStatus.CANCELLED, TaskStatus.PLANNED)
        return copy(status = TaskStatus.PLANNED)
    }

    private val canBeCancelled: Boolean
        get() = status == TaskStatus.INBOX || status == TaskStatus.PLANNED || status == TaskStatus.IN_PROGRESS

    private fun requireTransition(from: TaskStatus, to: TaskStatus) {
        require(status == from) {
            "Cannot transition from $status to $to"
        }
        require(deletedAt == null) {
            "Cannot transition a deleted task"
        }
        require(status != TaskStatus.COMPLETED) {
            "Cannot transition a completed task"
        }
    }
}
