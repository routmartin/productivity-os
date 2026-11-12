package com.productivityos.schedule.service

import com.productivityos.schedule.domain.ScheduleNodeType
import com.productivityos.schedule.domain.SchedulePhaseId
import com.productivityos.schedule.dto.AddScheduleStepRequest
import com.productivityos.schedule.exception.AnchorDeletionNotAllowedException
import com.productivityos.schedule.exception.ScheduleNodeNotFoundException
import com.productivityos.schedule.persistence.ScheduleEntryEntity
import com.productivityos.schedule.persistence.ScheduleEntryRepository
import com.productivityos.schedule.persistence.ScheduleHabitEntity
import com.productivityos.schedule.persistence.ScheduleHabitOccurrenceEntity
import com.productivityos.schedule.persistence.ScheduleHabitOccurrenceRepository
import com.productivityos.schedule.persistence.ScheduleHabitRepository
import com.productivityos.user.service.UserTimezoneService
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.mockito.ArgumentCaptor
import org.mockito.ArgumentMatchers.any
import org.mockito.ArgumentMatchers.eq
import org.mockito.Mockito.`when`
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify
import java.time.Clock
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZoneOffset
import java.util.Optional
import java.util.UUID

class ScheduleServiceTest {

    private lateinit var habitRepository: ScheduleHabitRepository
    private lateinit var occurrenceRepository: ScheduleHabitOccurrenceRepository
    private lateinit var entryRepository: ScheduleEntryRepository
    private lateinit var timezoneService: UserTimezoneService
    private lateinit var clock: Clock
    private lateinit var bedtimeEngine: BedtimeProjectionEngine
    private lateinit var streakCalculator: HabitStreakCalculator
    private lateinit var service: ScheduleService

    private val userId = UUID.randomUUID()
    private val otherUserId = UUID.randomUUID()
    private val date = LocalDate.of(2026, 11, 11)
    private val now = Instant.parse("2026-11-11T07:00:00Z")

    @BeforeEach
    fun setUp() {
        habitRepository = mock(ScheduleHabitRepository::class.java)
        occurrenceRepository = mock(ScheduleHabitOccurrenceRepository::class.java)
        entryRepository = mock(ScheduleEntryRepository::class.java)
        timezoneService = mock(UserTimezoneService::class.java)
        clock = Clock.fixed(now, ZoneOffset.UTC)
        bedtimeEngine = BedtimeProjectionEngine()
        streakCalculator = HabitStreakCalculator()

        service = ScheduleService(
            scheduleHabitRepository = habitRepository,
            scheduleHabitOccurrenceRepository = occurrenceRepository,
            scheduleEntryRepository = entryRepository,
            bedtimeProjectionEngine = bedtimeEngine,
            habitStreakCalculator = streakCalculator,
            userTimezoneService = timezoneService,
            clock = clock
        )

        `when`(timezoneService.today(userId)).thenReturn(date)
        `when`(timezoneService.timezone(userId)).thenReturn(ZoneId.of("UTC"))
    }

