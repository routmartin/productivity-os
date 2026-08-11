package com.productivityos.task

import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.util.UUID

@Service
@Transactional
class ReopenTaskService(
    private val taskRepository: TaskRepository,
    private val clock: Clock
) {

    fun reopen(taskId: UUID, ownerId: UUID): TaskResponse {
        val entity = taskRepository.findById(taskId).orElse(null)
            ?: throw TaskNotFoundException(taskId)

        require(entity.userId == ownerId) { "Task does not belong to the current user" }

        val domain = entity.toDomain()
        domain.reopen()

        entity.status = TaskStatus.PLANNED
        entity.updatedAt = clock.instant()
        taskRepository.save(entity)

        return TaskResponse.from(entity)
    }
}
