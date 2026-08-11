package com.productivityos.task

import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import java.util.UUID

interface TaskRepository : JpaRepository<TaskEntity, UUID> {

    @Query("SELECT t FROM TaskEntity t WHERE t.userId = :userId AND t.deletedAt IS NULL AND t.status NOT IN (com.productivityos.task.TaskStatus.COMPLETED, com.productivityos.task.TaskStatus.CANCELLED) ORDER BY t.createdAt DESC")
    fun findActiveByUserId(userId: UUID, pageable: Pageable): org.springframework.data.domain.Page<TaskEntity>
}
