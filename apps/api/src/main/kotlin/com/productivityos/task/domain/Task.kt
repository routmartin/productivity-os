package com.productivityos.task.domain

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
    val status: TaskStatus = TaskStatus.PLANNED,
    val completedAt: Instant? = null,
    val deletedAt: Instant? = null,
    val projectId: UUID? = null
) {

    fun plan(): Task {
        require(status == TaskStatus.INBOX || status == TaskStatus.PLANNED) {
            "Cannot transition from $status to PLANNED"
        }
        require(deletedAt == null) { "Cannot transition a deleted task" }
        return copy(status = TaskStatus.PLANNED)
    }

    fun start(): Task {
        require(status == TaskStatus.PLANNED || status == TaskStatus.INBOX) {
            "Cannot transition from $status to IN_PROGRESS"
        }
        require(deletedAt == null) { "Cannot transition a deleted task" }
        return copy(status = TaskStatus.IN_PROGRESS)
    }

    fun complete(now: Instant): Task {
        require(status == TaskStatus.IN_PROGRESS || status == TaskStatus.PLANNED) {
            "Cannot complete task from $status state"
        }
        require(deletedAt == null) { "Cannot transition a deleted task" }
        return copy(status = TaskStatus.COMPLETED, completedAt = now)
    }

    fun uncomplete(targetStatus: TaskStatus = TaskStatus.IN_PROGRESS): Task {
        require(status == TaskStatus.COMPLETED) { "Cannot uncomplete a task in $status state" }
        require(deletedAt == null) { "Cannot uncomplete a deleted task" }
        require(targetStatus == TaskStatus.PLANNED || targetStatus == TaskStatus.IN_PROGRESS) {
            "Target status for uncompletion must be PLANNED or IN_PROGRESS"
        }
        return copy(status = targetStatus, completedAt = null)
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
        get() = status != TaskStatus.COMPLETED && status != TaskStatus.CANCELLED

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
