package com.productivityos.task.service

import com.productivityos.api.CurrentUser
import com.productivityos.project.persistence.ProjectRepository
import com.productivityos.task.domain.TaskStatus
import com.productivityos.task.domain.TaskUncompletedEvent
import com.productivityos.task.persistence.TaskEntity
import com.productivityos.task.persistence.TaskRepository
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.ArgumentCaptor
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import org.springframework.context.ApplicationEventPublisher
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import java.util.Optional
import java.util.UUID

class TaskServiceTest {

    private val taskRepository = mock(TaskRepository::class.java)
    private val projectRepository = mock(ProjectRepository::class.java)
    private val eventPublisher = mock(ApplicationEventPublisher::class.java)
    private val currentUser = mock(CurrentUser::class.java)
    private val fixedClock = Clock.fixed(Instant.parse("2026-11-12T12:00:00Z"), ZoneOffset.UTC)

    private lateinit var service: TaskService

    private val userId = UUID.randomUUID()
    private val taskId = UUID.randomUUID()

    @BeforeEach
    fun setUp() {
        `when`(currentUser.id()).thenReturn(userId)
        service = TaskService(
            taskRepository = taskRepository,
            projectRepository = projectRepository,
            eventPublisher = eventPublisher,
            currentUser = currentUser,
            clock = fixedClock
        )
    }

    @Test
    fun `uncomplete with null targetStatus defaults to IN_PROGRESS and emits TaskUncompletedEvent (AC-017, AC-033)`() {
        val completedEntity = TaskEntity(
            id = taskId,
            userId = userId,
            title = "Ship feature",
            status = TaskStatus.COMPLETED,
            completedAt = Instant.parse("2026-11-12T11:00:00Z"),
            createdAt = Instant.parse("2026-11-12T09:00:00Z")
        )
        `when`(taskRepository.findById(taskId)).thenReturn(Optional.of(completedEntity))
        `when`(taskRepository.save(completedEntity)).thenReturn(completedEntity)

        val response = service.uncomplete(taskId, userId, null)

        assertEquals(TaskStatus.IN_PROGRESS, response.status)
        assertNull(response.completedAt)

        val captor = ArgumentCaptor.forClass(TaskUncompletedEvent::class.java)
        verify(eventPublisher).publishEvent(captor.capture())
        val event = captor.value
        assertEquals(taskId, event.taskId)
        assertEquals(userId, event.userId)
        assertEquals(TaskStatus.IN_PROGRESS, event.targetStatus)
    }

    @Test
    fun `uncomplete with PLANNED targetStatus transitions to PLANNED (AC-031)`() {
        val completedEntity = TaskEntity(
            id = taskId,
            userId = userId,
            title = "Ship feature",
            status = TaskStatus.COMPLETED,
            completedAt = Instant.parse("2026-11-12T11:00:00Z"),
            createdAt = Instant.parse("2026-11-12T09:00:00Z")
        )
        `when`(taskRepository.findById(taskId)).thenReturn(Optional.of(completedEntity))
        `when`(taskRepository.save(completedEntity)).thenReturn(completedEntity)

        val response = service.uncomplete(taskId, userId, "PLANNED")

        assertEquals(TaskStatus.PLANNED, response.status)
        assertNull(response.completedAt)
    }

    @Test
    fun `plan demotes IN_PROGRESS task to PLANNED (Rule 20, AC-019)`() {
        val inProgressEntity = TaskEntity(
            id = taskId,
            userId = userId,
            title = "In progress task",
            status = TaskStatus.IN_PROGRESS,
            createdAt = Instant.parse("2026-11-12T09:00:00Z")
        )
        `when`(taskRepository.findById(taskId)).thenReturn(Optional.of(inProgressEntity))
        `when`(taskRepository.save(inProgressEntity)).thenReturn(inProgressEntity)

        val response = service.plan(taskId, userId)

        assertEquals(TaskStatus.PLANNED, response.status)
        assertNull(response.completedAt)
    }
}
