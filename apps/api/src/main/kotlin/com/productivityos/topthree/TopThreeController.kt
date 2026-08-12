package com.productivityos.topthree

import com.productivityos.user.CurrentUser
import jakarta.validation.Valid
import org.springframework.format.annotation.DateTimeFormat
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.time.LocalDate
import java.util.UUID

@RestController
@Tag(name = "Daily Top 3", description = "Daily priorities: view, select, reorder, remove")
@RequestMapping("/api/v1/daily-top-three")
class TopThreeController(
    private val topThreeService: TopThreeService,
    private val currentUser: CurrentUser
) {
    @GetMapping("/{date}")
    fun list(
        @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) date: LocalDate
    ): List<TopThreeResponse> {
        return topThreeService.list(currentUser.id(), date)
    }

    @PostMapping("/{date}")
    fun select(
        @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) date: LocalDate,
        @Valid @RequestBody request: SelectTaskRequest
    ): ResponseEntity<TopThreeResponse> {
        val result = topThreeService.select(currentUser.id(), date, request.taskId, request.position)
        val location = java.net.URI.create("/api/v1/daily-top-three/$date/${result.id}")
        return ResponseEntity.created(location).body(result)
    }

    @PutMapping("/{date}/{selectionId}/position")
    fun reorder(
        @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) date: LocalDate,
        @PathVariable selectionId: UUID,
        @RequestBody request: ReorderRequest
    ): List<TopThreeResponse> {
        return topThreeService.reorder(currentUser.id(), date, selectionId, request.position)
    }

    @DeleteMapping("/{date}/{selectionId}")
    fun remove(
        @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) date: LocalDate,
        @PathVariable selectionId: UUID
    ): ResponseEntity<List<TopThreeResponse>> {
        val result = topThreeService.remove(currentUser.id(), date, selectionId)
        return ResponseEntity.ok(result)
    }
}
