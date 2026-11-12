package com.productivityos.schedule.service

import com.productivityos.schedule.domain.ScheduleEdgeType
import com.productivityos.schedule.domain.ScheduleNodeType
import com.productivityos.schedule.domain.SchedulePhaseId
import com.productivityos.schedule.dto.AddScheduleStepRequest
import com.productivityos.schedule.dto.HabitStreakDayDTO
import com.productivityos.schedule.dto.ScheduleEdgeDTO
import com.productivityos.schedule.dto.ScheduleGraphResponse
import com.productivityos.schedule.dto.ScheduleNodeDTO
import com.productivityos.schedule.dto.SchedulePhaseDTO
import com.productivityos.schedule.dto.ToggleHabitResponse
import com.productivityos.schedule.dto.UpdateScheduleStepRequest
import com.productivityos.schedule.exception.AnchorDeletionNotAllowedException
import com.productivityos.schedule.exception.AnchorUpdateNotAllowedException
import com.productivityos.schedule.exception.ScheduleNodeNotFoundException
import com.productivityos.schedule.persistence.ScheduleEntryEntity
import com.productivityos.schedule.persistence.ScheduleEntryRepository
import com.productivityos.schedule.persistence.ScheduleHabitEntity
import com.productivityos.schedule.persistence.ScheduleHabitOccurrenceEntity
import com.productivityos.schedule.persistence.ScheduleHabitOccurrenceRepository
import com.productivityos.schedule.persistence.ScheduleHabitRepository
import com.productivityos.user.service.UserTimezoneService
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.time.LocalDate
import java.util.UUID

