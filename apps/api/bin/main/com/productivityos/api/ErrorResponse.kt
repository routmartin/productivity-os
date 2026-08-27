package com.productivityos.api

data class ErrorResponse(
    val code: String,
    val message: String,
    val details: Any? = null,
    val traceId: String
)
