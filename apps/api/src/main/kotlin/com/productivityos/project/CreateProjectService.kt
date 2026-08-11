package com.productivityos.project

import com.productivityos.user.CurrentUser
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock

@Service
@Transactional
class CreateProjectService(
    private val projectRepository: ProjectRepository,
    private val currentUser: CurrentUser,
    private val clock: Clock
) {
    fun create(request: CreateProjectRequest): ProjectResponse {
        val now = clock.instant()
        val entity = ProjectEntity.from(
            userId = currentUser.id(),
            title = request.title,
            description = request.description,
            goalId = request.goalId,
            deadline = request.deadline,
            now = now
        )
        val saved = projectRepository.save(entity)
        return ProjectResponse.from(saved)
    }
}
