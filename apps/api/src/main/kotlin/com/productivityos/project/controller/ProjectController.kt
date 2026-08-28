package com.productivityos.project.controller

import com.productivityos.api.CurrentUser
import com.productivityos.task.dto.TaskResponse
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
import com.productivityos.project.dto.CreateProjectRequest
import com.productivityos.project.dto.ProjectResponse
import com.productivityos.project.dto.UpdateProjectRequest
import com.productivityos.project.service.ProjectService

@RestController
@Tag(name = "Projects", description = "Project lifecycle: create, activate, return-to-draft, complete, archive")
@RequestMapping("/api/v1/projects")
class ProjectController(
    private val projectService: ProjectService,
    private val currentUser: CurrentUser
) {
    @PostMapping
    fun create(@Valid @RequestBody request: CreateProjectRequest): ResponseEntity<ProjectResponse> {
        val project = projectService.create(currentUser.id(), request)
        val location = URI.create("/api/v1/projects/${project.id}")
        return ResponseEntity.created(location).body(project)
    }

    @GetMapping
    fun list(): List<ProjectResponse> {
        return projectService.listAll(currentUser.id())
    }

    @GetMapping("/{id}")
    fun get(@PathVariable id: UUID): ProjectResponse {
        return projectService.getById(id, currentUser.id())
    }

    /**
     * All non-deleted tasks belonging to a project (any lifecycle state).
     * Newest capture first; the project detail panel renders the full set
     * across Active / History / Cancelled sections (Project Management
     * AC-005, AC-011).
     */
    @GetMapping("/{id}/tasks")
    fun listTasks(@PathVariable id: UUID): List<TaskResponse> {
        return projectService.listTasks(id, currentUser.id())
    }

    @PutMapping("/{id}")
    fun update(
        @PathVariable id: UUID,
        @Valid @RequestBody request: UpdateProjectRequest
    ): ProjectResponse {
        return projectService.update(id, currentUser.id(), request)
    }

    @DeleteMapping("/{id}")
    fun delete(@PathVariable id: UUID): ResponseEntity<Void> {
        projectService.delete(id, currentUser.id())
        return ResponseEntity.noContent().build()
    }

    @PostMapping("/{id}/activation")
    fun activate(@PathVariable id: UUID): ProjectResponse {
        return projectService.activate(id, currentUser.id())
    }

    @PostMapping("/{id}/return-to-draft")
    fun returnToDraft(@PathVariable id: UUID): ProjectResponse {
        return projectService.returnToDraft(id, currentUser.id())
    }

    @PostMapping("/{id}/completion")
    fun complete(@PathVariable id: UUID): ProjectResponse {
        return projectService.complete(id, currentUser.id())
    }

    @PostMapping("/{id}/archival")
    fun archive(@PathVariable id: UUID): ProjectResponse {
        return projectService.archive(id, currentUser.id())
    }
}