    // AC-B02: Baseline Blueprint Auto-Seeding (Spec AC-009)
    @Test
    @Suppress("UNCHECKED_CAST")
    fun `fresh user accessing schedule gets auto-seeded with 5 baseline blueprint habits and 16-node graph`() {
        `when`(habitRepository.countByUserIdAndDeletedAtIsNull(userId)).thenReturn(0L)
        `when`(entryRepository.findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByOrderIndexAsc(userId, date))
            .thenReturn(emptyList())

        // Capture saved habits
        val habitCaptor = ArgumentCaptor.forClass(List::class.java as Class<List<ScheduleHabitEntity>>)
        val entryCaptor = ArgumentCaptor.forClass(List::class.java as Class<List<ScheduleEntryEntity>>)

        val habit1Id = UUID.randomUUID()
        val habit2Id = UUID.randomUUID()
        val habit3Id = UUID.randomUUID()
        val habit4Id = UUID.randomUUID()
        val habit5Id = UUID.randomUUID()

        val seededHabits = listOf(
            ScheduleHabitEntity(id = habit1Id, userId = userId, title = "Hydration & Mineral Salts", phase = "morning", orderIndex = 2, createdAt = now),
            ScheduleHabitEntity(id = habit2Id, userId = userId, title = "Zone 2 Cardio & Mobility", phase = "morning", orderIndex = 3, createdAt = now),
            ScheduleHabitEntity(id = habit3Id, userId = userId, title = "Cold Rinse & Grooming", phase = "morning", orderIndex = 4, createdAt = now),
            ScheduleHabitEntity(id = habit4Id, userId = userId, title = "Daily Top 3 Planning", phase = "morning", orderIndex = 5, createdAt = now),
            ScheduleHabitEntity(id = habit5Id, userId = userId, title = "Evening Wind-Down", phase = "bedtime", orderIndex = 15, createdAt = now)
        )

        val seededEntries = (6..14).map { idx ->
            ScheduleEntryEntity(
                id = UUID.randomUUID(),
                userId = userId,
                calendarDate = date,
                stepType = if (idx in listOf(6, 8, 10, 11)) "task" else "recharge",
                phase = if (idx in 6..8) "deep-focus" else if (idx in 9..12) "afternoon" else "bedtime",
                title = "Entry $idx",
                orderIndex = idx,
                createdAt = now
            )
        }

        `when`(habitRepository.findByUserIdAndDeletedAtIsNullOrderByOrderIndexAsc(userId)).thenReturn(seededHabits)
        `when`(entryRepository.findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByOrderIndexAsc(userId, date))
            .thenReturn(emptyList(), seededEntries)

        `when`(occurrenceRepository.findByUserIdAndCalendarDate(userId, date)).thenReturn(emptyList())
        `when`(occurrenceRepository.findByUserIdAndCalendarDateBetween(userId, date.minusDays(365), date))
            .thenReturn(emptyList())

        val response = service.getSchedule(userId, date)

        verify(habitRepository).saveAll(habitCaptor.capture())
        assertEquals(5, habitCaptor.value.size)
        val habitTitles = habitCaptor.value.map { it.title }
        assertTrue(habitTitles.contains("Hydration & Mineral Salts"))
        assertTrue(habitTitles.contains("Zone 2 Cardio & Mobility"))
        assertTrue(habitTitles.contains("Cold Rinse & Grooming"))
        assertTrue(habitTitles.contains("Daily Top 3 Planning"))
        assertTrue(habitTitles.contains("Evening Wind-Down"))

        // 16-node circadian graph: 2 anchors + 5 habits + 9 entries
        assertEquals(16, response.nodes.size)
        assertEquals("anchor-wake", response.nodes.first().id)
        assertEquals("anchor-bedtime", response.nodes.last().id)
        assertEquals(4, response.phases.size)
        assertEquals(15, response.edges.size)
        // Zero initial completions
        response.nodes.filter { it.type == "habit" }.forEach {
            assertFalse(it.completed ?: true)
        }
    }

    // AC-B01: Unified Schedule Graph Retrieval
    @Test
    fun `getSchedule returns populated graph with anchors and phases strictly scoped to user`() {
        val habitId = UUID.randomUUID()
        val habit = ScheduleHabitEntity(
            id = habitId,
            userId = userId,
            title = "Hydration & Mineral Salts",
            phase = "morning",
            orderIndex = 2,
            createdAt = now
        )
        `when`(habitRepository.countByUserIdAndDeletedAtIsNull(userId)).thenReturn(1L)
        `when`(habitRepository.findByUserIdAndDeletedAtIsNullOrderByOrderIndexAsc(userId)).thenReturn(listOf(habit))
        `when`(entryRepository.findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByOrderIndexAsc(userId, date))
            .thenReturn(emptyList())
        `when`(occurrenceRepository.findByUserIdAndCalendarDate(userId, date)).thenReturn(emptyList())
        `when`(occurrenceRepository.findByUserIdAndCalendarDateBetween(userId, date.minusDays(365), date))
            .thenReturn(emptyList())

        val response = service.getSchedule(userId, date)

        assertEquals(date.toString(), response.date)
        assertEquals("06:30", response.wakeTime)
        assertEquals("22:30", response.targetBedtime)
        assertEquals(4, response.phases.size)
        // Wake anchor + 1 habit + Bedtime anchor = 3 nodes
        assertEquals(3, response.nodes.size)
        assertEquals("anchor-wake", response.nodes[0].id)
        assertEquals(habitId.toString(), response.nodes[1].id)
        assertEquals("anchor-bedtime", response.nodes[2].id)
        assertEquals(2, response.edges.size)
    }

