package com.productivityos.auth.security

import io.jsonwebtoken.Jwts
import io.jsonwebtoken.security.Keys
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import java.security.SecureRandom
import java.time.Clock
import java.time.Instant
import java.util.Base64
import java.util.Date
import java.util.UUID
import javax.crypto.SecretKey

@Service
class TokenService(
    @Value("\${app.jwt.secret}") private val jwtSecret: String,
    @Value("\${app.jwt.access-token-ttl-minutes:15}") private val accessTokenTtlMinutes: Long,
    @Value("\${app.jwt.refresh-token-ttl-days:30}") private val refreshTokenTtlDays: Long,
    private val clock: Clock
) {
    private val secretKey: SecretKey = Keys.hmacShaKeyFor(jwtSecret.toByteArray(Charsets.UTF_8))

    private val secureRandom = SecureRandom()

    fun generateAccessToken(userId: UUID): String {
        val now = clock.instant()
        return Jwts.builder()
            .issuer("productivity-os")
            .subject(userId.toString())
            .issuedAt(Date.from(now))
            .expiration(Date.from(now.plusSeconds(accessTokenTtlMinutes * 60)))
            .signWith(secretKey)
            .compact()
    }

    fun generateRefreshToken(): String {
        val bytes = ByteArray(32)
        secureRandom.nextBytes(bytes)
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes)
    }

    fun refreshTokenExpiry(): Instant =
        clock.instant().plusSeconds(refreshTokenTtlDays * 86400)

    fun validateAccessToken(token: String): UUID? {
        return try {
            val claims = Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .payload
            UUID.fromString(claims.subject)
        } catch (e: Exception) {
            null
        }
    }
}
