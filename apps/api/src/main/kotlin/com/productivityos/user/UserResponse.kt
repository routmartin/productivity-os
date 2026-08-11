package com.productivityos.user

import java.util.UUID

data class UserResponse(
    val id: UUID,
    val email: String,
    val timezone: String
)
