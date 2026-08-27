package com.productivityos.topthree.dto

import jakarta.validation.constraints.NotNull
import java.util.UUID

data class SelectTaskRequest(
    @field:NotNull
    val taskId: UUID,

    val position: Int? = null
)
