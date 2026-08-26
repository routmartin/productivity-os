package com.productivityos.project.service

import com.productivityos.goal.domain.GoalCompletedEvent
import com.productivityos.goal.domain.GoalDeletedEvent
import com.productivityos.goal.domain.GoalReopenedEvent
import com.productivityos.project.domain.ProjectStatus
import com.productivityos.project.persistence.ProjectRepository
import org.springframework.context.event.EventListener
import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock

@Service
@Transactional
class GoalSyncService(
    private val projectRepository: ProjectRepository,
    private val jdbcTemplate: JdbcTemplate,
    private val clock: Clock
) {

    @EventListener
    fun onGoalCompleted(event: GoalCompletedEvent) {
        val projects = projectRepository.findByGoalIdAndUserId(event.goalId, event.userId)
        val blocking = projects.filter {
            it.status == ProjectStatus.DRAFT || it.status == ProjectStatus.ACTIVE
        }
        require(blocking.isEmpty()) {
            "Goal has ${blocking.size} unresolved project(s)"
        }

        val now = clock.instant()
        projects.filter { it.status == ProjectStatus.COMPLETED }
            .forEach { project ->
                project.status = ProjectStatus.ARCHIVED
                project.updatedAt = now
            }
    }

    @EventListener
    fun onGoalReopened(event: GoalReopenedEvent) {
        val now = clock.instant()
        projectRepository.findByGoalIdAndUserId(event.goalId, event.userId)
            .filter { it.status == ProjectStatus.ARCHIVED }
            .forEach { project ->
                if (project.id in event.projectIds) {
                    project.status = ProjectStatus.ACTIVE
                    project.updatedAt = now
                }
            }
    }

    @EventListener
    fun onGoalDeleted(event: GoalDeletedEvent) {
        // Detach the goal's projects so they stay alive, goal-less
        // (amendment AC-017). Same transaction as the goal delete.
        jdbcTemplate.update(
            "UPDATE projects SET goal_id = NULL WHERE goal_id = ?",
            event.goalId
        )
    }
}
