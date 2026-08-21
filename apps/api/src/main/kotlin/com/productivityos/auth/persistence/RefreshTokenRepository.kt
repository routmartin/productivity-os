package com.productivityos.auth.persistence

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import java.time.Instant
import java.util.UUID

interface RefreshTokenRepository : JpaRepository<RefreshTokenEntity, UUID> {

    fun findByTokenHash(tokenHash: String): RefreshTokenEntity?

    @Query("SELECT rt FROM RefreshTokenEntity rt WHERE rt.userId = :userId AND rt.revokedAt IS NULL")
    fun findActiveByUserId(userId: UUID): List<RefreshTokenEntity>

    @Query("SELECT rt FROM RefreshTokenEntity rt WHERE rt.userId = :userId AND rt.rotatedFrom = :rotatedFrom")
    fun findByUserIdAndRotatedFrom(userId: UUID, rotatedFrom: UUID): RefreshTokenEntity?
}
