package com.productivityos.auth.service

import com.productivityos.auth.exception.InvalidRefreshTokenException
import com.productivityos.auth.persistence.RefreshTokenEntity
import com.productivityos.auth.persistence.RefreshTokenRepository
import com.productivityos.auth.security.TokenHasher
import com.productivityos.auth.security.TokenService
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.mockito.ArgumentMatchers.any
import org.mockito.Mockito.`when`
import org.mockito.Mockito.mock
import org.mockito.Mockito.never
import org.mockito.Mockito.verify
import java.time.Clock
import java.time.Instant
import java.time.ZoneId
import java.time.ZoneOffset
import java.util.Optional
import java.util.UUID

class RefreshTokenServiceTest {

    private class MutableClock(var currentInstant: Instant) : Clock() {
        override fun getZone(): ZoneId = ZoneOffset.UTC
        override fun withZone(zone: ZoneId?): Clock = this
        override fun instant(): Instant = currentInstant
    }

    private lateinit var refreshTokenRepository: RefreshTokenRepository
    private lateinit var tokenService: TokenService
    private lateinit var clock: MutableClock
    private lateinit var refreshTokenService: RefreshTokenService

    private val fixedInstant = Instant.parse("2026-08-26T00:00:00Z")
    private val userId = UUID.randomUUID()

    @BeforeEach
    fun setUp() {
        refreshTokenRepository = mock(RefreshTokenRepository::class.java)
        tokenService = mock(TokenService::class.java)
        clock = MutableClock(fixedInstant)
        refreshTokenService = RefreshTokenService(
            refreshTokenRepository = refreshTokenRepository,
            tokenService = tokenService,
            clock = clock,
            gracePeriodSeconds = 30L
        )
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
    fun `refresh within grace period succeeds and returns new access token and cached refresh token`() {
        val rawToken = "concurrent-refresh-token"
        val tokenHash = TokenHasher.hash(rawToken)
        val tokenId = UUID.randomUUID()
        val childTokenId = UUID.randomUUID()

        val storedEntity = RefreshTokenEntity(
            id = tokenId,
            userId = userId,
            tokenHash = tokenHash,
            createdAt = fixedInstant.minusSeconds(3600),
            expiresAt = fixedInstant.plusSeconds(86400),
            revokedAt = null
        )

        val childEntity = RefreshTokenEntity(
            id = childTokenId,
            userId = userId,
            tokenHash = "child-hash",
            createdAt = fixedInstant,
            expiresAt = fixedInstant.plusSeconds(86400 * 30),
            rotatedFrom = tokenId,
            revokedAt = null
        )

        `when`(refreshTokenRepository.findByTokenHash(tokenHash)).thenReturn(storedEntity)
        `when`(tokenService.generateAccessToken(userId)).thenReturn("access-token-1", "access-token-2")
        `when`(tokenService.generateRefreshToken()).thenReturn("cached-child-refresh-token")
        `when`(tokenService.refreshTokenExpiry()).thenReturn(fixedInstant.plusSeconds(86400 * 30))

        // Initial rotation: rotates token and caches the new child refresh token
        val initialResult = refreshTokenService.refresh(rawToken)
        assertEquals("access-token-1", initialResult.accessToken)
        assertEquals("cached-child-refresh-token", initialResult.refreshToken)

        // Advance clock by 10s (within 30-second grace window)
        clock.currentInstant = fixedInstant.plusSeconds(10)
        `when`(refreshTokenRepository.findAllByUserIdAndRotatedFrom(userId, tokenId)).thenReturn(listOf(childEntity))

        // Second concurrent request presenting the now-revoked token
        val graceResult = refreshTokenService.refresh(rawToken)

        assertEquals("access-token-2", graceResult.accessToken)
        assertEquals("cached-child-refresh-token", graceResult.refreshToken)
        assertNull(childEntity.revokedAt)
        verify(refreshTokenRepository, never()).findById(any())
    }

    @Test
    fun `refresh within grace period succeeds even if cache misses returning null refresh token`() {
        val rawToken = "cache-miss-token"
        val tokenHash = TokenHasher.hash(rawToken)
        val tokenId = UUID.randomUUID()
        val childTokenId = UUID.randomUUID()

        // Stored entity was revoked 15 seconds ago (within 30s grace window), but not cached in this process
        val storedEntity = RefreshTokenEntity(
            id = tokenId,
            userId = userId,
            tokenHash = tokenHash,
            createdAt = fixedInstant.minusSeconds(3600),
            expiresAt = fixedInstant.plusSeconds(86400),
            revokedAt = fixedInstant.minusSeconds(15)
        )

        val childEntity = RefreshTokenEntity(
            id = childTokenId,
            userId = userId,
            tokenHash = "child-hash",
            createdAt = fixedInstant.minusSeconds(15),
            expiresAt = fixedInstant.plusSeconds(86400 * 30),
            rotatedFrom = tokenId,
            revokedAt = null
        )

        `when`(refreshTokenRepository.findByTokenHash(tokenHash)).thenReturn(storedEntity)
        `when`(refreshTokenRepository.findAllByUserIdAndRotatedFrom(userId, tokenId)).thenReturn(listOf(childEntity))
        `when`(tokenService.generateAccessToken(userId)).thenReturn("grace-access-token")

        val result = refreshTokenService.refresh(rawToken)

        assertEquals("grace-access-token", result.accessToken)
        assertNull(result.refreshToken)
        assertNull(childEntity.revokedAt)
        verify(refreshTokenRepository, never()).findById(any())
    }

    @Test
    fun `refresh outside grace period triggers family revocation`() {
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

        // Revoked 35 seconds ago — outside the 30-second grace window
        val compromisedEntity = RefreshTokenEntity(
            id = tokenId,
            userId = userId,
            tokenHash = tokenHash,
            createdAt = fixedInstant.minusSeconds(3600),
            expiresAt = fixedInstant.plusSeconds(86400),
            rotatedFrom = parentId,
            revokedAt = fixedInstant.minusSeconds(35)
        )

        val childEntity = RefreshTokenEntity(
            id = childId,
            userId = userId,
            tokenHash = "child-hash",
            createdAt = fixedInstant.minusSeconds(35),
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
    fun `refresh on revoked token without active child within grace period throws InvalidRefreshTokenException`() {
        val rawToken = "logged-out-token"
        val tokenHash = TokenHasher.hash(rawToken)
        val tokenId = UUID.randomUUID()

        // Revoked 5 seconds ago (e.g. via logout), so within 30s grace window, but has no active children
        val storedEntity = RefreshTokenEntity(
            id = tokenId,
            userId = userId,
            tokenHash = tokenHash,
            createdAt = fixedInstant.minusSeconds(3600),
            expiresAt = fixedInstant.plusSeconds(86400),
            revokedAt = fixedInstant.minusSeconds(5)
        )

        `when`(refreshTokenRepository.findByTokenHash(tokenHash)).thenReturn(storedEntity)
        `when`(refreshTokenRepository.findAllByUserIdAndRotatedFrom(userId, tokenId)).thenReturn(emptyList())

        assertThrows<InvalidRefreshTokenException> {
            refreshTokenService.refresh(rawToken)
        }
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

    @Test
    fun `logout revokes token and clears rotation cache`() {
        val rawToken = "logout-token"
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

        refreshTokenService.logout(rawToken)

        assertEquals(fixedInstant, storedEntity.revokedAt)
        verify(refreshTokenRepository).save(storedEntity)
    }
}
