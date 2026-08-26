package com.productivityos.focus.controller

import com.productivityos.api.CurrentUser
import jakarta.validation.Valid
import org.springframework.http.ResponseEntity
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.net.URI
import java.util.UUID
import com.productivityos.focus.dto.FocusSessionResponse
import com.productivityos.focus.dto.StartFocusRequest
import com.productivityos.focus.service.FocusSessionService

@RestController
@Tag(name = "Focus Sessions", description = "Start/end focus sessions with manual or Pomodoro mode")
@RequestMapping("/api/v1/focus")
class FocusController(
    private val focusSessionService: FocusSessionService,
    private val currentUser: CurrentUser
) {
    @GetMapping("/active")
    fun getActive(): ResponseEntity<FocusSessionResponse> {
        val session = focusSessionService.getActive(currentUser.id())
            ?: return ResponseEntity.notFound().build()
        return ResponseEntity.ok(session)
    }

    @PostMapping
    fun start(@Valid @RequestBody request: StartFocusRequest): ResponseEntity<FocusSessionResponse> {
        val session = focusSessionService.start(currentUser.id(), request)
        val location = URI.create("/api/v1/focus/${session.id}")
        return ResponseEntity.created(location).body(session)
    }

    @PostMapping("/{id}/end")
    fun end(@PathVariable id: UUID): FocusSessionResponse {
        return focusSessionService.end(currentUser.id(), id)
    }

    @GetMapping
    fun list(
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int
    ): List<FocusSessionResponse> {
        return focusSessionService.list(currentUser.id(), page, size)
    }
}
