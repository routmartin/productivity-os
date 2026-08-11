package com.productivityos.user

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import java.time.Instant
import java.util.UUID

interface RefreshTokenRepository : JpaRepository<RefreshToken, UUID> {

    fun findByTokenHash(tokenHash: String): RefreshToken?

    @Query("SELECT rt FROM RefreshToken rt WHERE rt.userId = :userId AND rt.rotatedFrom = :rotatedFrom")
    fun findByUserIdAndRotatedFrom(userId: UUID, rotatedFrom: UUID): RefreshToken?
}
