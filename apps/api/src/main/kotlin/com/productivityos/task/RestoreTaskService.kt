package com.productivityos.task

import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.util.UUID

@Service
@Transactional
class RestoreTaskService(
    private val taskRepository: TaskRepository,
    private val clock: Clock
) {

    fun restore(taskId: UUID, ownerId: UUID): TaskResponse {
        val entity = taskRepository.findById(taskId).orElse(null)
            ?: throw TaskNotFoundException(taskId)

        require(entity.userId == ownerId) { "Task does not belong to the current user" }
        require(entity.deletedAt != null) { "Task is not deleted" }

        entity.deletedAt = null
        entity.updatedAt = clock.instant()
        taskRepository.save(entity)

        return TaskResponse.from(entity)
    }
}
