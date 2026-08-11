package com.productivityos.user

import org.springframework.security.crypto.argon2.Argon2PasswordEncoder
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock

@Service
@Transactional
class LoginService(
    private val userRepository: UserRepository,
    private val refreshTokenRepository: RefreshTokenRepository,
    private val passwordEncoder: PasswordEncoder,
    private val tokenService: TokenService,
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
        val user = userRepository.findByEmailIgnoreCase(request.email)
        if (user == null) {
            passwordEncoder.matches(request.password, DUMMY_HASH)
            throw AuthenticationException("invalid_credentials")
        }

        if (!passwordEncoder.matches(request.password, user.passwordHash)) {
            throw AuthenticationException("invalid_credentials")
        }

        val accessToken = tokenService.generateAccessToken(user.id!!)
        val refreshToken = tokenService.generateRefreshToken()
        val refreshTokenHash = TokenHasher.hash(refreshToken)

        val persisted = RefreshToken(
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
            user = user
        )
    }
}
