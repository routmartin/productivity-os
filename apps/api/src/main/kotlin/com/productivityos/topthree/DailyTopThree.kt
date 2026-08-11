package com.productivityos.topthree

import java.time.Instant
import java.time.LocalDate
import java.util.UUID

data class DailyTopThree(
    val id: UUID,
    val userId: UUID,
    val taskId: UUID,
    val calendarDate: LocalDate,
    val position: Int,
    val selectedAt: Instant,
    val deletedAt: Instant? = null
)
