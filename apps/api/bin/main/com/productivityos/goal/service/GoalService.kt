package com.productivityos.goal.service

import org.springframework.context.ApplicationEventPublisher
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.util.UUID
import com.productivityos.goal.domain.GoalCompletedEvent
import com.productivityos.goal.domain.GoalDeletedEvent
import com.productivityos.goal.domain.GoalReopenedEvent
import com.productivityos.goal.domain.GoalStatus
import com.productivityos.goal.dto.CreateGoalRequest
import com.productivityos.goal.dto.GoalResponse
import com.productivityos.goal.dto.UpdateGoalRequest
import com.productivityos.goal.exception.GoalNotFoundException
import com.productivityos.goal.persistence.GoalEntity
import com.productivityos.goal.persistence.GoalRepository

@Service
@Transactional
class GoalService(
    private val goalRepository: GoalRepository,
    private val clock: Clock,
    private val publisher: ApplicationEventPublisher
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
        val completed = entity.toDomain().complete(clock.instant())

        entity.status = GoalStatus.COMPLETED
        entity.completedAt = completed.completedAt
        entity.updatedAt = clock.instant()
        goalRepository.save(entity)

        // Cross-module cleanup: GoalSyncService archives the goal's completed
        // projects synchronously in this same transaction, and rejects the
        // completion if unresolved projects remain.
        publisher.publishEvent(GoalCompletedEvent(goalId, userId))

        return GoalResponse.from(entity)
    }

    fun reopen(goalId: UUID, userId: UUID, projectIds: List<UUID>): GoalResponse {
        val entity = loadOwned(goalId, userId)
        entity.toDomain().reopen()

        entity.status = GoalStatus.ACTIVE
        entity.updatedAt = clock.instant()
        goalRepository.save(entity)

        // Cross-module cleanup: GoalSyncService reactivates the selected
        // archived projects synchronously in this same transaction.
        publisher.publishEvent(GoalReopenedEvent(goalId, userId, projectIds))

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

    fun update(goalId: UUID, userId: UUID, request: UpdateGoalRequest): GoalResponse {
        val entity = loadOwned(goalId, userId)
        request.title?.let { entity.title = it }
        entity.description = request.description
        entity.deadline = request.deadline
        entity.updatedAt = clock.instant()
        return GoalResponse.from(goalRepository.save(entity))
    }

    fun delete(goalId: UUID, userId: UUID) {
        val entity = loadOwned(goalId, userId)
        // Detach the goal's projects so they stay alive, goal-less
        // (amendment AC-017). GoalSyncService detaches synchronously in the
        // same transaction, before the goal delete commits.
        publisher.publishEvent(GoalDeletedEvent(goalId, userId))
        goalRepository.delete(entity)
    }

    private fun loadOwned(goalId: UUID, userId: UUID): GoalEntity {
        val entity = goalRepository.findById(goalId).orElse(null)
            ?: throw GoalNotFoundException(goalId)
        require(entity.userId == userId) { "Goal does not belong to the current user" }
        return entity
    }
}
