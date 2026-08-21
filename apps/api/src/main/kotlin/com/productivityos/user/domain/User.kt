package com.productivityos.user.domain

import java.time.Instant
import java.util.UUID

data class User(
    val id: UUID,
    val email: String,
    val timezone: String,
    val createdAt: Instant
)
