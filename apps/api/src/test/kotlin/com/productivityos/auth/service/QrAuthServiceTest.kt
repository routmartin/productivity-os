package com.productivityos.auth.service

import com.productivityos.auth.exception.AuthenticationException
import com.productivityos.auth.persistence.*
import com.productivityos.auth.security.TokenService
import com.productivityos.user.persistence.UserRepository
import com.productivityos.user.persistence.UserEntity
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.ArgumentMatchers.any
import org.mockito.Mockito.*
import java.time.Clock
import java.time.Instant
import java.time.ZoneId
import java.util.*

class QrAuthServiceTest {
    private lateinit var qrAuthChallengeRepository: QrAuthChallengeRepository
    private lateinit var userRepository: UserRepository
    private lateinit var refreshTokenRepository: RefreshTokenRepository
    private lateinit var tokenService: TokenService
    private lateinit var qrAuthService: QrAuthService
    private val clock = Clock.fixed(Instant.parse("2026-08-27T10:00:00Z"), ZoneId.of("UTC"))

    @BeforeEach
    fun setup() {
        qrAuthChallengeRepository = mock(QrAuthChallengeRepository::class.java)
        userRepository = mock(UserRepository::class.java)
        refreshTokenRepository = mock(RefreshTokenRepository::class.java)
        tokenService = mock(TokenService::class.java)
        
        qrAuthService = QrAuthService(
            qrAuthChallengeRepository,
            userRepository,
            refreshTokenRepository,
            tokenService,
            clock
        )
    }

    @Test
    fun `createChallenge should save and return a new challenge`() {
        val userId = UUID.randomUUID()
        `when`(qrAuthChallengeRepository.save(any(QrAuthChallengeEntity::class.java))).thenAnswer { it.arguments[0] }

        val challenge = qrAuthService.createChallenge(userId)

        assertNotNull(challenge.challenge)
        assertEquals(userId, challenge.userId)
        assertEquals(clock.instant().plusSeconds(120), challenge.expiresAt)
        verify(qrAuthChallengeRepository).save(any(QrAuthChallengeEntity::class.java))
    }

    @Test
    fun `exchange should succeed for valid challenge`() {
        val userId = UUID.randomUUID()
        val challengeValue = "valid-challenge"
        val challenge = QrAuthChallengeEntity(
            challenge = challengeValue,
            userId = userId,
            expiresAt = clock.instant().plusSeconds(120),
            createdAt = clock.instant()
        )
        val user = UserEntity(
            id = userId,
            email = "test@example.com",
            passwordHash = "hash",
            createdAt = clock.instant()
        )

        `when`(qrAuthChallengeRepository.findByChallenge(challengeValue)).thenReturn(challenge)
        `when`(userRepository.findById(userId)).thenReturn(Optional.of(user))
        `when`(tokenService.generateAccessToken(userId)).thenReturn("access-token")
        `when`(tokenService.generateRefreshToken()).thenReturn("refresh-token")
        `when`(tokenService.refreshTokenExpiry()).thenReturn(clock.instant().plusSeconds(3600))

        val result = qrAuthService.exchange(challengeValue)

        assertEquals("access-token", result.accessToken)
        assertEquals("refresh-token", result.refreshToken)
        assertEquals("test@example.com", result.user.email)
        assertNotNull(challenge.usedAt)
        verify(qrAuthChallengeRepository).save(challenge)
        verify(refreshTokenRepository).save(any(RefreshTokenEntity::class.java))
    }

    @Test
    fun `exchange should fail for expired challenge`() {
        val challengeValue = "expired-challenge"
        val challenge = QrAuthChallengeEntity(
            challenge = challengeValue,
            userId = UUID.randomUUID(),
            expiresAt = clock.instant().minusSeconds(1),
            createdAt = clock.instant().minusSeconds(121)
        )

        `when`(qrAuthChallengeRepository.findByChallenge(challengeValue)).thenReturn(challenge)

        val exception = assertThrows(AuthenticationException::class.java) {
            qrAuthService.exchange(challengeValue)
        }
        assertEquals("challenge_expired", exception.message)
        assertNotNull(challenge.usedAt)
        verify(qrAuthChallengeRepository).save(challenge)
    }

    @Test
    fun `exchange should fail for already used challenge`() {
        val challengeValue = "used-challenge"
        val challenge = QrAuthChallengeEntity(
            challenge = challengeValue,
            userId = UUID.randomUUID(),
            expiresAt = clock.instant().plusSeconds(120),
            createdAt = clock.instant(),
            usedAt = clock.instant().minusSeconds(10)
        )

        `when`(qrAuthChallengeRepository.findByChallenge(challengeValue)).thenReturn(challenge)

        val exception = assertThrows(AuthenticationException::class.java) {
            qrAuthService.exchange(challengeValue)
        }
        assertEquals("challenge_already_used", exception.message)
    }
}
