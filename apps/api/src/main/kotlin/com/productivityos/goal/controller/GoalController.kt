package com.productivityos.goal.controller

import com.productivityos.api.CurrentUser
import jakarta.validation.Valid
import org.springframework.http.ResponseEntity
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.net.URI
import java.util.UUID
import com.productivityos.goal.dto.CreateGoalRequest
import com.productivityos.goal.dto.GoalResponse
import com.productivityos.goal.dto.ReopenGoalRequest
import com.productivityos.goal.dto.UpdateGoalRequest
import com.productivityos.goal.service.GoalService

@RestController
@Tag(name = "Goals", description = "Goal lifecycle: create, update, delete, activate, return-to-draft, complete, reopen, archive")
@RequestMapping("/api/v1/goals")
class GoalController(
    private val goalService: GoalService,
    private val currentUser: CurrentUser
) {
    @PostMapping
    fun create(@Valid @RequestBody request: CreateGoalRequest): ResponseEntity<GoalResponse> {
        val goal = goalService.create(currentUser.id(), request)
        val location = URI.create("/api/v1/goals/${goal.id}")
        return ResponseEntity.created(location).body(goal)
    }

    @GetMapping
    fun list(): List<GoalResponse> {
        return goalService.listAll(currentUser.id())
    }

    @GetMapping("/{id}")
    fun get(@PathVariable id: UUID): GoalResponse {
        return goalService.getById(id, currentUser.id())
    }

    @PutMapping("/{id}")
    fun update(
        @PathVariable id: UUID,
        @Valid @RequestBody request: UpdateGoalRequest
    ): GoalResponse {
        return goalService.update(id, currentUser.id(), request)
    }

    @DeleteMapping("/{id}")
    fun delete(@PathVariable id: UUID): ResponseEntity<Void> {
        goalService.delete(id, currentUser.id())
        return ResponseEntity.noContent().build()
    }

    @PostMapping("/{id}/activation")
    fun activate(@PathVariable id: UUID): GoalResponse {
        return goalService.activate(id, currentUser.id())
    }

    @PostMapping("/{id}/return-to-draft")
    fun returnToDraft(@PathVariable id: UUID): GoalResponse {
        return goalService.returnToDraft(id, currentUser.id())
    }

    @PostMapping("/{id}/completion")
    fun complete(@PathVariable id: UUID): GoalResponse {
        return goalService.complete(id, currentUser.id())
    }

    @PostMapping("/{id}/reopening")
    fun reopen(@PathVariable id: UUID, @Valid @RequestBody request: ReopenGoalRequest): GoalResponse {
        return goalService.reopen(id, currentUser.id(), request.projectIds)
    }

    @PostMapping("/{id}/archival")
    fun archive(@PathVariable id: UUID): GoalResponse {
        return goalService.archive(id, currentUser.id())
    }
}
