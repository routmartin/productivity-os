package com.productivityos.task

import com.productivityos.project.ProjectRepository
import com.productivityos.user.CurrentUser
import org.springframework.context.ApplicationEventPublisher
import org.springframework.data.domain.PageRequest
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.util.UUID

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
    fun listActive(page: Int, size: Int): List<TaskResponse> {
        val pageable = PageRequest.of(page, size)
        return taskRepository.findActiveByUserId(currentUser.id(), pageable)
            .content
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
