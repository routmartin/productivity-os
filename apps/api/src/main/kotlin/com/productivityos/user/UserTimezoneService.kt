package com.productivityos.user

import org.springframework.stereotype.Component
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID

@Component
class UserTimezoneService(
    private val userRepository: UserRepository,
    private val clock: java.time.Clock
) {
    fun timezone(userId: UUID): ZoneId {
        val user = userRepository.findById(userId).orElseThrow()
        return ZoneId.of(user.timezone)
    }

    fun today(userId: UUID): LocalDate =
        clock.instant().atZone(timezone(userId)).toLocalDate()
}
