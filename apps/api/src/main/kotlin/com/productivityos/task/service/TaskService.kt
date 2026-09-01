package com.productivityos.task.service

import com.productivityos.project.persistence.ProjectRepository
import com.productivityos.api.CurrentUser
import org.springframework.context.ApplicationEventPublisher
import org.springframework.data.domain.PageRequest
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.util.UUID
import com.productivityos.task.domain.TaskCancelledEvent
import com.productivityos.task.domain.TaskCompletedEvent
import com.productivityos.task.domain.TaskDeletedEvent
import com.productivityos.task.domain.TaskRestoredEvent
import com.productivityos.task.domain.TaskStatus
import com.productivityos.task.dto.CreateTaskRequest
import com.productivityos.task.dto.TaskResponse
import com.productivityos.task.dto.UpdateTaskRequest
import com.productivityos.task.exception.TaskNotFoundException
import com.productivityos.task.persistence.TaskEntity
import com.productivityos.task.persistence.TaskRepository

@Service
@Transactional
class TaskService(
    private val taskRepository: TaskRepository,
    private val projectRepository: ProjectRepository,
    private val eventPublisher: ApplicationEventPublisher,
    private val currentUser: CurrentUser,
    private val clock: Clock
) {
    fun create(request: CreateTaskRequest): TaskResponse {
        val now = clock.instant()
        val entity = TaskEntity.from(
            ownerId = currentUser.id(),
            title = request.title,
            description = request.description,
            dueDate = request.dueDate,
            priority = request.priority,
            energy = request.energy,
            estimatedDurationMinutes = request.estimatedDurationMinutes,
            now = now
        )
        return TaskResponse.from(taskRepository.save(entity))
    }

    @Transactional(readOnly = true)
    fun listAll(page: Int, size: Int): List<TaskResponse> {
        val pageable = PageRequest.of(page, size)
        return taskRepository.findAllByUserId(currentUser.id(), pageable)
            .content
            .map { TaskResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun listActive(page: Int, size: Int): List<TaskResponse> {
        val pageable = PageRequest.of(page, size)
        return taskRepository.findActiveByUserId(currentUser.id(), pageable)
            .content
            .map { TaskResponse.from(it) }
    }

    /**
     * Completed (terminal) tasks for the current user, newest completion
     * first. The page is the user's task history; the frontend mirrors it
     * for the project detail "History" section and the tasks page
     * "Completed" filter.
     */
    @Transactional(readOnly = true)
    fun listCompleted(page: Int, size: Int): List<TaskResponse> {
        val pageable = PageRequest.of(page, size)
        return taskRepository.findCompletedByUserId(currentUser.id(), pageable)
            .content
            .map { TaskResponse.from(it) }
    }

    /**
     * All non-deleted tasks belonging to a project (any lifecycle state).
     * Used by the project detail panel to render the full task set
     * (active, completed, cancelled) so the project page lists every task
     * within it (Project Management AC-005, AC-011).
     */
    @Transactional(readOnly = true)
    fun listForProject(projectId: UUID, userId: UUID): List<TaskResponse> {
        val project = projectRepository.findById(projectId).orElse(null)
            ?: throw NoSuchElementException("Project not found: $projectId")
        require(project.userId == userId) { "Project does not belong to the current user" }
        return taskRepository.findByProjectIdAndUserId(projectId, userId)
            .map { TaskResponse.from(it) }
    }

    fun plan(taskId: UUID, userId: UUID): TaskResponse {
        val entity = loadOwned(taskId, userId)
        entity.toDomain().plan()
        entity.status = TaskStatus.PLANNED
        entity.updatedAt = clock.instant()
        return TaskResponse.from(taskRepository.save(entity))
    }

    fun start(taskId: UUID, userId: UUID): TaskResponse {
        val entity = loadOwned(taskId, userId)
        entity.toDomain().start()
        entity.status = TaskStatus.IN_PROGRESS
        entity.updatedAt = clock.instant()
        return TaskResponse.from(taskRepository.save(entity))
    }

    fun complete(taskId: UUID, userId: UUID): TaskResponse {
        val entity = loadOwned(taskId, userId)
        val completed = entity.toDomain().complete(clock.instant())
        entity.status = TaskStatus.COMPLETED
        entity.completedAt = completed.completedAt
        entity.updatedAt = clock.instant()
        taskRepository.save(entity)
        eventPublisher.publishEvent(TaskCompletedEvent(taskId, userId))
        return TaskResponse.from(entity)
    }

    fun cancel(taskId: UUID, userId: UUID): TaskResponse {
        val entity = loadOwned(taskId, userId)
        entity.toDomain().cancel()
        entity.status = TaskStatus.CANCELLED
        entity.updatedAt = clock.instant()
        taskRepository.save(entity)
        eventPublisher.publishEvent(TaskCancelledEvent(taskId, userId))
        return TaskResponse.from(entity)
    }

    fun reopen(taskId: UUID, userId: UUID): TaskResponse {
        val entity = loadOwned(taskId, userId)
        entity.toDomain().reopen()
        entity.status = TaskStatus.PLANNED
        entity.updatedAt = clock.instant()
        return TaskResponse.from(taskRepository.save(entity))
    }

    fun update(taskId: UUID, userId: UUID, request: UpdateTaskRequest): TaskResponse {
        val entity = loadOwned(taskId, userId)
        request.title?.let { entity.title = it }
        entity.description = request.description
        entity.dueDate = request.dueDate
        entity.priority = request.priority
        entity.energy = request.energy
        entity.estimatedDurationMinutes = request.estimatedDurationMinutes
        entity.updatedAt = clock.instant()
        return TaskResponse.from(taskRepository.save(entity))
    }

    fun delete(taskId: UUID, userId: UUID) {
        val entity = loadOwned(taskId, userId)
        require(entity.deletedAt == null) { "Task is already deleted" }
        entity.deletedAt = clock.instant()
        entity.updatedAt = clock.instant()
        taskRepository.save(entity)
        eventPublisher.publishEvent(TaskDeletedEvent(taskId, userId))
    }

    fun restore(taskId: UUID, userId: UUID): TaskResponse {
        val entity = loadOwned(taskId, userId)
        require(entity.deletedAt != null) { "Task is not deleted" }
        entity.deletedAt = null
        entity.updatedAt = clock.instant()
        taskRepository.save(entity)
        eventPublisher.publishEvent(TaskRestoredEvent(taskId, userId))
        return TaskResponse.from(entity)
    }

    fun assignProject(taskId: UUID, projectId: UUID?, userId: UUID): TaskResponse {
        val entity = loadOwned(taskId, userId)
        if (projectId != null) {
            val project = projectRepository.findById(projectId).orElse(null)
                ?: throw NoSuchElementException("Project not found: $projectId")
            require(project.userId == userId) { "Project does not belong to the current user" }
        }
        entity.projectId = projectId
        entity.updatedAt = clock.instant()
        return TaskResponse.from(taskRepository.save(entity))
    }

    private fun loadOwned(taskId: UUID, userId: UUID): TaskEntity {
        val entity = taskRepository.findById(taskId).orElse(null)
            ?: throw TaskNotFoundException(taskId)
        require(entity.userId == userId) { "Task does not belong to the current user" }
        return entity
    }
}
