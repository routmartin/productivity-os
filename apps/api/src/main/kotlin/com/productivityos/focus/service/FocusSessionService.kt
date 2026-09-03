package com.productivityos.focus.service

import com.productivityos.task.domain.TaskCancelledEvent
import com.productivityos.task.domain.TaskDeletedEvent
import com.productivityos.task.persistence.TaskRepository
import com.productivityos.task.domain.TaskStatus
import org.springframework.context.event.EventListener
import org.springframework.data.domain.PageRequest
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.util.UUID
import com.productivityos.focus.dto.FocusSessionResponse
import com.productivityos.focus.dto.StartFocusRequest
import com.productivityos.focus.persistence.FocusSessionEntity
import com.productivityos.focus.persistence.FocusSessionRepository

@Service
@Transactional
class FocusSessionService(
    private val focusSessionRepository: FocusSessionRepository,
    private val taskRepository: TaskRepository,
    private val clock: Clock
) {
    fun start(userId: UUID, request: StartFocusRequest): FocusSessionResponse {
        val active = focusSessionRepository.findActiveByUserId(userId)
        require(active == null) { "You already have an active focus session" }

        val task = taskRepository.findById(request.taskId).orElse(null)
            ?: throw NoSuchElementException("Task not found: ${request.taskId}")
        require(task.userId == userId) { "Task does not belong to the current user" }
        require(task.deletedAt == null) { "Task is deleted" }
        require(task.status in setOf(TaskStatus.INBOX, TaskStatus.PLANNED, TaskStatus.IN_PROGRESS)) {
            "Task must be INBOX, PLANNED, or IN_PROGRESS to start a focus session"
        }

        if (task.status != TaskStatus.IN_PROGRESS) {
            task.status = TaskStatus.IN_PROGRESS
            task.updatedAt = clock.instant()
            taskRepository.save(task)
        }

        val entity = FocusSessionEntity(
            userId = userId,
            taskId = request.taskId,
            startedAt = clock.instant(),
            configuredDurationSeconds = request.configuredDurationSeconds,
            note = request.note
        )
        val saved = focusSessionRepository.save(entity)
        return FocusSessionResponse.from(saved, task.title)
    }

    fun end(userId: UUID, sessionId: UUID): FocusSessionResponse {
        val entity = focusSessionRepository.findById(sessionId).orElse(null)
            ?: throw NoSuchElementException("Session not found: ${sessionId}")
        require(entity.userId == userId) { "Session does not belong to the current user" }
        require(entity.endedAt == null) { "Session is already ended" }

        entity.endedAt = clock.instant()
        entity.durationSeconds = entity.endedAt!!.epochSecond - entity.startedAt.epochSecond
        focusSessionRepository.save(entity)

        val task = taskRepository.findById(entity.taskId).orElse(null)
        if (task != null && task.userId == userId && task.deletedAt == null && task.status == TaskStatus.IN_PROGRESS) {
            task.status = TaskStatus.PLANNED
            task.updatedAt = clock.instant()
            taskRepository.save(task)
        }
        return FocusSessionResponse.from(entity, task?.title)
    }

    @Transactional(readOnly = true)
    fun getActive(userId: UUID): FocusSessionResponse? {
        val entity = focusSessionRepository.findActiveByUserId(userId) ?: return null
        val task = taskRepository.findById(entity.taskId).orElse(null)
        return FocusSessionResponse.from(entity, task?.title)
    }

    @Transactional(readOnly = true)
    fun list(userId: UUID, page: Int, size: Int): List<FocusSessionResponse> {
        val pageable = PageRequest.of(page, size)
        return focusSessionRepository.findAllByUserId(userId, pageable)
            .content
            .map { entity ->
                val task = taskRepository.findById(entity.taskId).orElse(null)
                FocusSessionResponse.from(entity, task?.title)
            }
    }

    @EventListener
    fun onTaskDeleted(event: TaskDeletedEvent) {
        autoEndActiveSession(event.taskId, event.userId)
    }

    @EventListener
    fun onTaskCancelled(event: TaskCancelledEvent) {
        autoEndActiveSession(event.taskId, event.userId)
    }

    private fun autoEndActiveSession(taskId: UUID, userId: UUID) {
        val active = focusSessionRepository.findActiveByUserId(userId)
        if (active != null && active.taskId == taskId) {
            active.endedAt = clock.instant()
            active.durationSeconds = active.endedAt!!.epochSecond - active.startedAt.epochSecond
            focusSessionRepository.save(active)
        }
    }
}
