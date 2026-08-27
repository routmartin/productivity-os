package com.productivityos.auth.service

import org.springframework.security.crypto.argon2.Argon2PasswordEncoder
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import com.productivityos.auth.dto.LoginRequest
import com.productivityos.auth.exception.AuthenticationException
import com.productivityos.auth.persistence.RefreshTokenEntity
import com.productivityos.auth.persistence.RefreshTokenRepository
import com.productivityos.auth.security.TokenHasher
import com.productivityos.auth.security.TokenService
import com.productivityos.user.domain.User
import com.productivityos.user.persistence.UserRepository

@Service
@Transactional
class LoginService(
    private val userRepository: UserRepository,
    private val refreshTokenRepository: RefreshTokenRepository,
    private val passwordEncoder: PasswordEncoder,
    private val tokenService: TokenService,
    private val loginRateLimiter: LoginRateLimiter,
    private val clock: Clock
) {
    companion object {
        private val DUMMY_HASH = Argon2PasswordEncoder.defaultsForSpringSecurity_v5_8()
            .encode("this-is-a-dummy-password-for-timing-side-channel-protection")
    }

    data class LoginResult(
        val accessToken: String,
        val refreshToken: String,
        val user: User
    )

    fun login(request: LoginRequest): LoginResult {
        if (loginRateLimiter.isLocked(request.email)) {
            throw AuthenticationException("rate_limited")
        }

        val user = userRepository.findByEmailIgnoreCase(request.email)
        if (user == null) {
            loginRateLimiter.recordFailure(request.email)
            passwordEncoder.matches(request.password, DUMMY_HASH)
            throw AuthenticationException("invalid_credentials")
        }

        if (!passwordEncoder.matches(request.password, user.passwordHash)) {
            loginRateLimiter.recordFailure(request.email)
            throw AuthenticationException("invalid_credentials")
        }

        loginRateLimiter.clear(request.email)

        val accessToken = tokenService.generateAccessToken(user.id!!)
        val refreshToken = tokenService.generateRefreshToken()
        val refreshTokenHash = TokenHasher.hash(refreshToken)

        val persisted = RefreshTokenEntity(
            userId = user.id,
            tokenHash = refreshTokenHash,
            deviceLabel = null,
            createdAt = clock.instant(),
            expiresAt = tokenService.refreshTokenExpiry()
        )
        refreshTokenRepository.save(persisted)

        return LoginResult(
            accessToken = accessToken,
            refreshToken = refreshToken,
            user = user.toDomain()
        )
    }
}
