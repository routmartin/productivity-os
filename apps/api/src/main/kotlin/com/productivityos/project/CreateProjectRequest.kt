package com.productivityos.project

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size
import java.time.LocalDate
import java.util.UUID

data class CreateProjectRequest(
    @field:NotBlank
    @field:Size(max = 500)
    val title: String,

    val description: String? = null,

    val goalId: UUID? = null,

    val deadline: LocalDate? = null
)
