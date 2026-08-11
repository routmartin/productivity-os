package com.productivityos.task

import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.util.UUID

@Service
@Transactional
class DeleteTaskService(
    private val taskRepository: TaskRepository,
    private val clock: Clock
) {

    fun delete(taskId: UUID, ownerId: UUID) {
        val entity = taskRepository.findById(taskId).orElse(null)
            ?: throw TaskNotFoundException(taskId)

        require(entity.userId == ownerId) { "Task does not belong to the current user" }
        require(entity.deletedAt == null) { "Task is already deleted" }

        entity.deletedAt = clock.instant()
        entity.updatedAt = clock.instant()
        taskRepository.save(entity)
    }
}
