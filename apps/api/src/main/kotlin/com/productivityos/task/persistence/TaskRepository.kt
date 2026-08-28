package com.productivityos.task.persistence

import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import java.util.UUID

interface TaskRepository : JpaRepository<TaskEntity, UUID> {

    @Query("SELECT t FROM TaskEntity t WHERE t.userId = :userId AND t.deletedAt IS NULL AND t.status NOT IN (com.productivityos.task.domain.TaskStatus.COMPLETED, com.productivityos.task.domain.TaskStatus.CANCELLED) ORDER BY t.createdAt DESC")
    fun findActiveByUserId(userId: UUID, pageable: Pageable): Page<TaskEntity>

    @Query("SELECT COUNT(t) FROM TaskEntity t WHERE t.projectId = :projectId AND t.userId = :userId AND t.deletedAt IS NULL AND t.status NOT IN (com.productivityos.task.domain.TaskStatus.COMPLETED, com.productivityos.task.domain.TaskStatus.CANCELLED)")
    fun countByProjectIdAndUserIdAndStatusNotCompleted(projectId: UUID, userId: UUID): Long

    /**
     * Completed (terminal) tasks for a user, newest completion first. Excludes
     * soft-deleted tasks so a deleted-and-restored task keeps its completion
     * state but a never-restored deleted task does not surface in the
     * user's history (Task Management rule 15).
     */
    @Query("SELECT t FROM TaskEntity t WHERE t.userId = :userId AND t.deletedAt IS NULL AND t.status = com.productivityos.task.domain.TaskStatus.COMPLETED ORDER BY t.completedAt DESC NULLS LAST, t.createdAt DESC")
    fun findCompletedByUserId(userId: UUID, pageable: Pageable): Page<TaskEntity>

    /**
     * All non-deleted tasks belonging to a project, any lifecycle state.
     * Newest capture first so the project detail can show the project's
     * history alongside its active work (Project Management AC-005, AC-011).
     */
    @Query("SELECT t FROM TaskEntity t WHERE t.projectId = :projectId AND t.userId = :userId AND t.deletedAt IS NULL ORDER BY t.createdAt DESC")
    fun findByProjectIdAndUserId(projectId: UUID, userId: UUID): List<TaskEntity>
}
