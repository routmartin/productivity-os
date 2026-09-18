package com.productivityos.focus.service

import com.productivityos.focus.dto.StartFocusRequest
import com.productivityos.focus.persistence.FocusSessionEntity
import com.productivityos.focus.persistence.FocusSessionPauseEntity
import com.productivityos.focus.persistence.FocusSessionPauseRepository
import com.productivityos.focus.persistence.FocusSessionRepository
import com.productivityos.task.domain.TaskDeletedEvent
import com.productivityos.task.persistence.TaskRepository
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.mockito.ArgumentCaptor
import org.mockito.Mockito.`when`
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify
import java.time.Clock
import java.time.Instant
import java.time.ZoneId
import java.time.ZoneOffset
import java.util.Optional
import java.util.UUID

/**
 * Unit tests for the pause/resume and active-duration accounting (ADR-008).
 * Repositories are mocked and the [Clock] is mutable so time-based criteria are
 * deterministic.
 */
class FocusSessionServiceTest {

    private lateinit var sessionRepository: FocusSessionRepository
    private lateinit var pauseRepository: FocusSessionPauseRepository
    private lateinit var taskRepository: TaskRepository
    private lateinit var clock: MutableClock
    private lateinit var service: FocusSessionService

    private val userId = UUID.randomUUID()
    private val otherUserId = UUID.randomUUID()
    private val taskId = UUID.randomUUID()
    private val sessionId = UUID.randomUUID()
    private val t0 = Instant.parse("2026-09-01T10:00:00Z")

    @BeforeEach
    fun setUp() {
        sessionRepository = mock(FocusSessionRepository::class.java)
        pauseRepository = mock(FocusSessionPauseRepository::class.java)
        taskRepository = mock(TaskRepository::class.java)
        clock = MutableClock(t0)
        service = FocusSessionService(sessionRepository, pauseRepository, taskRepository, clock)
    }

    private fun activeSession(owner: UUID = userId, startedAt: Instant = t0) =
        FocusSessionEntity(id = sessionId, userId = owner, taskId = taskId, startedAt = startedAt)

    private fun closedPause(from: Instant, to: Instant) =
        FocusSessionPauseEntity(id = UUID.randomUUID(), sessionId = sessionId, startedAt = from, endedAt = to)

    // AC-011 / AC-015
    @Test
    fun `pause opens an interval and marks the session paused`() {
        val session = activeSession()
        val pauseStartedAt = t0.plusSeconds(300)
        clock.instant = pauseStartedAt
        `when`(sessionRepository.findById(sessionId)).thenReturn(Optional.of(session))
        `when`(pauseRepository.findOpenBySessionId(sessionId)).thenReturn(
            null,
            FocusSessionPauseEntity(sessionId = sessionId, startedAt = pauseStartedAt)
        )
        `when`(pauseRepository.findAllClosedBySessionId(sessionId)).thenReturn(emptyList())

        val response = service.pause(userId, sessionId)

        assertTrue(response.isPaused)
        assertEquals(pauseStartedAt, response.pausedAt)
        assertEquals(0L, response.accumulatedPausedSeconds)

        val captor = ArgumentCaptor.forClass(FocusSessionPauseEntity::class.java)
        verify(pauseRepository).save(captor.capture())
        assertEquals(sessionId, captor.value.sessionId)
        assertEquals(pauseStartedAt, captor.value.startedAt)
        assertNull(captor.value.endedAt)
    }

    // AC-013
    @Test
    fun `pause is rejected when the session is already paused`() {
        `when`(sessionRepository.findById(sessionId)).thenReturn(Optional.of(activeSession()))
        `when`(pauseRepository.findOpenBySessionId(sessionId)).thenReturn(
            FocusSessionPauseEntity(sessionId = sessionId, startedAt = t0)
        )

        assertThrows<IllegalArgumentException> { service.pause(userId, sessionId) }
    }

    // AC-012 / AC-015 / AC-016
    @Test
    fun `resume closes the open pause and accumulates paused seconds`() {
        val open = FocusSessionPauseEntity(id = UUID.randomUUID(), sessionId = sessionId, startedAt = t0.plusSeconds(300))
        clock.instant = t0.plusSeconds(600)
        `when`(sessionRepository.findById(sessionId)).thenReturn(Optional.of(activeSession()))
        `when`(pauseRepository.findOpenBySessionId(sessionId)).thenReturn(open, null)
        `when`(pauseRepository.findAllClosedBySessionId(sessionId)).thenReturn(listOf(open))

        val response = service.resume(userId, sessionId)

        assertFalse(response.isPaused)
        assertNull(response.pausedAt)
        assertEquals(300L, response.accumulatedPausedSeconds)
        assertEquals(t0.plusSeconds(600), open.endedAt)
        verify(pauseRepository).save(open)
    }

