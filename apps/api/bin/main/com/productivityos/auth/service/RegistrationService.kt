package com.productivityos.auth.service

import org.springframework.dao.DataIntegrityViolationException
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.time.ZoneId
import com.productivityos.auth.dto.RegisterRequest
import com.productivityos.auth.exception.DuplicateEmailException
import com.productivityos.user.domain.User
import com.productivityos.user.persistence.UserEntity
import com.productivityos.user.persistence.UserRepository

@Service
@Transactional
class RegistrationService(
    private val userRepository: UserRepository,
    private val passwordEncoder: PasswordEncoder,
    private val clock: Clock
) {

    fun register(request: RegisterRequest): User {
        if (userRepository.existsByEmail(request.email)) {
            throw DuplicateEmailException()
        }

        val timezone = request.timezone?.let { zone ->
            ZoneId.of(zone)
            zone
        } ?: "UTC"

        val user = UserEntity(
            email = request.email.lowercase(),
            passwordHash = passwordEncoder.encode(request.password),
            timezone = timezone,
            createdAt = clock.instant()
        )

        return try {
            userRepository.save(user).toDomain()
        } catch (e: DataIntegrityViolationException) {
            throw DuplicateEmailException()
        }
    }
}
