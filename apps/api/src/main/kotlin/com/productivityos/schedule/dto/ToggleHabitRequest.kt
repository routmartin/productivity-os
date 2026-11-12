package com.productivityos.schedule.dto

import java.time.LocalDate

data class ToggleHabitRequest(
    val date: LocalDate? = null
)
