package com.productivityos.goal

import com.productivityos.project.ProjectRepository
import com.productivityos.project.ProjectStatus
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.util.UUID

@Service
@Transactional
class GoalService(
    private val goalRepository: GoalRepository,
    private val projectRepository: ProjectRepository,
    private val clock: Clock
) {
    fun create(userId: UUID, request: CreateGoalRequest): GoalResponse {
        val now = clock.instant()
        val entity = GoalEntity.from(
            userId = userId,
            title = request.title,
            description = request.description,
            deadline = request.deadline,
            now = now
        )
        return GoalResponse.from(goalRepository.save(entity))
    }

    fun activate(goalId: UUID, userId: UUID): GoalResponse {
        val entity = loadOwned(goalId, userId)
        val domain = entity.toDomain()
        domain.activate()

        entity.status = GoalStatus.ACTIVE
        entity.updatedAt = clock.instant()
        return GoalResponse.from(goalRepository.save(entity))
    }

    fun returnToDraft(goalId: UUID, userId: UUID): GoalResponse {
        val entity = loadOwned(goalId, userId)
        entity.toDomain().returnToDraft()
        entity.status = GoalStatus.DRAFT
        entity.updatedAt = clock.instant()
        return GoalResponse.from(goalRepository.save(entity))
    }

    fun complete(goalId: UUID, userId: UUID): GoalResponse {
        val entity = loadOwned(goalId, userId)
        val domain = entity.toDomain()

        val projects = projectRepository.findByGoalIdAndUserId(goalId, userId)
        val blocking = projects.filter {
            it.status == ProjectStatus.DRAFT || it.status == ProjectStatus.ACTIVE
        }
        require(blocking.isEmpty()) {
            "Goal has ${blocking.size} unresolved project(s)"
        }

        val completed = domain.complete(clock.instant())

        entity.status = GoalStatus.COMPLETED
        entity.completedAt = completed.completedAt
        entity.updatedAt = clock.instant()
        goalRepository.save(entity)

        projects.forEach { project ->
            if (project.status == ProjectStatus.COMPLETED) {
                project.status = ProjectStatus.ARCHIVED
                project.updatedAt = clock.instant()
            }
        }

        return GoalResponse.from(entity)
    }

    fun reopen(goalId: UUID, userId: UUID, projectIds: List<UUID>): GoalResponse {
        val entity = loadOwned(goalId, userId)
        val domain = entity.toDomain()
        domain.reopen()

        entity.status = GoalStatus.ACTIVE
        entity.updatedAt = clock.instant()
        goalRepository.save(entity)

        val archivedProjects = projectRepository.findByGoalIdAndUserId(goalId, userId)
            .filter { it.status == ProjectStatus.ARCHIVED }
        archivedProjects.forEach { project ->
            if (project.id in projectIds) {
                project.status = ProjectStatus.ACTIVE
                project.updatedAt = clock.instant()
            }
        }

        return GoalResponse.from(entity)
    }

    fun archive(goalId: UUID, userId: UUID): GoalResponse {
        val entity = loadOwned(goalId, userId)
        val domain = entity.toDomain()
        domain.archive()

        entity.status = GoalStatus.ARCHIVED
        entity.updatedAt = clock.instant()
        return GoalResponse.from(goalRepository.save(entity))
    }

    @Transactional(readOnly = true)
    fun listAll(userId: UUID): List<GoalResponse> {
        return goalRepository.findAllByUserId(userId)
            .map { GoalResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun getById(goalId: UUID, userId: UUID): GoalResponse {
        return GoalResponse.from(loadOwned(goalId, userId))
    }

    private fun loadOwned(goalId: UUID, userId: UUID): GoalEntity {
        val entity = goalRepository.findById(goalId).orElse(null)
            ?: throw NoSuchElementException("Goal not found: $goalId")
        require(entity.userId == userId) { "Goal does not belong to the current user" }
        return entity
    }
}
