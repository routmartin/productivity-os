package com.productivityos.user

import org.springframework.dao.DataIntegrityViolationException
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.time.ZoneId

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

        val user = User(
            email = request.email.lowercase(),
            passwordHash = passwordEncoder.encode(request.password),
            timezone = timezone,
            createdAt = clock.instant()
        )

        return try {
            userRepository.save(user)
        } catch (e: DataIntegrityViolationException) {
            throw DuplicateEmailException()
        }
    }
}
