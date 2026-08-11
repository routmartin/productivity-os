package com.productivityos.project

import com.productivityos.user.CurrentUser
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.UUID

@Service
@Transactional(readOnly = true)
class ListProjectsService(
    private val projectRepository: ProjectRepository,
    private val currentUser: CurrentUser
) {
    fun listAll(): List<ProjectResponse> {
        return projectRepository.findAllByUserId(currentUser.id())
            .map { ProjectResponse.from(it) }
    }

    fun getById(projectId: UUID, userId: UUID): ProjectResponse {
        val entity = projectRepository.findById(projectId).orElse(null)
            ?: throw NoSuchElementException("Project not found: $projectId")

        require(entity.userId == userId) { "Project does not belong to the current user" }

        return ProjectResponse.from(entity)
    }
}
