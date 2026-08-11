package com.productivityos.project

import com.productivityos.task.TaskRepository
import com.productivityos.task.TaskStatus
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.util.UUID

@Service
@Transactional
class CompleteProjectService(
    private val projectRepository: ProjectRepository,
    private val taskRepository: TaskRepository,
    private val clock: Clock
) {
    fun complete(projectId: UUID, userId: UUID): ProjectResponse {
        val entity = projectRepository.findById(projectId).orElse(null)
            ?: throw NoSuchElementException("Project not found: $projectId")

        require(entity.userId == userId) { "Project does not belong to the current user" }

        val unresolvedCount = taskRepository.countByProjectIdAndUserIdAndStatusNotCompleted(
            projectId, userId
        )
        require(unresolvedCount == 0L) {
            "Project has $unresolvedCount unresolved incomplete task(s)"
        }

        val domain = entity.toDomain()
        val completed = domain.complete(clock.instant())

        entity.status = ProjectStatus.COMPLETED
        entity.completedAt = completed.completedAt
        entity.updatedAt = clock.instant()
        projectRepository.save(entity)

        return ProjectResponse.from(entity)
    }
}
