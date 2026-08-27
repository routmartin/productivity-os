package com.productivityos.user.service

import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.ZoneId
import java.util.UUID
import com.productivityos.user.dto.ChangeTimezoneRequest
import com.productivityos.user.dto.UserResponse
import com.productivityos.user.persistence.UserRepository

@Service
@Transactional
class UserService(
    private val userRepository: UserRepository
) {
    fun changeTimezone(userId: UUID, request: ChangeTimezoneRequest): UserResponse {
        ZoneId.of(request.timezone)

        val user = userRepository.findById(userId).orElseThrow()
        user.timezone = request.timezone
        userRepository.save(user)

        return UserResponse(id = user.id!!, email = user.email, timezone = user.timezone)
    }
}
