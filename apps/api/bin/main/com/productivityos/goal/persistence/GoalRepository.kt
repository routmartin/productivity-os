package com.productivityos.goal.persistence

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import java.util.UUID

interface GoalRepository : JpaRepository<GoalEntity, UUID> {

    @Query("SELECT g FROM GoalEntity g WHERE g.userId = :userId ORDER BY g.createdAt DESC")
    fun findAllByUserId(userId: UUID): List<GoalEntity>
}
