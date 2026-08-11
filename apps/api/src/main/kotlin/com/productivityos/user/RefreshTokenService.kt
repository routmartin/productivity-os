package com.productivityos.user

import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.time.Clock
import java.util.Base64

@Service
@Transactional
class RefreshTokenService(
    private val refreshTokenRepository: RefreshTokenRepository,
    private val tokenService: TokenService,
    private val clock: Clock
) {

    data class TokenPair(
        val accessToken: String,
        val refreshToken: String
    )

    fun refresh(presentedRefreshToken: String): TokenPair {
        val tokenHash = hashToken(presentedRefreshToken)
        val stored = refreshTokenRepository.findByTokenHash(tokenHash)
            ?: throw InvalidRefreshTokenException()

        if (stored.revokedAt != null) {
            revokeFamily(stored)
            throw InvalidRefreshTokenException()
        }

        if (clock.instant().isAfter(stored.expiresAt)) {
            throw InvalidRefreshTokenException()
        }

        stored.revokedAt = clock.instant()
        refreshTokenRepository.save(stored)

        val newAccessToken = tokenService.generateAccessToken(stored.userId)
        val newRefreshToken = tokenService.generateRefreshToken()
        val newRefreshTokenHash = hashToken(newRefreshToken)

        val rotated = RefreshToken(
            userId = stored.userId,
            tokenHash = newRefreshTokenHash,
            deviceLabel = stored.deviceLabel,
            createdAt = clock.instant(),
            expiresAt = tokenService.refreshTokenExpiry(),
            rotatedFrom = stored.id
        )
        refreshTokenRepository.save(rotated)

        return TokenPair(
            accessToken = newAccessToken,
            refreshToken = newRefreshToken
        )
    }

    fun logout(refreshToken: String) {
        val tokenHash = hashToken(refreshToken)
        val stored = refreshTokenRepository.findByTokenHash(tokenHash) ?: return
        stored.revokedAt = clock.instant()
        refreshTokenRepository.save(stored)
    }

    private fun revokeFamily(token: RefreshToken) {
        var current: RefreshToken? = token
        while (current != null) {
            if (current.revokedAt == null) {
                current.revokedAt = clock.instant()
                refreshTokenRepository.save(current)
            }
            current = current.rotatedFrom?.let { rotatedFrom ->
                refreshTokenRepository.findByUserIdAndRotatedFrom(current!!.userId, rotatedFrom)
            }
        }
        var child = refreshTokenRepository.findByUserIdAndRotatedFrom(token.userId, token.id!!)
        while (child != null) {
            if (child.revokedAt == null) {
                child.revokedAt = clock.instant()
                refreshTokenRepository.save(child)
            }
            val nextChild = child.id?.let {
                refreshTokenRepository.findByUserIdAndRotatedFrom(child.userId, it)
            }
            child = nextChild
        }
    }

    private fun hashToken(token: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val hash = digest.digest(token.toByteArray(StandardCharsets.UTF_8))
        return Base64.getEncoder().encodeToString(hash)
    }
}

class InvalidRefreshTokenException : RuntimeException("Invalid refresh token")
