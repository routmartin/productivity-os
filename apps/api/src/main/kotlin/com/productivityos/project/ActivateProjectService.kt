package com.productivityos.project

import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.util.UUID

@Service
@Transactional
class ActivateProjectService(
    private val projectRepository: ProjectRepository,
    private val clock: Clock
) {
    fun activate(projectId: UUID, userId: UUID): ProjectResponse {
        val entity = projectRepository.findById(projectId).orElse(null)
            ?: throw NoSuchElementException("Project not found: $projectId")

        require(entity.userId == userId) { "Project does not belong to the current user" }

        val domain = entity.toDomain()
        domain.activate()

        entity.status = ProjectStatus.ACTIVE
        entity.updatedAt = clock.instant()
        projectRepository.save(entity)

        return ProjectResponse.from(entity)
    }
}
