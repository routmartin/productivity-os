package com.productivityos.focus

import java.util.UUID

data class StartFocusRequest(
    val taskId: UUID,
    val configuredDurationSeconds: Int? = null,
    val note: String? = null
)
