package com.productivityos.task.dto

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Positive
import jakarta.validation.constraints.Size
import java.time.LocalDate
import com.productivityos.task.domain.Energy
import com.productivityos.task.domain.Priority

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
