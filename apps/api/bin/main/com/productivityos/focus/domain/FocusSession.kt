package com.productivityos.focus.domain

import java.time.Instant
import java.util.UUID

data class FocusSession(
    val id: UUID,
    val userId: UUID,
    val taskId: UUID,
    val startedAt: Instant,
    val endedAt: Instant? = null,
    val configuredDurationSeconds: Int? = null,
    val note: String? = null
)
