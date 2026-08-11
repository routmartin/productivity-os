package com.productivityos.task

import com.productivityos.project.ProjectRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.util.UUID

@Service
@Transactional
class AssignTaskToProjectService(
    private val taskRepository: TaskRepository,
    private val projectRepository: ProjectRepository,
    private val clock: Clock
) {
    fun assign(taskId: UUID, projectId: UUID?, userId: UUID): TaskResponse {
        val entity = taskRepository.findById(taskId).orElse(null)
            ?: throw TaskNotFoundException(taskId)

        require(entity.userId == userId) { "Task does not belong to the current user" }

        if (projectId != null) {
            val project = projectRepository.findById(projectId).orElse(null)
                ?: throw NoSuchElementException("Project not found: $projectId")

            require(project.userId == userId) { "Project does not belong to the current user" }
        }

        entity.projectId = projectId
        entity.updatedAt = clock.instant()
        taskRepository.save(entity)

        return TaskResponse.from(entity)
    }
}
