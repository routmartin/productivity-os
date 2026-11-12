package com.productivityos.schedule.dto

import com.fasterxml.jackson.annotation.JsonAlias
import jakarta.validation.constraints.Min
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size
import java.time.LocalDate

data class UpdateScheduleStepRequest(
    @field:NotBlank
    val title: String,

    @field:Size(max = 500)
    val subtitle: String? = null,

    val phase: String? = null,

    @field:Size(max = 32)
    val timeSlot: String? = null,

    @field:Min(1)
    @JsonAlias("totalMinutes")
    val durationMinutes: Int? = null,

    val iconName: String? = null,

    val notes: String? = null,

    val date: LocalDate? = null
)
