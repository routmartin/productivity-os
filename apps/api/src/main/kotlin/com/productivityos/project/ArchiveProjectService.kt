package com.productivityos.project

import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.UUID

@Service
@Transactional
class ArchiveProjectService(
    private val projectRepository: ProjectRepository
) {
    fun archive(projectId: UUID, userId: UUID): ProjectResponse {
        val entity = projectRepository.findById(projectId).orElse(null)
            ?: throw NoSuchElementException("Project not found: $projectId")

        require(entity.userId == userId) { "Project does not belong to the current user" }

        val domain = entity.toDomain()
        domain.archive()

        entity.status = ProjectStatus.ARCHIVED
        projectRepository.save(entity)

        return ProjectResponse.from(entity)
    }
}
