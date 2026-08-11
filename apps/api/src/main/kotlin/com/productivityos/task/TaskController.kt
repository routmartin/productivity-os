package com.productivityos.task

import com.productivityos.user.CurrentUser
import jakarta.validation.Valid
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.net.URI
import java.util.UUID

@RestController
@RequestMapping("/api/v1/tasks")
class TaskController(
    private val createTaskService: CreateTaskService,
    private val listTasksService: ListTasksService,
    private val transitionTaskService: TransitionTaskService,
    private val completeTaskService: CompleteTaskService,
    private val cancelTaskService: CancelTaskService,
    private val reopenTaskService: ReopenTaskService,
    private val deleteTaskService: DeleteTaskService,
    private val restoreTaskService: RestoreTaskService,
    private val currentUser: CurrentUser
) {

    @PostMapping
    fun create(@Valid @RequestBody request: CreateTaskRequest): ResponseEntity<TaskResponse> {
        val task = createTaskService.create(request)
        val location = URI.create("/api/v1/tasks/${task.id}")
        return ResponseEntity.created(location).body(task)
    }

    @GetMapping
    fun list(
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int
    ): List<TaskResponse> {
        return listTasksService.listActive(page, size)
    }

    @PostMapping("/{id}/plan")
    fun plan(@PathVariable id: UUID): TaskResponse {
        return transitionTaskService.plan(id, currentUser.id())
    }

    @PostMapping("/{id}/start")
    fun start(@PathVariable id: UUID): TaskResponse {
        return transitionTaskService.start(id, currentUser.id())
    }

    @PostMapping("/{id}/completion")
    fun complete(@PathVariable id: UUID): TaskResponse {
        return completeTaskService.complete(id, currentUser.id())
    }

    @PostMapping("/{id}/cancellation")
    fun cancel(@PathVariable id: UUID): TaskResponse {
        return cancelTaskService.cancel(id, currentUser.id())
    }

    @PostMapping("/{id}/reopening")
    fun reopen(@PathVariable id: UUID): TaskResponse {
        return reopenTaskService.reopen(id, currentUser.id())
    }

    @DeleteMapping("/{id}")
    fun delete(@PathVariable id: UUID): ResponseEntity<Void> {
        deleteTaskService.delete(id, currentUser.id())
        return ResponseEntity.noContent().build()
    }

    @PostMapping("/{id}/restoration")
    fun restore(@PathVariable id: UUID): TaskResponse {
        return restoreTaskService.restore(id, currentUser.id())
    }
}