@Service
@Transactional
class ScheduleService(
    private val scheduleHabitRepository: ScheduleHabitRepository,
    private val scheduleHabitOccurrenceRepository: ScheduleHabitOccurrenceRepository,
    private val scheduleEntryRepository: ScheduleEntryRepository,
    private val bedtimeProjectionEngine: BedtimeProjectionEngine,
    private val habitStreakCalculator: HabitStreakCalculator,
    private val userTimezoneService: UserTimezoneService,
    private val clock: Clock
) {

    companion object {
        const val WAKE_TIME = "06:30"
        const val TARGET_BEDTIME = "22:30"
        const val ANCHOR_WAKE_ID = "anchor-wake"
        const val ANCHOR_BEDTIME_ID = "anchor-bedtime"
    }

    private val defaultPhases = listOf(
        SchedulePhaseDTO(
            id = SchedulePhaseId.MORNING.value,
            title = SchedulePhaseId.MORNING.defaultTitle,
            subtitle = SchedulePhaseId.MORNING.defaultSubtitle,
            timeRange = SchedulePhaseId.MORNING.defaultTimeRange,
            colorTone = SchedulePhaseId.MORNING.tone
        ),
        SchedulePhaseDTO(
            id = SchedulePhaseId.DEEP_FOCUS.value,
            title = SchedulePhaseId.DEEP_FOCUS.defaultTitle,
            subtitle = SchedulePhaseId.DEEP_FOCUS.defaultSubtitle,
            timeRange = SchedulePhaseId.DEEP_FOCUS.defaultTimeRange,
            colorTone = SchedulePhaseId.DEEP_FOCUS.tone
        ),
        SchedulePhaseDTO(
            id = SchedulePhaseId.AFTERNOON.value,
            title = SchedulePhaseId.AFTERNOON.defaultTitle,
            subtitle = SchedulePhaseId.AFTERNOON.defaultSubtitle,
            timeRange = SchedulePhaseId.AFTERNOON.defaultTimeRange,
            colorTone = SchedulePhaseId.AFTERNOON.tone
        ),
        SchedulePhaseDTO(
            id = SchedulePhaseId.BEDTIME.value,
            title = SchedulePhaseId.BEDTIME.defaultTitle,
            subtitle = SchedulePhaseId.BEDTIME.defaultSubtitle,
            timeRange = SchedulePhaseId.BEDTIME.defaultTimeRange,
            colorTone = SchedulePhaseId.BEDTIME.tone
        )
    )

    fun getSchedule(userId: UUID, date: LocalDate): ScheduleGraphResponse {
        val habitCount = scheduleHabitRepository.countByUserIdAndDeletedAtIsNull(userId)
        val entryCount = scheduleEntryRepository
            .findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByOrderIndexAsc(userId, date).size

        if (habitCount == 0L) {
            seedDefaultBlueprint(userId, date)
        } else if (entryCount == 0) {
            seedDefaultEntriesForDate(userId, date)
        }

        return buildScheduleGraph(userId, date)
    }

    fun toggleHabit(userId: UUID, habitId: UUID, date: LocalDate): ToggleHabitResponse {
        val habit = scheduleHabitRepository.findByIdAndUserIdAndDeletedAtIsNull(habitId, userId)
            .orElseThrow { ScheduleNodeNotFoundException("Habit not found: $habitId") }

        val existingOccurrence = scheduleHabitOccurrenceRepository
            .findByUserIdAndHabitIdAndCalendarDate(userId, habitId, date)

        val completed: Boolean
        if (existingOccurrence.isPresent) {
            scheduleHabitOccurrenceRepository.deleteByUserIdAndHabitIdAndCalendarDate(userId, habitId, date)
            completed = false
        } else {
            val occurrence = ScheduleHabitOccurrenceEntity(
                userId = userId,
                habitId = habitId,
                calendarDate = date,
                completedAt = clock.instant()
            )
            scheduleHabitOccurrenceRepository.save(occurrence)
            completed = true
        }

        val historyWindow = scheduleHabitOccurrenceRepository
            .findByUserIdAndHabitIdAndCalendarDateBetween(userId, habitId, date.minusDays(365), date)
            .map { it.calendarDate }
            .toSet()

        val streak = habitStreakCalculator.calculateStreak(historyWindow, date)
        val history = habitStreakCalculator.generate14DayHistory(historyWindow, date)

        val updatedGraph = buildScheduleGraph(userId, date)
        val updatedEdges = updatedGraph.edges.filter { it.fromNodeId == habit.id.toString() }

        return ToggleHabitResponse(
            habitId = habit.id!!,
            completed = completed,
            streak = streak,
            history = history,
            updatedEdges = updatedEdges,
            projectedBedtime = updatedGraph.projectedBedtime,
            overflowMinutes = updatedGraph.overflowMinutes
        )
    }

    fun addStep(userId: UUID, request: AddScheduleStepRequest): ScheduleNodeDTO {
        val targetDate = request.date ?: userTimezoneService.today(userId)

        val validPhases = setOf(
            SchedulePhaseId.MORNING.value,
            SchedulePhaseId.DEEP_FOCUS.value,
            SchedulePhaseId.AFTERNOON.value,
            SchedulePhaseId.BEDTIME.value
        )
        if (request.phase !in validPhases) {
            throw IllegalArgumentException("Invalid phase: ${request.phase}. Allowed: $validPhases")
        }

        return if (request.type.equals("habit", ignoreCase = true)) {
            val existing = scheduleHabitRepository.findByUserIdAndDeletedAtIsNullOrderByOrderIndexAsc(userId)
            val nextOrder = (existing.maxOfOrNull { it.orderIndex } ?: 0) + 1
            val habit = ScheduleHabitEntity(
                userId = userId,
                title = request.title,
                subtitle = request.subtitle,
                icon = request.iconName ?: "sun.max",
                phase = request.phase,
                targetTime = request.timeSlot,
                durationMinutes = request.durationMinutes ?: 15,
                orderIndex = nextOrder,
                createdAt = clock.instant()
            )
            val saved = scheduleHabitRepository.save(habit)
            val history = habitStreakCalculator.generate14DayHistory(emptySet(), targetDate)
            ScheduleNodeDTO(
                id = saved.id.toString(),
                type = ScheduleNodeType.HABIT.value,
                phase = saved.phase,
                title = saved.title,
                subtitle = saved.subtitle,
                time = saved.targetTime,
                durationMinutes = saved.durationMinutes,
                habitId = saved.id.toString(),
                icon = saved.icon,
                streak = 0,
                completed = false,
                frequency = "Daily",
                history = history,
                order = saved.orderIndex
            )
        } else {
            val existing = scheduleEntryRepository
                .findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByOrderIndexAsc(userId, targetDate)
            val nextOrder = (existing.maxOfOrNull { it.orderIndex } ?: 0) + 1
            val entry = ScheduleEntryEntity(
                userId = userId,
                calendarDate = targetDate,
                stepType = request.type,
                phase = request.phase,
                title = request.title,
                subtitle = request.subtitle,
                timeLabel = request.timeSlot,
                durationMinutes = request.durationMinutes ?: 30,
                orderIndex = nextOrder,
                createdAt = clock.instant()
            )
            val saved = scheduleEntryRepository.save(entry)
            ScheduleNodeDTO(
                id = saved.id.toString(),
                type = saved.stepType,
                phase = saved.phase,
                title = saved.title,
                subtitle = saved.subtitle,
                time = saved.timeLabel,
                durationMinutes = saved.durationMinutes,
                inFocus = saved.inFocus,
                completedMinutes = saved.completedMinutes,
                totalMinutes = saved.durationMinutes,
                order = saved.orderIndex
            )
        }
    }

    fun deleteStep(userId: UUID, stepId: String) {
        if (stepId == ANCHOR_WAKE_ID || stepId == ANCHOR_BEDTIME_ID || stepId.startsWith("anchor-")) {
            throw AnchorDeletionNotAllowedException("Anchor node deletion is not allowed")
        }

        val uuid = try {
            UUID.fromString(stepId)
        } catch (e: Exception) {
            throw ScheduleNodeNotFoundException("Invalid step id: $stepId")
        }

        val entryOpt = scheduleEntryRepository.findByIdAndUserIdAndDeletedAtIsNull(uuid, userId)
        if (entryOpt.isPresent) {
            val entry = entryOpt.get()
            entry.deletedAt = clock.instant()
            scheduleEntryRepository.save(entry)
            return
        }

        val habitOpt = scheduleHabitRepository.findByIdAndUserIdAndDeletedAtIsNull(uuid, userId)
        if (habitOpt.isPresent) {
            val habit = habitOpt.get()
            habit.deletedAt = clock.instant()
            scheduleHabitRepository.save(habit)
            return
        }

        throw ScheduleNodeNotFoundException("Schedule node not found: $stepId")
    }

    fun updateStep(userId: UUID, stepId: String, request: UpdateScheduleStepRequest): ScheduleNodeDTO {
        if (stepId == ANCHOR_WAKE_ID || stepId == ANCHOR_BEDTIME_ID || stepId.startsWith("anchor-")) {
            throw AnchorUpdateNotAllowedException("Anchor node update is not allowed")
        }

        val uuid = try {
            UUID.fromString(stepId)
        } catch (e: Exception) {
            throw ScheduleNodeNotFoundException("Invalid step id: $stepId")
        }

        val validPhases = setOf(
            SchedulePhaseId.MORNING.value,
            SchedulePhaseId.DEEP_FOCUS.value,
            SchedulePhaseId.AFTERNOON.value,
            SchedulePhaseId.BEDTIME.value
        )
        if (request.phase != null && request.phase !in validPhases) {
            throw IllegalArgumentException("Invalid phase: ${request.phase}. Allowed: $validPhases")
        }

        val entryOpt = scheduleEntryRepository.findByIdAndUserIdAndDeletedAtIsNull(uuid, userId)
        if (entryOpt.isPresent) {
            val entry = entryOpt.get()
            entry.title = request.title.trim()
            if (request.subtitle != null) {
                entry.subtitle = request.subtitle.trim()
            }
            if (!request.phase.isNullOrBlank()) {
                entry.phase = request.phase
            }
            if (request.timeSlot != null) {
                entry.timeLabel = request.timeSlot.trim()
            }
            if (request.durationMinutes != null) {
                entry.durationMinutes = request.durationMinutes
            }
            if (request.notes != null) {
                entry.notes = request.notes.trim()
            }
            val saved = scheduleEntryRepository.save(entry)
            return ScheduleNodeDTO(
                id = saved.id.toString(),
                type = saved.stepType,
                phase = saved.phase,
                title = saved.title,
                subtitle = saved.subtitle,
                time = saved.timeLabel,
                durationMinutes = saved.durationMinutes,
                inFocus = saved.inFocus,
                completedMinutes = saved.completedMinutes,
                totalMinutes = saved.durationMinutes,
                rechargeKind = if (saved.stepType == ScheduleNodeType.RECHARGE.value) "break" else null,
                notes = saved.notes,
                order = saved.orderIndex
            )
        }

        val habitOpt = scheduleHabitRepository.findByIdAndUserIdAndDeletedAtIsNull(uuid, userId)
        if (habitOpt.isPresent) {
            val habit = habitOpt.get()
            habit.title = request.title.trim()
            if (request.subtitle != null) {
                habit.subtitle = request.subtitle.trim()
            }
            if (!request.iconName.isNullOrBlank()) {
                habit.icon = request.iconName.trim()
            }
            if (!request.phase.isNullOrBlank()) {
                habit.phase = request.phase
            }
            if (request.timeSlot != null) {
                habit.targetTime = request.timeSlot.trim()
            }
            if (request.durationMinutes != null) {
                habit.durationMinutes = request.durationMinutes
            }
            if (request.notes != null) {
                habit.notes = request.notes.trim()
            }
            val saved = scheduleHabitRepository.save(habit)

            val targetDate = request.date ?: userTimezoneService.today(userId)
            val historyWindow = scheduleHabitOccurrenceRepository
                .findByUserIdAndHabitIdAndCalendarDateBetween(userId, uuid, targetDate.minusDays(365), targetDate)
                .map { it.calendarDate }
                .toSet()
            val isCompleted = scheduleHabitOccurrenceRepository
                .findByUserIdAndHabitIdAndCalendarDate(userId, uuid, targetDate)
                .isPresent
            val streak = habitStreakCalculator.calculateStreak(historyWindow, targetDate)
            val history = habitStreakCalculator.generate14DayHistory(historyWindow, targetDate)

            return ScheduleNodeDTO(
                id = saved.id.toString(),
                type = ScheduleNodeType.HABIT.value,
                phase = saved.phase,
                title = saved.title,
                subtitle = saved.subtitle,
                time = saved.targetTime,
                durationMinutes = saved.durationMinutes,
                habitId = saved.id.toString(),
                icon = saved.icon,
                streak = streak,
                completed = isCompleted,
                frequency = "Daily",
                history = history,
                notes = saved.notes,
                order = saved.orderIndex
            )
        }

        throw ScheduleNodeNotFoundException("Schedule node not found: $stepId")
    }

    fun seedDefaultBlueprint(userId: UUID, date: LocalDate? = null) {
        val now = clock.instant()
        val targetDate = date ?: userTimezoneService.today(userId)

        // Seed standard 5 baseline habits (AC-B02)
        val habits = listOf(
            ScheduleHabitEntity(
                userId = userId,
                title = "Hydration & Mineral Salts",
                subtitle = "Rehydrate brain and kickstart metabolism",
                icon = "drop.fill",
                phase = SchedulePhaseId.MORNING.value,
                targetTime = "06:45",
                durationMinutes = 15,
                orderIndex = 2,
                notes = "Filtered water with a pinch of Himalayan pink salt and lemon.",
                createdAt = now
            ),
            ScheduleHabitEntity(
                userId = userId,
                title = "Zone 2 Cardio & Mobility",
                subtitle = "Light jog or bodyweight mobility flow",
                icon = "figure.run",
                phase = SchedulePhaseId.MORNING.value,
                targetTime = "07:00",
                durationMinutes = 45,
                orderIndex = 3,
                notes = "Elevate heart rate to 125-135 bpm for mitochondrial health.",
                createdAt = now
            ),
            ScheduleHabitEntity(
                userId = userId,
                title = "Cold Rinse & Grooming",
                subtitle = "Dopamine surge and alertness spike",
                icon = "shower.fill",
                phase = SchedulePhaseId.MORNING.value,
                targetTime = "07:45",
                durationMinutes = 15,
                orderIndex = 4,
                notes = "2 minutes cold finish to boost norepinephrine.",
                createdAt = now
            ),
            ScheduleHabitEntity(
                userId = userId,
                title = "Daily Top 3 Planning",
                subtitle = "Review priorities and calibrate focus blocks",
                icon = "target",
                phase = SchedulePhaseId.MORNING.value,
                targetTime = "08:15",
                durationMinutes = 30,
                orderIndex = 5,
                notes = "Lock in Daily Top 3 and silence notification channels.",
                createdAt = now
            ),
            ScheduleHabitEntity(
                userId = userId,
                title = "Evening Wind-Down",
                subtitle = "Down-regulate central nervous system",
                icon = "cup.and.saucer.fill",
                phase = SchedulePhaseId.BEDTIME.value,
                targetTime = "22:00",
                durationMinutes = 15,
                orderIndex = 15,
                notes = "Warm herbal tea, 5 minutes 4-7-8 parasympathetic breathing.",
                createdAt = now
            )
        )
        scheduleHabitRepository.saveAll(habits)

        seedDefaultEntriesForDate(userId, targetDate)
    }

    private fun seedDefaultEntriesForDate(userId: UUID, date: LocalDate) {
        val now = clock.instant()
        val entries = listOf(
            ScheduleEntryEntity(
                userId = userId,
                calendarDate = date,
                stepType = ScheduleNodeType.TASK.value,
                phase = SchedulePhaseId.DEEP_FOCUS.value,
                title = "Finish authentication architecture",
                subtitle = "Top 1 Priority · Core Security & JWT flow",
                timeLabel = "09:00",
                durationMinutes = 90,
                orderIndex = 6,
                notes = "Implement refresh tokens, user isolation tests, and session revocation.",
                createdAt = now
            ),
            ScheduleEntryEntity(
                userId = userId,
                calendarDate = date,
                stepType = ScheduleNodeType.RECHARGE.value,
                phase = SchedulePhaseId.DEEP_FOCUS.value,
                title = "Eye Rest & Hydration Walk",
                subtitle = "Disengage focus network and look at distance",
                timeLabel = "10:30",
                durationMinutes = 15,
                orderIndex = 7,
                notes = "Step away from screen. Look at horizon to relax ciliary eye muscles.",
                createdAt = now
            ),
            ScheduleEntryEntity(
                userId = userId,
                calendarDate = date,
                stepType = ScheduleNodeType.TASK.value,
                phase = SchedulePhaseId.DEEP_FOCUS.value,
                title = "Build task dashboard layout",
                subtitle = "Top 2 Priority · Kanban & List hybrid",
                timeLabel = "10:45",
                durationMinutes = 75,
                orderIndex = 8,
                notes = "Desktop 1600px responsive grid with priority column drag-drop.",
                createdAt = now
            ),
            ScheduleEntryEntity(
                userId = userId,
                calendarDate = date,
                stepType = ScheduleNodeType.RECHARGE.value,
                phase = SchedulePhaseId.AFTERNOON.value,
                title = "Nutritious Lunch & Outdoor Walk",
                subtitle = "Balanced protein + low glycemic index carbs",
                timeLabel = "12:00",
                durationMinutes = 60,
                orderIndex = 9,
                notes = "Avoid heavy sugars to prevent post-lunch sluggishness.",
                createdAt = now
            ),
            ScheduleEntryEntity(
                userId = userId,
                calendarDate = date,
                stepType = ScheduleNodeType.TASK.value,
                phase = SchedulePhaseId.AFTERNOON.value,
                title = "Review API implementation",
                subtitle = "Top 3 Priority · Verification & OpenAPI docs",
                timeLabel = "13:00",
                durationMinutes = 60,
                orderIndex = 10,
                notes = "Review error schemas, DTOs, and test coverage on PR #42.",
                createdAt = now
            ),
            ScheduleEntryEntity(
                userId = userId,
                calendarDate = date,
                stepType = ScheduleNodeType.TASK.value,
                phase = SchedulePhaseId.AFTERNOON.value,
                title = "Write documentation & Team Sync",
                subtitle = "Low cognitive load · Clean inbox & sync updates",
                timeLabel = "14:00",
                durationMinutes = 60,
                orderIndex = 11,
                notes = "Update README architecture diagrams and respond to team RFC comments.",
                createdAt = now
            ),
            ScheduleEntryEntity(
                userId = userId,
                calendarDate = date,
                stepType = ScheduleNodeType.RECHARGE.value,
                phase = SchedulePhaseId.AFTERNOON.value,
                title = "Afternoon Sunset Stride",
                subtitle = "Evening light cues to initiate melatonin onset",
                timeLabel = "16:00",
                durationMinutes = 30,
                orderIndex = 12,
                notes = "20-30 min brisk walk outdoors during golden hour.",
                createdAt = now
            ),
            ScheduleEntryEntity(
                userId = userId,
                calendarDate = date,
                stepType = ScheduleNodeType.RECHARGE.value,
                phase = SchedulePhaseId.BEDTIME.value,
                title = "Digital Screen Curfew",
                subtitle = "Turn off blue light displays and dock phone away from bed",
                timeLabel = "21:00",
                durationMinutes = 15,
                orderIndex = 13,
                notes = "All screens off. Night lighting turned to warm amber dim mode.",
                createdAt = now
            ),
            ScheduleEntryEntity(
                userId = userId,
                calendarDate = date,
                stepType = ScheduleNodeType.RECHARGE.value,
                phase = SchedulePhaseId.BEDTIME.value,
                title = "Evening Reflection & Fiction Reading",
                subtitle = "3 wins of the day, brain dump & analog paper book",
                timeLabel = "21:30",
                durationMinutes = 30,
                orderIndex = 14,
                notes = "Write 3 wins in physical notebook, read 15-20 pages fiction.",
                createdAt = now
            )
        )
        scheduleEntryRepository.saveAll(entries)
    }

    private fun buildScheduleGraph(userId: UUID, date: LocalDate): ScheduleGraphResponse {
        val habits = scheduleHabitRepository.findByUserIdAndDeletedAtIsNullOrderByOrderIndexAsc(userId)
        val entries = scheduleEntryRepository
            .findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByOrderIndexAsc(userId, date)

        val todayOccurrences = scheduleHabitOccurrenceRepository
            .findByUserIdAndCalendarDate(userId, date)
            .associateBy { it.habitId }

        val allOccurrences = scheduleHabitOccurrenceRepository
            .findByUserIdAndCalendarDateBetween(userId, date.minusDays(365), date)
        val occurrencesByHabit = allOccurrences
            .groupBy({ it.habitId }, { it.calendarDate })
            .mapValues { it.value.toSet() }

        var pendingHabits = 0
        val habitNodes = habits.map { habit ->
            val isCompleted = todayOccurrences.containsKey(habit.id)
            if (!isCompleted) pendingHabits++
            val occurrences = occurrencesByHabit[habit.id] ?: emptySet()
            val streak = habitStreakCalculator.calculateStreak(occurrences, date)
            val history = habitStreakCalculator.generate14DayHistory(occurrences, date)

            ScheduleNodeDTO(
                id = habit.id.toString(),
                type = ScheduleNodeType.HABIT.value,
                phase = habit.phase,
                title = habit.title,
                subtitle = habit.subtitle,
                time = habit.targetTime,
                durationMinutes = habit.durationMinutes,
                habitId = habit.id.toString(),
                icon = habit.icon,
                streak = streak,
                completed = isCompleted,
                frequency = "Daily",
                history = history,
                notes = habit.notes,
                order = habit.orderIndex
            )
        }

        var incompleteActivities = 0
        val entryNodes = entries.map { entry ->
            val isIncomplete = entry.stepType == ScheduleNodeType.TASK.value &&
                (entry.completedMinutes < entry.durationMinutes)
            if (isIncomplete) incompleteActivities++

            ScheduleNodeDTO(
                id = entry.id.toString(),
                type = entry.stepType,
                phase = entry.phase,
                title = entry.title,
                subtitle = entry.subtitle,
                time = entry.timeLabel,
                durationMinutes = entry.durationMinutes,
                inFocus = entry.inFocus,
                completedMinutes = entry.completedMinutes,
                totalMinutes = entry.durationMinutes,
                rechargeKind = if (entry.stepType == ScheduleNodeType.RECHARGE.value) "break" else null,
                notes = entry.notes,
                order = entry.orderIndex
            )
        }

        val overflowMinutes = bedtimeProjectionEngine.calculateOverflow(pendingHabits, incompleteActivities)
        val projectedBedtime = bedtimeProjectionEngine.calculateProjectedTime(TARGET_BEDTIME, overflowMinutes)

        val wakeAnchor = ScheduleNodeDTO(
            id = ANCHOR_WAKE_ID,
            type = ScheduleNodeType.ANCHOR.value,
            phase = SchedulePhaseId.MORNING.value,
            title = "Wake Up & Natural Sunlight",
            subtitle = "Anchor routine to reset circadian clock",
            time = WAKE_TIME,
            durationMinutes = 15,
            anchorKind = "wake",
            targetTime = WAKE_TIME,
            notes = "Get 10 minutes of direct sunlight outdoors within 30 minutes of waking.",
            order = 1
        )

        val bedtimeAnchor = ScheduleNodeDTO(
            id = ANCHOR_BEDTIME_ID,
            type = ScheduleNodeType.ANCHOR.value,
            phase = SchedulePhaseId.BEDTIME.value,
            title = "Sleep Target & Bedtime Terminus",
            subtitle = "Target $TARGET_BEDTIME · 8h Recovery Sleep Target",
            time = TARGET_BEDTIME,
            durationMinutes = 480,
            anchorKind = "bedtime",
            targetTime = TARGET_BEDTIME,
            projectedTime = projectedBedtime,
            overflowMinutes = overflowMinutes,
            notes = "Room temperature 18°C, total blackout, earplugs ready.",
            order = 16
        )

        val phaseOrder = mapOf(
            SchedulePhaseId.MORNING.value to 1,
            SchedulePhaseId.DEEP_FOCUS.value to 2,
            SchedulePhaseId.AFTERNOON.value to 3,
            SchedulePhaseId.BEDTIME.value to 4
        )

        val middleNodes = (habitNodes + entryNodes).sortedWith(
            compareBy<ScheduleNodeDTO> { phaseOrder[it.phase] ?: 99 }
                .thenBy { it.order ?: 999 }
        )

        val allNodes = listOf(wakeAnchor) + middleNodes + listOf(bedtimeAnchor)

        // Topological Edge Wiring
        val edges = ArrayList<ScheduleEdgeDTO>()
        for (i in 0 until allNodes.size - 1) {
            val from = allNodes[i]
            val to = allNodes[i + 1]

            val edgeType = when {
                from.phase != to.phase -> ScheduleEdgeType.PHASE.value
                from.type == ScheduleNodeType.HABIT.value && to.type == ScheduleNodeType.HABIT.value ->
                    ScheduleEdgeType.PREREQUISITE.value
                else -> ScheduleEdgeType.SEQUENTIAL.value
            }

            val isActive = when {
                from.type == ScheduleNodeType.HABIT.value -> from.completed == true
                else -> false
            }

            edges.add(
                ScheduleEdgeDTO(
                    id = "e-${from.id}-${to.id}",
                    fromNodeId = from.id,
                    toNodeId = to.id,
                    type = edgeType,
                    active = isActive
                )
            )
        }

        return ScheduleGraphResponse(
            date = date.toString(),
            wakeTime = WAKE_TIME,
            targetBedtime = TARGET_BEDTIME,
            projectedBedtime = projectedBedtime,
            overflowMinutes = overflowMinutes,
            phases = defaultPhases,
            nodes = allNodes,
            edges = edges
        )
    }
}
