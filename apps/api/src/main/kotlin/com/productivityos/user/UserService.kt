package com.productivityos.user

import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.ZoneId
import java.util.UUID

@Service
@Transactional
class UserService(
    private val userRepository: UserRepository,
    private val passwordEncoder: PasswordEncoder,
    private val refreshTokenService: RefreshTokenService
) {
    fun changePassword(userId: UUID, request: ChangePasswordRequest): UserResponse {
        val user = userRepository.findById(userId).orElseThrow()

        if (!passwordEncoder.matches(request.currentPassword, user.passwordHash)) {
            throw AuthenticationException("invalid_credentials")
        }

        user.passwordHash = passwordEncoder.encode(request.newPassword)
        userRepository.save(user)

        refreshTokenService.revokeAllUserTokens(userId)

        return UserResponse(id = user.id!!, email = user.email, timezone = user.timezone)
    }

    fun changeTimezone(userId: UUID, request: ChangeTimezoneRequest): UserResponse {
        ZoneId.of(request.timezone)

        val user = userRepository.findById(userId).orElseThrow()
        user.timezone = request.timezone
        userRepository.save(user)

        return UserResponse(id = user.id!!, email = user.email, timezone = user.timezone)
    }
}
