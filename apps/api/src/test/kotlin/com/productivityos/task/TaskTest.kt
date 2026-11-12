package com.productivityos.task

import com.productivityos.task.domain.Task
import com.productivityos.task.domain.TaskStatus

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import java.time.Instant
import java.util.UUID

class TaskTest {

    private val now = Instant.parse("2026-11-12T10:00:00Z")
    private val taskId = UUID.randomUUID()
    private val userId = UUID.randomUUID()

    @Test
    fun `new task defaults to PLANNED status`() {
        val task = Task(id = taskId, ownerId = userId, title = "Test Task")
        assertEquals(TaskStatus.PLANNED, task.status)
        assertNull(task.completedAt)
    }

    @Test
    fun `complete task from PLANNED transitions to COMPLETED with timestamp`() {
        val task = Task(id = taskId, ownerId = userId, title = "Test Task", status = TaskStatus.PLANNED)
        val completed = task.complete(now)

        assertEquals(TaskStatus.COMPLETED, completed.status)
        assertEquals(now, completed.completedAt)
    }

    @Test
    fun `complete task from IN_PROGRESS transitions to COMPLETED with timestamp`() {
        val task = Task(id = taskId, ownerId = userId, title = "Test Task", status = TaskStatus.IN_PROGRESS)
        val completed = task.complete(now)

        assertEquals(TaskStatus.COMPLETED, completed.status)
        assertEquals(now, completed.completedAt)
    }

    @Test
    fun `uncomplete without target defaults to IN_PROGRESS and clears completedAt (AC-017, AC-032)`() {
        val completed = Task(
            id = taskId,
            ownerId = userId,
            title = "Test Task",
            status = TaskStatus.COMPLETED,
            completedAt = now
        )
        val uncompleted = completed.uncomplete()

        assertEquals(TaskStatus.IN_PROGRESS, uncompleted.status)
        assertNull(uncompleted.completedAt)
    }

    @Test
    fun `uncomplete with target PLANNED transitions to PLANNED and clears completedAt (AC-031, AC-032)`() {
        val completed = Task(
            id = taskId,
            ownerId = userId,
            title = "Test Task",
            status = TaskStatus.COMPLETED,
            completedAt = now
        )
        val uncompleted = completed.uncomplete(TaskStatus.PLANNED)

        assertEquals(TaskStatus.PLANNED, uncompleted.status)
        assertNull(uncompleted.completedAt)
    }

    @Test
    fun `uncomplete rejected on non-completed tasks (AC-034)`() {
        val planned = Task(id = taskId, ownerId = userId, title = "Test Task", status = TaskStatus.PLANNED)
        assertThrows<IllegalArgumentException> {
            planned.uncomplete()
        }

        val inProgress = Task(id = taskId, ownerId = userId, title = "Test Task", status = TaskStatus.IN_PROGRESS)
        assertThrows<IllegalArgumentException> {
            inProgress.uncomplete()
        }
    }
}
