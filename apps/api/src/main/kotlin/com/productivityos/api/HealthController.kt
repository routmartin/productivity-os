package com.productivityos.api

import org.springframework.web.bind.annotation.GetMapping
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

/**
 * Public operational health endpoint (Plan 001, Step 1).
 * This is the only public endpoint besides the authentication endpoints
 * (ADR-004).
 */
@RestController
@RequestMapping("/api/v1")
class HealthController {

    @GetMapping("/health")
    fun health(): Map<String, String> = mapOf("status" to "ok")
}