    // AC-B03: Habit Completion Toggle & Streak Increment
    @Test
    fun `toggleHabit checks an incomplete habit, increments streak, illuminates edges, and recalculates bedtime`() {
        val habitId = UUID.randomUUID()
        val habit = ScheduleHabitEntity(
            id = habitId,
            userId = userId,
            title = "Hydration",
            phase = "morning",
            orderIndex = 2,
            createdAt = now
        )

        `when`(habitRepository.findByIdAndUserIdAndDeletedAtIsNull(habitId, userId)).thenReturn(Optional.of(habit))
        `when`(occurrenceRepository.findByUserIdAndHabitIdAndCalendarDate(userId, habitId, date))
            .thenReturn(Optional.empty())

        // Occurrences before toggle: completed yesterday (streak 1 -> 2)
        val pastOccurrence = ScheduleHabitOccurrenceEntity(
            id = UUID.randomUUID(),
            userId = userId,
            habitId = habitId,
            calendarDate = date.minusDays(1),
            completedAt = now
        )
        val todayOccurrence = ScheduleHabitOccurrenceEntity(
            id = UUID.randomUUID(),
            userId = userId,
            habitId = habitId,
            calendarDate = date,
            completedAt = now
        )

        `when`(occurrenceRepository.findByUserIdAndHabitIdAndCalendarDateBetween(userId, habitId, date.minusDays(365), date))
            .thenReturn(listOf(todayOccurrence, pastOccurrence))

        `when`(habitRepository.findByUserIdAndDeletedAtIsNullOrderByOrderIndexAsc(userId)).thenReturn(listOf(habit))
        `when`(entryRepository.findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByOrderIndexAsc(userId, date))
            .thenReturn(emptyList())
        `when`(occurrenceRepository.findByUserIdAndCalendarDate(userId, date))
            .thenReturn(listOf(todayOccurrence))
        `when`(occurrenceRepository.findByUserIdAndCalendarDateBetween(userId, date.minusDays(365), date))
            .thenReturn(listOf(todayOccurrence, pastOccurrence))

        val result = service.toggleHabit(userId, habitId, date)

        assertTrue(result.completed)
        assertEquals(2, result.streak)
        assertEquals(14, result.history.size)
        assertTrue(result.history.last().completed)
        verify(occurrenceRepository).save(any(ScheduleHabitOccurrenceEntity::class.java))

        // Outgoing edge should be active
        assertTrue(result.updatedEdges.isNotEmpty())
        assertTrue(result.updatedEdges.all { it.active == true })
    }

