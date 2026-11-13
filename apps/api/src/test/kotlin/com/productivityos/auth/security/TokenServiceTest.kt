package com.productivityos.auth.security

import io.jsonwebtoken.Jwts
import io.jsonwebtoken.security.Keys
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Test
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import java.util.Date
import java.util.UUID

class TokenServiceTest {

    private val secret = "this-is-a-test-secret-at-least-256-bits-long-for-hmac-sha256"
    private val fixedInstant = Instant.parse("2026-08-26T12:00:00Z")
    private val clock = Clock.fixed(fixedInstant, ZoneOffset.UTC)

    @Test
    fun `generateAccessToken creates JWT with 15-minute expiration by default`() {
        val tokenService = TokenService(
            jwtSecret = secret,
            accessTokenTtlMinutes = 15L,
            refreshTokenTtlDays = 30L,
            clock = clock
        )
        val userId = UUID.randomUUID()

        val token = tokenService.generateAccessToken(userId)
        assertNotNull(token)

        val claims = Jwts.parser()
            .verifyWith(Keys.hmacShaKeyFor(secret.toByteArray(Charsets.UTF_8)))
            .clock { Date.from(fixedInstant) }
            .build()
            .parseSignedClaims(token)
            .payload

        assertEquals(userId.toString(), claims.subject)
        assertEquals("productivity-os", claims.issuer)
        assertEquals(fixedInstant.epochSecond, claims.issuedAt.toInstant().epochSecond)
        // AC-004: JWT's exp timestamp is 900 seconds (15 minutes) after its iat timestamp
        assertEquals(fixedInstant.plusSeconds(900).epochSecond, claims.expiration.toInstant().epochSecond)
    }

    @Test
    fun `validateAccessToken extracts userId correctly`() {
        val tokenService = TokenService(
            jwtSecret = secret,
            accessTokenTtlMinutes = 15L,
            refreshTokenTtlDays = 30L,
            clock = clock
        )
        val userId = UUID.randomUUID()
        val token = tokenService.generateAccessToken(userId)

        val parsedUserId = tokenService.validateAccessToken(token)
        assertEquals(userId, parsedUserId)
    }
}
