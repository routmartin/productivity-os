package com.productivityos.schedule.dto

import com.fasterxml.jackson.annotation.JsonAlias
import jakarta.validation.constraints.NotBlank
import java.time.LocalDate

data class AddScheduleStepRequest(
    val date: LocalDate? = null,

    @field:NotBlank
    @JsonAlias("phaseId")
    val phase: String,

    @field:NotBlank
    val type: String,

    @field:NotBlank
    val title: String,

    val subtitle: String? = null,
    val timeSlot: String? = null,

    @JsonAlias("totalMinutes")
    val durationMinutes: Int? = null,

    val iconName: String? = null
)
