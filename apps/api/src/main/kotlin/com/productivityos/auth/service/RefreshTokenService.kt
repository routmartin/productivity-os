package com.productivityos.auth.service

import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.time.Instant
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import com.productivityos.auth.exception.InvalidRefreshTokenException
import com.productivityos.auth.persistence.RefreshTokenEntity
import com.productivityos.auth.persistence.RefreshTokenRepository
import com.productivityos.auth.security.TokenHasher
import com.productivityos.auth.security.TokenService

@Service
@Transactional
class RefreshTokenService(
    private val refreshTokenRepository: RefreshTokenRepository,
    private val tokenService: TokenService,
    private val clock: Clock,
    @Value("\${app.jwt.refresh-token-grace-period-seconds:30}")
    private val gracePeriodSeconds: Long = 30
) {

    data class TokenPair(
        val accessToken: String,
        val refreshToken: String? = null
    )

    private data class CachedRotation(
        val rawRefreshToken: String,
        val rotatedAt: Instant
    )

    private val recentRotations = ConcurrentHashMap<String, CachedRotation>()

    fun refresh(presentedRefreshToken: String): TokenPair {
        val tokenHash = TokenHasher.hash(presentedRefreshToken)
        val stored = refreshTokenRepository.findByTokenHash(tokenHash)
            ?: throw InvalidRefreshTokenException()
        if (stored.revokedAt != null) {

            val now = clock.instant()
            val isWithinGrace = now.isBefore(stored.revokedAt!!.plusSeconds(gracePeriodSeconds))
            if (isWithinGrace && stored.id != null) {
                val hasActiveChild = hasActiveDescendant(stored.userId, stored.id, now)
                if (hasActiveChild) {
                    pruneOldRotations(now)
                    val newAccessToken = tokenService.generateAccessToken(stored.userId)
                    val cachedRawToken = recentRotations[tokenHash]?.rawRefreshToken
                    return TokenPair(
                        accessToken = newAccessToken,
                        refreshToken = cachedRawToken
                    )
                }
            }
            revokeFamily(stored)
            throw InvalidRefreshTokenException()
        }

        if (clock.instant().isAfter(stored.expiresAt)) {
            throw InvalidRefreshTokenException()
        }

        val now = clock.instant()
        stored.revokedAt = now
        refreshTokenRepository.save(stored)

        val newAccessToken = tokenService.generateAccessToken(stored.userId)
        val newRefreshToken = tokenService.generateRefreshToken()
        val newRefreshTokenHash = TokenHasher.hash(newRefreshToken)

        val rotated = RefreshTokenEntity(
            userId = stored.userId,
            tokenHash = newRefreshTokenHash,
            deviceLabel = stored.deviceLabel,
            createdAt = now,
            expiresAt = tokenService.refreshTokenExpiry(),
            rotatedFrom = stored.id
        )
        refreshTokenRepository.save(rotated)

        pruneOldRotations(now)
        recentRotations[tokenHash] = CachedRotation(newRefreshToken, now)

        return TokenPair(
            accessToken = newAccessToken,
            refreshToken = newRefreshToken
        )
    }

    fun logout(refreshToken: String) {
        val tokenHash = TokenHasher.hash(refreshToken)
        val stored = refreshTokenRepository.findByTokenHash(tokenHash) ?: return
        stored.revokedAt = clock.instant()
        refreshTokenRepository.save(stored)
        recentRotations.remove(tokenHash)
    }

    fun revokeAllUserTokens(userId: UUID) {
        val activeTokens = refreshTokenRepository.findActiveByUserId(userId)
        val now = clock.instant()
        activeTokens.forEach { it.revokedAt = now }
        refreshTokenRepository.saveAll(activeTokens)
    }

    private fun pruneOldRotations(now: Instant) {
        val threshold = now.minusSeconds(gracePeriodSeconds)
        recentRotations.entries.removeIf { it.value.rotatedAt.isBefore(threshold) }
    }

    private fun hasActiveDescendant(userId: UUID, parentId: UUID, now: Instant): Boolean {
        val children = refreshTokenRepository.findAllByUserIdAndRotatedFrom(userId, parentId)
        for (child in children) {
            if (child.revokedAt == null && now.isBefore(child.expiresAt)) {
                return true
            }
            val childId = child.id
            if (childId != null && hasActiveDescendant(userId, childId, now)) {
                return true
            }
        }
        return false
    }

    private fun revokeFamily(token: RefreshTokenEntity) {
        val now = clock.instant()
        var current: RefreshTokenEntity? = token
        while (current != null) {
            if (current.revokedAt == null) {
                current.revokedAt = now
                refreshTokenRepository.save(current)
            }
            current = current.rotatedFrom?.let { parentId ->
                refreshTokenRepository.findById(parentId).orElse(null)
            }
        }
        token.id?.let { tokenId ->
            revokeDescendants(token.userId, tokenId, now)
        }
    }

    private fun revokeDescendants(userId: UUID, parentId: UUID, now: Instant) {
        val children = refreshTokenRepository.findAllByUserIdAndRotatedFrom(userId, parentId)
        for (child in children) {
            if (child.revokedAt == null) {
                child.revokedAt = now
                refreshTokenRepository.save(child)
            }
            child.id?.let { childId ->
                revokeDescendants(userId, childId, now)
            }
        }
    }
}
