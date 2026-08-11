package com.productivityos.project

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
@RequestMapping("/api/v1/projects")
class ProjectController(
    private val createProjectService: CreateProjectService,
    private val activateProjectService: ActivateProjectService,
    private val completeProjectService: CompleteProjectService,
    private val archiveProjectService: ArchiveProjectService,
    private val listProjectsService: ListProjectsService,
    private val currentUser: CurrentUser
) {
    @PostMapping
    fun create(@Valid @RequestBody request: CreateProjectRequest): ResponseEntity<ProjectResponse> {
        val project = createProjectService.create(request)
        val location = URI.create("/api/v1/projects/${project.id}")
        return ResponseEntity.created(location).body(project)
    }

    @GetMapping
    fun list(): List<ProjectResponse> {
        return listProjectsService.listAll()
    }

    @GetMapping("/{id}")
    fun get(@PathVariable id: UUID): ProjectResponse {
        return listProjectsService.getById(id, currentUser.id())
    }

    @PostMapping("/{id}/activation")
    fun activate(@PathVariable id: UUID): ProjectResponse {
        return activateProjectService.activate(id, currentUser.id())
    }

    @PostMapping("/{id}/completion")
    fun complete(@PathVariable id: UUID): ProjectResponse {
        return completeProjectService.complete(id, currentUser.id())
    }

    @PostMapping("/{id}/archival")
    fun archive(@PathVariable id: UUID): ProjectResponse {
        return archiveProjectService.archive(id, currentUser.id())
    }
}
