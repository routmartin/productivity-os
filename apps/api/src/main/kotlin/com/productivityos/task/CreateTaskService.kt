package com.productivityos.task

import com.productivityos.user.CurrentUser
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock

@Service
@Transactional
class CreateTaskService(
    private val taskRepository: TaskRepository,
    private val currentUser: CurrentUser,
    private val clock: Clock
) {

    fun create(request: CreateTaskRequest): TaskResponse {
        val now = clock.instant()
        val entity = TaskEntity.from(
            ownerId = currentUser.id(),
            title = request.title,
            description = request.description,
            dueDate = request.dueDate,
            now = now
        )
        val saved = taskRepository.save(entity)
        return TaskResponse.from(saved)
    }
}