    // AC-014
    @Test
    fun `resume is rejected when the session is not paused`() {
        `when`(sessionRepository.findById(sessionId)).thenReturn(Optional.of(activeSession()))
        `when`(pauseRepository.findOpenBySessionId(sessionId)).thenReturn(null)

        assertThrows<IllegalArgumentException> { service.resume(userId, sessionId) }
    }

    // AC-005 / AC-017: end while paused closes the open pause and excludes it.
    @Test
    fun `end closes the open pause and persists active duration`() {
        val session = activeSession()
        val open = FocusSessionPauseEntity(id = UUID.randomUUID(), sessionId = sessionId, startedAt = t0.plusSeconds(600))
        clock.instant = t0.plusSeconds(900)
        `when`(sessionRepository.findById(sessionId)).thenReturn(Optional.of(session))
        `when`(pauseRepository.findOpenBySessionId(sessionId)).thenReturn(open, null)
        `when`(pauseRepository.findAllClosedBySessionId(sessionId)).thenReturn(listOf(open))
        `when`(taskRepository.findById(taskId)).thenReturn(Optional.empty())

        val response = service.end(userId, sessionId)

        assertEquals(t0.plusSeconds(900), open.endedAt)
        assertEquals(600L, response.durationSeconds)
        assertEquals(600L, session.durationSeconds)
        verify(sessionRepository).save(session)
    }

    // AC-005 / AC-016: several pause intervals are all excluded.
    @Test
    fun `end excludes every pause interval`() {
        val session = activeSession()
        val first = closedPause(t0.plusSeconds(300), t0.plusSeconds(420)) // 120s
        val second = closedPause(t0.plusSeconds(600), t0.plusSeconds(780)) // 180s
        clock.instant = t0.plusSeconds(1200) // 1200s wall clock
        `when`(sessionRepository.findById(sessionId)).thenReturn(Optional.of(session))
        `when`(pauseRepository.findOpenBySessionId(sessionId)).thenReturn(null)
        `when`(pauseRepository.findAllClosedBySessionId(sessionId)).thenReturn(listOf(first, second))
        `when`(taskRepository.findById(taskId)).thenReturn(Optional.empty())

        val response = service.end(userId, sessionId)

        assertEquals(900L, response.durationSeconds) // 1200 - 300
    }

    // AC-007: auto-end closes an open pause and records duration.
    @Test
    fun `auto-end on task deletion closes an open pause`() {
        val session = activeSession()
        val open = FocusSessionPauseEntity(id = UUID.randomUUID(), sessionId = sessionId, startedAt = t0.plusSeconds(600))
        clock.instant = t0.plusSeconds(900)
        `when`(sessionRepository.findActiveByUserId(userId)).thenReturn(session)
        `when`(pauseRepository.findOpenBySessionId(sessionId)).thenReturn(open, null)
        `when`(pauseRepository.findAllClosedBySessionId(sessionId)).thenReturn(listOf(open))

        service.onTaskDeleted(TaskDeletedEvent(taskId, userId))

        assertEquals(t0.plusSeconds(900), open.endedAt)
        assertEquals(t0.plusSeconds(900), session.endedAt)
        assertEquals(600L, session.durationSeconds)
        verify(sessionRepository).save(session)
    }

    // AC-008
    @Test
    fun `pause is rejected for another user's session`() {
        `when`(sessionRepository.findById(sessionId)).thenReturn(Optional.of(activeSession(owner = otherUserId)))

        assertThrows<IllegalArgumentException> { service.pause(userId, sessionId) }
    }

    // AC-002 (amended): a paused session still blocks starting a new one.
    @Test
    fun `start is rejected while a paused session is active`() {
        `when`(sessionRepository.findActiveByUserId(userId)).thenReturn(activeSession())

        assertThrows<IllegalArgumentException> {
            service.start(userId, StartFocusRequest(taskId = taskId))
        }
    }

    // AC-015: active response reports pause state.
    @Test
    fun `active session exposes pause state`() {
        val open = FocusSessionPauseEntity(id = UUID.randomUUID(), sessionId = sessionId, startedAt = t0.plusSeconds(300))
        `when`(sessionRepository.findActiveByUserId(userId)).thenReturn(activeSession())
        `when`(pauseRepository.findOpenBySessionId(sessionId)).thenReturn(open)
        `when`(pauseRepository.findAllClosedBySessionId(sessionId)).thenReturn(emptyList())
        `when`(taskRepository.findById(taskId)).thenReturn(Optional.empty())

        val response = service.getActive(userId)

        assertTrue(response!!.isActive)
        assertTrue(response.isPaused)
        assertEquals(t0.plusSeconds(300), response.pausedAt)
    }
}

/** Test clock whose instant can be advanced between assertions. */
private class MutableClock(
    var instant: Instant,
    private val zone: ZoneId = ZoneOffset.UTC
) : Clock() {
    override fun getZone(): ZoneId = zone
    override fun withZone(zone: ZoneId): Clock = MutableClock(instant, zone)
    override fun instant(): Instant = instant
}
