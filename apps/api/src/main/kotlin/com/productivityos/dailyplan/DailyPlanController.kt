package com.productivityos.dailyplan

import com.productivityos.user.CurrentUser
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
@RequestMapping("/api/v1/daily-plan")
class DailyPlanController(
    private val dailyPlanService: DailyPlanService,
    private val currentUser: CurrentUser
) {
    @GetMapping("/{date}")
    fun list(
        @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) date: LocalDate
    ): List<DailyPlanResponse> {
        return dailyPlanService.list(currentUser.id(), date)
    }

    @PostMapping("/{date}")
    fun plan(
        @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) date: LocalDate,
        @Valid @RequestBody request: PlanTaskRequest
    ): ResponseEntity<DailyPlanResponse> {
        val result = dailyPlanService.plan(currentUser.id(), date, request)
        val location = URI.create("/api/v1/daily-plan/$date/${result.id}")
        return ResponseEntity.created(location).body(result)
    }

    @DeleteMapping("/{date}/{planId}")
    fun remove(
        @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) date: LocalDate,
        @PathVariable planId: UUID
    ): ResponseEntity<Void> {
        dailyPlanService.remove(currentUser.id(), date, planId)
        return ResponseEntity.noContent().build()
    }

    @PutMapping("/capacity/{date}")
    fun setCapacity(
        @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) date: LocalDate,
        @RequestBody request: SetCapacityRequest
    ): ResponseEntity<Void> {
        dailyPlanService.setCapacity(currentUser.id(), date, request.hours)
        return ResponseEntity.ok().build()
    }

    @GetMapping("/{date}/capacity")
    fun getCapacity(
        @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) date: LocalDate
    ): CapacityInfo {
        return dailyPlanService.getCapacityInfo(currentUser.id(), date)
    }
}
