package com.productivityos.task

import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.util.UUID

@Service
@Transactional
class CompleteTaskService(
    private val taskRepository: TaskRepository,
    private val clock: Clock
) {

    fun complete(taskId: UUID, ownerId: UUID): TaskResponse {
        val entity = taskRepository.findById(taskId).orElse(null)
            ?: throw TaskNotFoundException(taskId)

        require(entity.userId == ownerId) { "Task does not belong to the current user" }

        val domain = entity.toDomain()
        val completed = domain.complete(clock.instant())

        entity.status = TaskStatus.COMPLETED
        entity.completedAt = completed.completedAt
        entity.updatedAt = clock.instant()
        taskRepository.save(entity)

        return TaskResponse.from(entity)
    }
}

class TaskNotFoundException(taskId: UUID) : RuntimeException("Task not found: $taskId")