    // AC-B04: Habit Uncheck / Reversal & Streak Rollback
    @Test
    fun `toggleHabit unchecks a completed habit, deletes occurrence, and decrements streak`() {
        val habitId = UUID.randomUUID()
        val habit = ScheduleHabitEntity(
            id = habitId,
            userId = userId,
            title = "Hydration",
            phase = "morning",
            orderIndex = 2,
            createdAt = now
        )

        val existingOccurrence = ScheduleHabitOccurrenceEntity(
            id = UUID.randomUUID(),
            userId = userId,
            habitId = habitId,
            calendarDate = date,
            completedAt = now
        )

        `when`(habitRepository.findByIdAndUserIdAndDeletedAtIsNull(habitId, userId)).thenReturn(Optional.of(habit))
        `when`(occurrenceRepository.findByUserIdAndHabitIdAndCalendarDate(userId, habitId, date))
            .thenReturn(Optional.of(existingOccurrence))

        // After untoggle: only yesterday remains
        val pastOccurrence = ScheduleHabitOccurrenceEntity(
            id = UUID.randomUUID(),
            userId = userId,
            habitId = habitId,
            calendarDate = date.minusDays(1),
            completedAt = now
        )
        `when`(occurrenceRepository.findByUserIdAndHabitIdAndCalendarDateBetween(userId, habitId, date.minusDays(365), date))
            .thenReturn(listOf(pastOccurrence))

        `when`(habitRepository.findByUserIdAndDeletedAtIsNullOrderByOrderIndexAsc(userId)).thenReturn(listOf(habit))
        `when`(entryRepository.findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByOrderIndexAsc(userId, date))
            .thenReturn(emptyList())
        `when`(occurrenceRepository.findByUserIdAndCalendarDate(userId, date))
            .thenReturn(emptyList())
        `when`(occurrenceRepository.findByUserIdAndCalendarDateBetween(userId, date.minusDays(365), date))
            .thenReturn(listOf(pastOccurrence))

        val result = service.toggleHabit(userId, habitId, date)

        assertFalse(result.completed)
        assertEquals(1, result.streak) // rolled back from 2 to 1
        assertFalse(result.history.last().completed)
        verify(occurrenceRepository).deleteByUserIdAndHabitIdAndCalendarDate(userId, habitId, date)

        // Outgoing edge should be inactive
        assertTrue(result.updatedEdges.isNotEmpty())
        assertTrue(result.updatedEdges.all { it.active == false })
    }

    // AC-B05: Dynamic Bedtime & Overflow Recalculation
    @Test
    fun `bedtime overflow scales with pending habits and incomplete activities up to 45m`() {
        val habitId = UUID.randomUUID()
        val habit = ScheduleHabitEntity(
            id = habitId,
            userId = userId,
            title = "Hydration",
            phase = "morning",
            orderIndex = 2,
            createdAt = now
        )
        val task = ScheduleEntryEntity(
            id = UUID.randomUUID(),
            userId = userId,
            calendarDate = date,
            stepType = "task",
            phase = "deep-focus",
            title = "Task 1",
            durationMinutes = 60,
            completedMinutes = 0,
            orderIndex = 3,
            createdAt = now
        )

        `when`(habitRepository.countByUserIdAndDeletedAtIsNull(userId)).thenReturn(1L)
        `when`(habitRepository.findByUserIdAndDeletedAtIsNullOrderByOrderIndexAsc(userId)).thenReturn(listOf(habit))
        `when`(entryRepository.findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByOrderIndexAsc(userId, date))
            .thenReturn(listOf(task))
        `when`(occurrenceRepository.findByUserIdAndCalendarDate(userId, date)).thenReturn(emptyList())
        `when`(occurrenceRepository.findByUserIdAndCalendarDateBetween(userId, date.minusDays(365), date))
            .thenReturn(emptyList())

        // 1 pending habit + 1 incomplete task = 2 pending * 15m = 30m overflow
        val response = service.getSchedule(userId, date)

        assertEquals(30, response.overflowMinutes)
        assertEquals("23:00", response.projectedBedtime)
        val bedtimeNode = response.nodes.first { it.id == "anchor-bedtime" }
        assertEquals(30, bedtimeNode.overflowMinutes)
        assertEquals("23:00", bedtimeNode.projectedTime)
    }

    // AC-B06: In-Line Step Creation
    @Test
    fun `addStep creates habit or entry with sequential order index`() {
        val request = AddScheduleStepRequest(
            date = date,
            phase = "deep-focus",
            type = "task",
            title = "API Implementation",
            durationMinutes = 60
        )

        `when`(entryRepository.findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByOrderIndexAsc(userId, date))
            .thenReturn(emptyList())

        val savedEntry = ScheduleEntryEntity(
            id = UUID.randomUUID(),
            userId = userId,
            calendarDate = date,
            stepType = "task",
            phase = "deep-focus",
            title = "API Implementation",
            durationMinutes = 60,
            orderIndex = 1,
            createdAt = now
        )
        `when`(entryRepository.save(any(ScheduleEntryEntity::class.java))).thenReturn(savedEntry)

        val node = service.addStep(userId, request)

        assertEquals("task", node.type)
        assertEquals("deep-focus", node.phase)
        assertEquals("API Implementation", node.title)
        assertEquals(60, node.durationMinutes)
        assertEquals(1, node.order)
    }

