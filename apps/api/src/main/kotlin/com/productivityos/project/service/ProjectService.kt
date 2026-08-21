package com.productivityos.project.service

import com.productivityos.task.persistence.TaskRepository
import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.util.UUID
import com.productivityos.project.domain.ProjectStatus
import com.productivityos.project.dto.CreateProjectRequest
import com.productivityos.project.dto.ProjectResponse
import com.productivityos.project.dto.UpdateProjectRequest
import com.productivityos.project.exception.ProjectNotFoundException
import com.productivityos.project.persistence.ProjectEntity
import com.productivityos.project.persistence.ProjectRepository

@Service
@Transactional
class ProjectService(
    private val projectRepository: ProjectRepository,
    private val taskRepository: TaskRepository,
    private val jdbcTemplate: JdbcTemplate,
    private val clock: Clock
) {
    fun create(userId: UUID, request: CreateProjectRequest): ProjectResponse {
        val now = clock.instant()
        val entity = ProjectEntity.from(
            userId = userId,
            title = request.title,
            description = request.description,
            goalId = request.goalId,
            deadline = request.deadline,
            now = now
        )
        return ProjectResponse.from(projectRepository.save(entity))
    }

    @Transactional(readOnly = true)
    fun listAll(userId: UUID): List<ProjectResponse> {
        return projectRepository.findAllByUserId(userId)
            .map { ProjectResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun getById(projectId: UUID, userId: UUID): ProjectResponse {
        return ProjectResponse.from(loadOwned(projectId, userId))
    }

    fun activate(projectId: UUID, userId: UUID): ProjectResponse {
        val entity = loadOwned(projectId, userId)
        entity.toDomain().activate()
        entity.status = ProjectStatus.ACTIVE
        entity.updatedAt = clock.instant()
        return ProjectResponse.from(projectRepository.save(entity))
    }

    fun returnToDraft(projectId: UUID, userId: UUID): ProjectResponse {
        val entity = loadOwned(projectId, userId)
        entity.toDomain().returnToDraft()
        entity.status = ProjectStatus.DRAFT
        entity.updatedAt = clock.instant()
        return ProjectResponse.from(projectRepository.save(entity))
    }

    fun complete(projectId: UUID, userId: UUID): ProjectResponse {
        val entity = loadOwned(projectId, userId)
        val unresolvedCount = taskRepository.countByProjectIdAndUserIdAndStatusNotCompleted(
            projectId, userId
        )
        require(unresolvedCount == 0L) {
            "Project has $unresolvedCount unresolved incomplete task(s)"
        }
        val completed = entity.toDomain().complete(clock.instant())
        entity.status = ProjectStatus.COMPLETED
        entity.completedAt = completed.completedAt
        entity.updatedAt = clock.instant()
        return ProjectResponse.from(projectRepository.save(entity))
    }

    fun archive(projectId: UUID, userId: UUID): ProjectResponse {
        val entity = loadOwned(projectId, userId)
        entity.toDomain().archive()
        entity.status = ProjectStatus.ARCHIVED
        entity.updatedAt = clock.instant()
        return ProjectResponse.from(projectRepository.save(entity))
    }

    fun update(projectId: UUID, userId: UUID, request: UpdateProjectRequest): ProjectResponse {
        val entity = loadOwned(projectId, userId)
        request.title?.let { entity.title = it }
        entity.description = request.description
        entity.goalId = request.goalId
        entity.deadline = request.deadline
        entity.updatedAt = clock.instant()
        return ProjectResponse.from(projectRepository.save(entity))
    }

    fun delete(projectId: UUID, userId: UUID) {
        val entity = loadOwned(projectId, userId)
        // Detach the project's tasks so they stay alive, project-less
        // (amendment AC-015). Same transaction as the delete.
        jdbcTemplate.update(
            "UPDATE tasks SET project_id = NULL WHERE project_id = ?",
            projectId
        )
        projectRepository.delete(entity)
    }

    private fun loadOwned(projectId: UUID, userId: UUID): ProjectEntity {
        val entity = projectRepository.findById(projectId).orElse(null)
            ?: throw ProjectNotFoundException(projectId)
        require(entity.userId == userId) { "Project does not belong to the current user" }
        return entity
    }
}
