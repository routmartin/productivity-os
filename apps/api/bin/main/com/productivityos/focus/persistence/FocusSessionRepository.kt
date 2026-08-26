package com.productivityos.focus.persistence

import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import java.util.UUID

interface FocusSessionRepository : JpaRepository<FocusSessionEntity, UUID> {

    @Query("SELECT f FROM FocusSessionEntity f WHERE f.userId = :userId AND f.endedAt IS NULL")
    fun findActiveByUserId(userId: UUID): FocusSessionEntity?

    @Query("SELECT f FROM FocusSessionEntity f WHERE f.userId = :userId ORDER BY f.startedAt DESC")
    fun findAllByUserId(userId: UUID, pageable: Pageable): Page<FocusSessionEntity>
}
