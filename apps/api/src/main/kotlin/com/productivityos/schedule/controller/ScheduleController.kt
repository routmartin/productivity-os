package com.productivityos.schedule.controller

import com.productivityos.api.CurrentUser
import com.productivityos.schedule.dto.AddScheduleStepRequest
import com.productivityos.schedule.dto.ScheduleGraphResponse
import com.productivityos.schedule.dto.ScheduleNodeDTO
import com.productivityos.schedule.dto.ToggleHabitRequest
import com.productivityos.schedule.dto.ToggleHabitResponse
import com.productivityos.schedule.dto.UpdateScheduleStepRequest
import com.productivityos.schedule.service.ScheduleService
import com.productivityos.user.service.UserTimezoneService
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.net.URI
import java.time.LocalDate
import java.util.UUID

@RestController
@Tag(name = "Daily Schedule", description = "Circadian link-map daily schedule and habit tracking")
@RequestMapping("/api/v1/schedule")
class ScheduleController(
    private val scheduleService: ScheduleService,
    private val currentUser: CurrentUser,
    private val userTimezoneService: UserTimezoneService
) {

    @GetMapping("/{date}")
    fun getSchedule(
        @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) date: LocalDate
    ): ResponseEntity<ScheduleGraphResponse> {
        val response = scheduleService.getSchedule(currentUser.id(), date)
        return ResponseEntity.ok(response)
    }

    @PostMapping("/habits/{id}/toggle")
    fun toggleHabit(
        @PathVariable("id") habitId: UUID,
        @RequestBody(required = false) request: ToggleHabitRequest?
    ): ResponseEntity<ToggleHabitResponse> {
        val targetDate = request?.date ?: userTimezoneService.today(currentUser.id())
        val response = scheduleService.toggleHabit(currentUser.id(), habitId, targetDate)
        return ResponseEntity.ok(response)
    }

    @PostMapping("/steps")
    fun addStep(
        @Valid @RequestBody request: AddScheduleStepRequest
    ): ResponseEntity<ScheduleNodeDTO> {
        val result = scheduleService.addStep(currentUser.id(), request)
        val location = URI.create("/api/v1/schedule/steps/${result.id}")
        return ResponseEntity.created(location).body(result)
    }

    @DeleteMapping("/steps/{id}")
    fun deleteStep(
        @PathVariable("id") id: String
    ): ResponseEntity<Void> {
        scheduleService.deleteStep(currentUser.id(), id)
        return ResponseEntity.noContent().build()
    }

    @PutMapping("/steps/{id}")
    fun updateStep(
        @PathVariable("id") id: String,
        @Valid @RequestBody request: UpdateScheduleStepRequest
    ): ResponseEntity<ScheduleNodeDTO> {
        val updated = scheduleService.updateStep(currentUser.id(), id, request)
        return ResponseEntity.ok(updated)
    }
}