    // AC-B07: Node Deletion from Schedule
    @Test
    fun `deleteStep soft-deletes custom schedule entry`() {
        val entryId = UUID.randomUUID()
        val entry = ScheduleEntryEntity(
            id = entryId,
            userId = userId,
            calendarDate = date,
            stepType = "task",
            phase = "deep-focus",
            title = "Custom Step",
            createdAt = now
        )

        `when`(entryRepository.findByIdAndUserIdAndDeletedAtIsNull(entryId, userId)).thenReturn(Optional.of(entry))

        service.deleteStep(userId, entryId.toString())

        assertEquals(now, entry.deletedAt)
        verify(entryRepository).save(entry)
    }

    // AC-B08: Anchor Node Deletion Invariant Guard
    @Test
    fun `deleteStep on anchor node throws AnchorDeletionNotAllowedException`() {
        assertThrows<AnchorDeletionNotAllowedException> {
            service.deleteStep(userId, "anchor-wake")
        }
        assertThrows<AnchorDeletionNotAllowedException> {
            service.deleteStep(userId, "anchor-bedtime")
        }
    }

    // AC-B09: Strict User Isolation (ADR-004)
    @Test
    fun `user cannot toggle or delete another user's habit or entry`() {
        val foreignHabitId = UUID.randomUUID()
        `when`(habitRepository.findByIdAndUserIdAndDeletedAtIsNull(foreignHabitId, otherUserId))
            .thenReturn(Optional.empty())

        assertThrows<ScheduleNodeNotFoundException> {
            service.toggleHabit(otherUserId, foreignHabitId, date)
        }

        val foreignEntryId = UUID.randomUUID()
        `when`(entryRepository.findByIdAndUserIdAndDeletedAtIsNull(foreignEntryId, otherUserId))
            .thenReturn(Optional.empty())
        `when`(habitRepository.findByIdAndUserIdAndDeletedAtIsNull(foreignEntryId, otherUserId))
            .thenReturn(Optional.empty())

        assertThrows<ScheduleNodeNotFoundException> {
            service.deleteStep(otherUserId, foreignEntryId.toString())
        }
    }

    // AC-B10: 14-Day Consistency History Array Generation
    @Test
    fun `habit nodes include exactly 14 history days ending on queried date`() {
        val habitId = UUID.randomUUID()
        val habit = ScheduleHabitEntity(
            id = habitId,
            userId = userId,
            title = "Hydration",
            phase = "morning",
            orderIndex = 2,
            createdAt = now
        )

        `when`(habitRepository.countByUserIdAndDeletedAtIsNull(userId)).thenReturn(1L)
        `when`(habitRepository.findByUserIdAndDeletedAtIsNullOrderByOrderIndexAsc(userId)).thenReturn(listOf(habit))
        `when`(entryRepository.findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByOrderIndexAsc(userId, date))
            .thenReturn(emptyList())
        `when`(occurrenceRepository.findByUserIdAndCalendarDate(userId, date)).thenReturn(emptyList())
        `when`(occurrenceRepository.findByUserIdAndCalendarDateBetween(userId, date.minusDays(365), date))
            .thenReturn(emptyList())

        val response = service.getSchedule(userId, date)
        val habitNode = response.nodes.first { it.id == habitId.toString() }

        assertNotNull(habitNode.history)
        assertEquals(14, habitNode.history!!.size)
        assertEquals(date.minusDays(13).toString(), habitNode.history!!.first().date)
        assertEquals(date.toString(), habitNode.history!!.last().date)
    }
}
