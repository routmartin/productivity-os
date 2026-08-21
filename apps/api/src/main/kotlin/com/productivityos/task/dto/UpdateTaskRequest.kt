package com.productivityos.task.dto

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Positive
import jakarta.validation.constraints.Size
import java.time.LocalDate
import com.productivityos.task.domain.Energy
import com.productivityos.task.domain.Priority

/**
 * Body of PUT /api/v1/tasks/{id} (amendment AC-012). Full-replace
 * semantics: the client sends the complete edited field set; an explicit
 * `null` clears a nullable field. Title is never cleared — absent or
 * blank (after @NotBlank) keeps the existing title.
 */
data class UpdateTaskRequest(
    @field:NotBlank
    @field:Size(max = 500)
    val title: String? = null,

    val description: String? = null,

    val dueDate: LocalDate? = null,

    val priority: Priority? = null,

    val energy: Energy? = null,

    @field:Positive
    val estimatedDurationMinutes: Int? = null
)
