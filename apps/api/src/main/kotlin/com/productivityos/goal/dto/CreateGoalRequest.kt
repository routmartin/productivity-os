package com.productivityos.goal.dto

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size
import java.time.LocalDate

data class CreateGoalRequest(
    @field:NotBlank
    @field:Size(max = 500)
    val title: String,

    val description: String? = null,

    val deadline: LocalDate? = null
)
