package com.productivityos.auth.service

import com.productivityos.auth.exception.InvalidRefreshTokenException
import com.productivityos.auth.persistence.RefreshTokenEntity
import com.productivityos.auth.persistence.RefreshTokenRepository
import com.productivityos.auth.security.TokenHasher
import com.productivityos.auth.security.TokenService
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.mockito.Mockito.`when`
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import java.util.Optional
import java.util.UUID

class RefreshTokenServiceTest {

    private lateinit var refreshTokenRepository: RefreshTokenRepository
    private lateinit var tokenService: TokenService
    private lateinit var clock: Clock
    private lateinit var refreshTokenService: RefreshTokenService

    private val fixedInstant = Instant.parse("2026-08-26T00:00:00Z")
    private val userId = UUID.randomUUID()

    @BeforeEach
    fun setUp() {
        refreshTokenRepository = mock(RefreshTokenRepository::class.java)
        tokenService = mock(TokenService::class.java)
        clock = Clock.fixed(fixedInstant, ZoneOffset.UTC)
        refreshTokenService = RefreshTokenService(refreshTokenRepository, tokenService, clock)
    }

    @Test
    fun `refresh successfully rotates valid token`() {
        val rawToken = "valid-refresh-token"
        val tokenHash = TokenHasher.hash(rawToken)
        val tokenId = UUID.randomUUID()
        val storedEntity = RefreshTokenEntity(
            id = tokenId,
            userId = userId,
            tokenHash = tokenHash,
            createdAt = fixedInstant.minusSeconds(3600),
            expiresAt = fixedInstant.plusSeconds(86400),
            revokedAt = null
        )

        `when`(refreshTokenRepository.findByTokenHash(tokenHash)).thenReturn(storedEntity)
        `when`(tokenService.generateAccessToken(userId)).thenReturn("new-access-token")
        `when`(tokenService.generateRefreshToken()).thenReturn("new-refresh-token")
        `when`(tokenService.refreshTokenExpiry()).thenReturn(fixedInstant.plusSeconds(86400 * 30))

        val result = refreshTokenService.refresh(rawToken)

        assertEquals("new-access-token", result.accessToken)
        assertEquals("new-refresh-token", result.refreshToken)
        assertEquals(fixedInstant, storedEntity.revokedAt)
        verify(refreshTokenRepository).save(storedEntity)
    }

    @Test
    fun `refresh on already revoked token triggers family revocation`() {
        val rawToken = "compromised-token"
        val tokenHash = TokenHasher.hash(rawToken)
        val parentId = UUID.randomUUID()
        val tokenId = UUID.randomUUID()
        val childId = UUID.randomUUID()

        val parentEntity = RefreshTokenEntity(
            id = parentId,
            userId = userId,
            tokenHash = "parent-hash",
            createdAt = fixedInstant.minusSeconds(7200),
            expiresAt = fixedInstant.plusSeconds(86400),
            revokedAt = null
        )

        val compromisedEntity = RefreshTokenEntity(
            id = tokenId,
            userId = userId,
            tokenHash = tokenHash,
            createdAt = fixedInstant.minusSeconds(3600),
            expiresAt = fixedInstant.plusSeconds(86400),
            rotatedFrom = parentId,
            revokedAt = fixedInstant.minusSeconds(1800)
        )

        val childEntity = RefreshTokenEntity(
            id = childId,
            userId = userId,
            tokenHash = "child-hash",
            createdAt = fixedInstant.minusSeconds(1800),
            expiresAt = fixedInstant.plusSeconds(86400),
            rotatedFrom = tokenId,
            revokedAt = null
        )

        `when`(refreshTokenRepository.findByTokenHash(tokenHash)).thenReturn(compromisedEntity)
        `when`(refreshTokenRepository.findById(parentId)).thenReturn(Optional.of(parentEntity))
        `when`(refreshTokenRepository.findAllByUserIdAndRotatedFrom(userId, tokenId)).thenReturn(listOf(childEntity))
        `when`(refreshTokenRepository.findAllByUserIdAndRotatedFrom(userId, childId)).thenReturn(emptyList())

        assertThrows<InvalidRefreshTokenException> {
            refreshTokenService.refresh(rawToken)
        }

        assertEquals(fixedInstant, parentEntity.revokedAt)
        assertEquals(fixedInstant, childEntity.revokedAt)
        verify(refreshTokenRepository).save(parentEntity)
        verify(refreshTokenRepository).save(childEntity)
    }

    @Test
    fun `refresh on expired token throws InvalidRefreshTokenException`() {
        val rawToken = "expired-token"
        val tokenHash = TokenHasher.hash(rawToken)
        val expiredEntity = RefreshTokenEntity(
            id = UUID.randomUUID(),
            userId = userId,
            tokenHash = tokenHash,
            createdAt = fixedInstant.minusSeconds(86400 * 35),
            expiresAt = fixedInstant.minusSeconds(86400 * 5),
            revokedAt = null
        )

        `when`(refreshTokenRepository.findByTokenHash(tokenHash)).thenReturn(expiredEntity)

        assertThrows<InvalidRefreshTokenException> {
            refreshTokenService.refresh(rawToken)
        }
    }
}
