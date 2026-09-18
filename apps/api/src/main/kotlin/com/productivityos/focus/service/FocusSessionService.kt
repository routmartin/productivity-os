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
import java.time.Duration
import java.time.Instant
import java.util.UUID
import com.productivityos.focus.dto.FocusSessionResponse
import com.productivityos.focus.dto.StartFocusRequest
import com.productivityos.focus.persistence.FocusSessionEntity
import com.productivityos.focus.persistence.FocusSessionPauseEntity
import com.productivityos.focus.persistence.FocusSessionPauseRepository
import com.productivityos.focus.persistence.FocusSessionRepository

/**
 * Records focus sessions and their pause intervals (ADR-008).
 *
 * Recorded duration is active focus time:
 * `duration = max(0, (ended_at - started_at) - sum(pause intervals))`.
 * All instants are server-authoritative via the injectable [Clock] (ADR-006).
 */
@Service
@Transactional
class FocusSessionService(
    private val focusSessionRepository: FocusSessionRepository,
    private val focusSessionPauseRepository: FocusSessionPauseRepository,
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
        return toResponse(saved, task.title)
    }

    /** Pauses an active, running session (AC-011). */
    fun pause(userId: UUID, sessionId: UUID): FocusSessionResponse {
        val entity = requireActiveOwnedSession(userId, sessionId)
        require(focusSessionPauseRepository.findOpenBySessionId(sessionId) == null) {
            "Session is already paused"
        }
        focusSessionPauseRepository.save(
            FocusSessionPauseEntity(sessionId = sessionId, startedAt = clock.instant())
        )
        return toResponse(entity, taskTitle(entity))
    }

    /** Resumes an active, paused session (AC-012). */
    fun resume(userId: UUID, sessionId: UUID): FocusSessionResponse {
        val entity = requireActiveOwnedSession(userId, sessionId)
        val open = focusSessionPauseRepository.findOpenBySessionId(sessionId)
            ?: throw IllegalArgumentException("Session is not paused")
        open.endedAt = clock.instant()
        focusSessionPauseRepository.save(open)
        return toResponse(entity, taskTitle(entity))
    }

    fun end(userId: UUID, sessionId: UUID): FocusSessionResponse {
        val entity = focusSessionRepository.findById(sessionId).orElse(null)
            ?: throw NoSuchElementException("Session not found: $sessionId")
        require(entity.userId == userId) { "Session does not belong to the current user" }
        require(entity.endedAt == null) { "Session is already ended" }

        val endedAt = clock.instant()
        closeOpenPause(sessionId, endedAt)
        entity.endedAt = endedAt
        entity.durationSeconds = activeDurationSeconds(entity.id!!, entity.startedAt, endedAt)
        focusSessionRepository.save(entity)

        val task = taskRepository.findById(entity.taskId).orElse(null)
        if (task != null && task.userId == userId && task.deletedAt == null && task.status == TaskStatus.IN_PROGRESS) {
            task.status = TaskStatus.PLANNED
            task.updatedAt = clock.instant()
            taskRepository.save(task)
        }
        return toResponse(entity, task?.title)
    }

    @Transactional(readOnly = true)
    fun getActive(userId: UUID): FocusSessionResponse? {
        val entity = focusSessionRepository.findActiveByUserId(userId) ?: return null
        return toResponse(entity, taskTitle(entity))
    }

    @Transactional(readOnly = true)
    fun list(userId: UUID, page: Int, size: Int): List<FocusSessionResponse> {
        val pageable = PageRequest.of(page, size)
        return focusSessionRepository.findAllByUserId(userId, pageable)
            .content
            .map { entity -> toResponse(entity, taskTitle(entity)) }
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
            val endedAt = clock.instant()
            closeOpenPause(active.id!!, endedAt)
            active.endedAt = endedAt
            active.durationSeconds = activeDurationSeconds(active.id!!, active.startedAt, endedAt)
            focusSessionRepository.save(active)
        }
    }

    // MARK: - Helpers

    private fun requireActiveOwnedSession(userId: UUID, sessionId: UUID): FocusSessionEntity {
        val entity = focusSessionRepository.findById(sessionId).orElse(null)
            ?: throw NoSuchElementException("Session not found: $sessionId")
        require(entity.userId == userId) { "Session does not belong to the current user" }
        require(entity.endedAt == null) { "Session is already ended" }
        return entity
    }

    private fun closeOpenPause(sessionId: UUID, at: Instant) {
        val open = focusSessionPauseRepository.findOpenBySessionId(sessionId) ?: return
        open.endedAt = at
        focusSessionPauseRepository.save(open)
    }

    /** Active focus seconds: wall-clock elapsed minus every pause interval. */
    private fun activeDurationSeconds(sessionId: UUID, startedAt: Instant, endedAt: Instant): Long {
        val pausedSeconds = focusSessionPauseRepository.findAllClosedBySessionId(sessionId)
            .sumOf { Duration.between(it.startedAt, it.endedAt!!).seconds }
        val wallClockSeconds = Duration.between(startedAt, endedAt).seconds
        return maxOf(0L, wallClockSeconds - pausedSeconds)
    }

    private fun accumulatedPausedSeconds(sessionId: UUID): Long =
        focusSessionPauseRepository.findAllClosedBySessionId(sessionId)
            .sumOf { Duration.between(it.startedAt, it.endedAt!!).seconds }

    private fun taskTitle(entity: FocusSessionEntity): String? =
        taskRepository.findById(entity.taskId).orElse(null)?.title

    private fun toResponse(entity: FocusSessionEntity, taskTitle: String?): FocusSessionResponse {
        val open = focusSessionPauseRepository.findOpenBySessionId(entity.id!!)
        return FocusSessionResponse.from(
            entity = entity,
            taskTitle = taskTitle,
            isPaused = open != null,
            pausedAt = open?.startedAt,
            accumulatedPausedSeconds = accumulatedPausedSeconds(entity.id)
        )
    }
}
