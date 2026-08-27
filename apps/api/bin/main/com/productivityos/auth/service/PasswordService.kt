package com.productivityos.auth.service

import com.productivityos.auth.exception.AuthenticationException
import com.productivityos.auth.dto.ChangePasswordRequest
import com.productivityos.user.dto.UserResponse
import com.productivityos.user.persistence.UserRepository
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.UUID

@Service
@Transactional
class PasswordService(
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
}
