package com.productivityos.task

import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.util.UUID

@Service
@Transactional
class TransitionTaskService(
    private val taskRepository: TaskRepository,
    private val clock: Clock
) {

    fun plan(taskId: UUID, ownerId: UUID): TaskResponse {
        val entity = taskRepository.findById(taskId).orElse(null)
            ?: throw TaskNotFoundException(taskId)
        require(entity.userId == ownerId) { "Task does not belong to the current user" }

        val domain = entity.toDomain()
        domain.plan()

        entity.status = TaskStatus.PLANNED
        entity.updatedAt = clock.instant()
        taskRepository.save(entity)

        return TaskResponse.from(entity)
    }

    fun start(taskId: UUID, ownerId: UUID): TaskResponse {
        val entity = taskRepository.findById(taskId).orElse(null)
            ?: throw TaskNotFoundException(taskId)
        require(entity.userId == ownerId) { "Task does not belong to the current user" }

        val domain = entity.toDomain()
        domain.start()

        entity.status = TaskStatus.IN_PROGRESS
        entity.updatedAt = clock.instant()
        taskRepository.save(entity)

        return TaskResponse.from(entity)
    }
}
