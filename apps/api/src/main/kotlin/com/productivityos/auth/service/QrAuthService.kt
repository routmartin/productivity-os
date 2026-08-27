package com.productivityos.auth.service

import com.productivityos.auth.persistence.*
import com.productivityos.auth.security.TokenHasher
import com.productivityos.auth.security.TokenService
import com.productivityos.user.persistence.UserRepository
import com.productivityos.auth.exception.AuthenticationException
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.time.Duration
import java.util.UUID
import java.security.SecureRandom
import java.util.Base64

@Service
@Transactional
class QrAuthService(
    private val qrAuthChallengeRepository: QrAuthChallengeRepository,
    private val userRepository: UserRepository,
    private val refreshTokenRepository: RefreshTokenRepository,
    private val tokenService: TokenService,
    private val clock: Clock
) {
    private val secureRandom = SecureRandom()

    fun createChallenge(userId: UUID): QrAuthChallengeEntity {
        val challenge = generateChallengeValue()
        val entity = QrAuthChallengeEntity(
            challenge = challenge,
            userId = userId,
            expiresAt = clock.instant().plus(Duration.ofMinutes(2)),
            createdAt = clock.instant()
        )
        return qrAuthChallengeRepository.save(entity)
    }

    fun exchange(challengeValue: String): LoginService.LoginResult {
        val entity = qrAuthChallengeRepository.findByChallenge(challengeValue)
            ?: throw AuthenticationException("invalid_challenge")

        if (entity.usedAt != null) {
            throw AuthenticationException("challenge_already_used")
        }

        if (clock.instant().isAfter(entity.expiresAt)) {
            // Mark as used even if expired to prevent reuse attempts
            entity.usedAt = clock.instant()
            qrAuthChallengeRepository.save(entity)
            throw AuthenticationException("challenge_expired")
        }

        entity.usedAt = clock.instant()
        qrAuthChallengeRepository.save(entity)

        val user = userRepository.findById(entity.userId).orElse(null)
            ?: throw AuthenticationException("user_not_found")

        val accessToken = tokenService.generateAccessToken(user.id!!)
        val refreshToken = tokenService.generateRefreshToken()
        val refreshTokenHash = TokenHasher.hash(refreshToken)

        val persisted = RefreshTokenEntity(
            userId = user.id,
            tokenHash = refreshTokenHash,
            deviceLabel = "iOS Device (QR Login)",
            createdAt = clock.instant(),
            expiresAt = tokenService.refreshTokenExpiry()
        )
        refreshTokenRepository.save(persisted)

        return LoginService.LoginResult(
            accessToken = accessToken,
            refreshToken = refreshToken,
            user = user.toDomain()
        )
    }

    private fun generateChallengeValue(): String {
        val bytes = ByteArray(32)
        secureRandom.nextBytes(bytes)
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes)
    }
}
