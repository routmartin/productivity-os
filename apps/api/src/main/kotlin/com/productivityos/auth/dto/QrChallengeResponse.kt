package com.productivityos.auth.dto

import java.time.Instant

data class QrChallengeResponse(
    val challenge: String,
    val expiresAt: Instant
)
