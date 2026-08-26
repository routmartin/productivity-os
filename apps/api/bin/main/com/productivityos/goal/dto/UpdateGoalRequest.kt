package com.productivityos.goal.dto

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size
import java.time.LocalDate

/**
 * Body of PUT /api/v1/goals/{id} (amendment AC-016). Full-replace
 * semantics: explicit `null` clears a nullable field (description,
 * deadline); absent or blank title keeps the existing one.
 */
data class UpdateGoalRequest(
    @field:NotBlank
    @field:Size(max = 500)
    val title: String? = null,

    val description: String? = null,

    val deadline: LocalDate? = null
)
