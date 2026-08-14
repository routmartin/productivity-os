package com.productivityos.task

import com.productivityos.user.CurrentUser
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
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.net.URI
import java.util.UUID

@RestController
@Tag(name = "Tasks", description = "Task lifecycle: create, plan, start, complete, cancel, reopen, delete, restore, assign to project")
@RequestMapping("/api/v1/tasks")
class TaskController(
    private val taskService: TaskService,
    private val currentUser: CurrentUser
) {
    @PostMapping
    fun create(@Valid @RequestBody request: CreateTaskRequest): ResponseEntity<TaskResponse> {
        val task = taskService.create(request)
        val location = URI.create("/api/v1/tasks/${task.id}")
        return ResponseEntity.created(location).body(task)
    }

    @GetMapping
    fun list(
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int
    ): List<TaskResponse> {
        return taskService.listActive(page, size)
    }

    @PostMapping("/{id}/plan")
    fun plan(@PathVariable id: UUID): TaskResponse {
        return taskService.plan(id, currentUser.id())
    }

    @PostMapping("/{id}/start")
    fun start(@PathVariable id: UUID): TaskResponse {
        return taskService.start(id, currentUser.id())
    }

    @PostMapping("/{id}/completion")
    fun complete(@PathVariable id: UUID): TaskResponse {
        return taskService.complete(id, currentUser.id())
    }

    @PostMapping("/{id}/cancellation")
    fun cancel(@PathVariable id: UUID): TaskResponse {
        return taskService.cancel(id, currentUser.id())
    }

    @PostMapping("/{id}/reopening")
    fun reopen(@PathVariable id: UUID): TaskResponse {
        return taskService.reopen(id, currentUser.id())
    }

    @DeleteMapping("/{id}")
    fun delete(@PathVariable id: UUID): ResponseEntity<Void> {
        taskService.delete(id, currentUser.id())
        return ResponseEntity.noContent().build()
    }

    @PostMapping("/{id}/restoration")
    fun restore(@PathVariable id: UUID): TaskResponse {
        return taskService.restore(id, currentUser.id())
    }

    @PutMapping("/{id}")
    fun update(
        @PathVariable id: UUID,
        @Valid @RequestBody request: UpdateTaskRequest
    ): TaskResponse {
        return taskService.update(id, currentUser.id(), request)
    }

    @PutMapping("/{id}/project")
    fun assignProject(@PathVariable id: UUID, @RequestBody request: AssignProjectRequest): TaskResponse {
        return taskService.assignProject(id, request.projectId, currentUser.id())
    }
}
