package com.productivityos.user.dto

import com.productivityos.user.domain.User
import java.util.UUID

data class UserResponse(
    val id: UUID,
    val email: String,
    val timezone: String
) {
    companion object {
        fun from(user: User): UserResponse =
            UserResponse(id = user.id, email = user.email, timezone = user.timezone)
    }
}
