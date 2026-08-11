package com.productivityos.goal

import com.productivityos.user.CurrentUser
import jakarta.validation.Valid
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.net.URI
import java.util.UUID

@RestController
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

    @PostMapping("/{id}/activation")
    fun activate(@PathVariable id: UUID): GoalResponse {
        return goalService.activate(id, currentUser.id())
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
