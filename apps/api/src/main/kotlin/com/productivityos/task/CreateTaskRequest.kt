package com.productivityos.task

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Positive
import jakarta.validation.constraints.Size
import java.time.LocalDate

data class CreateTaskRequest(
    @field:NotBlank
    @field:Size(max = 500)
    val title: String,

    val description: String? = null,

    val dueDate: LocalDate? = null,

    val priority: Priority? = null,

    val energy: Energy? = null,

    @field:Positive
    val estimatedDurationMinutes: Int? = null
)
