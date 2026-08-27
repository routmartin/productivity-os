package com.productivityos.auth.dto

import jakarta.validation.constraints.NotBlank

data class QrExchangeRequest(
    @field:NotBlank
    val challenge: String
)
