package com.productivityos.project

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size
import java.time.LocalDate
import java.util.UUID

/**
 * Body of PUT /api/v1/projects/{id} (amendment AC-014). Full-replace
 * semantics: explicit `null` clears a nullable field (goalId, deadline,
 * description); absent or blank title keeps the existing one.
 */
data class UpdateProjectRequest(
    @field:NotBlank
    @field:Size(max = 500)
    val title: String? = null,

    val description: String? = null,

    val goalId: UUID? = null,

    val deadline: LocalDate? = null
)
