package com.productivityos.dailyplan

import com.productivityos.task.TaskCancelledEvent
import com.productivityos.task.TaskCompletedEvent
import com.productivityos.task.TaskRepository
import com.productivityos.task.TaskStatus
import com.productivityos.user.UserTimezoneService
import org.springframework.context.event.EventListener
import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.time.LocalDate
import java.util.UUID

@Service
@Transactional
class DailyPlanService(
    private val dailyPlanRepository: DailyPlanRepository,
    private val taskRepository: TaskRepository,
    private val userTimezoneService: UserTimezoneService,
    private val jdbcTemplate: JdbcTemplate,
    private val clock: Clock
) {
    companion object {
        private const val MAX_ROLLOVERS = 3
    }

    fun plan(userId: UUID, calendarDate: LocalDate, request: PlanTaskRequest): DailyPlanResponse {
        val today = userTimezoneService.today(userId)
        require(!calendarDate.isBefore(today)) { "Past dates are view-only" }

        val task = taskRepository.findById(request.taskId).orElse(null)
            ?: throw NoSuchElementException("Task not found: ${request.taskId}")
        require(task.userId == userId) { "Task does not belong to the current user" }

        val existing = dailyPlanRepository
            .findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByCreatedAtAsc(userId, calendarDate)
        require(existing.none { it.taskId == request.taskId }) {
            "Task is already planned for this date"
        }

        val entity = DailyPlanEntity(
            userId = userId,
            taskId = request.taskId,
            calendarDate = calendarDate,
            remark = request.remark,
            createdAt = clock.instant()
        )
        val saved = dailyPlanRepository.save(entity)
        return DailyPlanResponse.from(saved, task.title)
    }

    @Transactional(readOnly = true)
    fun list(userId: UUID, calendarDate: LocalDate): List<DailyPlanResponse> {
        val today = userTimezoneService.today(userId)

        if (calendarDate == today) {
            rolloverFromYesterday(userId, today)
        }

        val isPast = calendarDate.isBefore(today)

        val entries = if (isPast) {
            dailyPlanRepository.findByUserIdAndCalendarDateOrderByCreatedAtAsc(userId, calendarDate)
        } else {
            dailyPlanRepository.findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByCreatedAtAsc(userId, calendarDate)
        }

        return entries.map { entity ->
            if (entity.deletedAt != null) {
                DailyPlanResponse.from(entity, null)
            } else {
                val task = taskRepository.findById(entity.taskId).orElse(null)
                DailyPlanResponse.from(entity, task?.title)
            }
        }
    }

    fun remove(userId: UUID, calendarDate: LocalDate, planId: UUID) {
        val today = userTimezoneService.today(userId)
        require(!calendarDate.isBefore(today)) { "Past dates are view-only" }

        val entity = dailyPlanRepository.findById(planId).orElse(null)
            ?: throw NoSuchElementException("Plan entry not found: $planId")
        require(entity.userId == userId) { "Plan entry does not belong to the current user" }

        entity.deletedAt = clock.instant()
        dailyPlanRepository.save(entity)
    }

    fun setCapacity(userId: UUID, calendarDate: LocalDate, hours: Int) {
        require(hours >= 0) { "Capacity must be non-negative" }
        jdbcTemplate.update(
            "INSERT INTO daily_capacities (user_id, calendar_date, capacity_hours) VALUES (?, ?, ?) " +
            "ON CONFLICT (user_id, calendar_date) DO UPDATE SET capacity_hours = ?",
            userId, calendarDate, hours, hours
        )
    }

    fun getCapacity(userId: UUID, calendarDate: LocalDate): Int {
        // queryForObject throws on an empty result set — use query so a
        // missing row falls back to the 6h default instead of a 500.
        val rows = jdbcTemplate.query(
            "SELECT capacity_hours FROM daily_capacities WHERE user_id = ? AND calendar_date = ?",
            { rs, _ -> rs.getInt("capacity_hours") },
            userId, calendarDate
        )
        return rows.firstOrNull() ?: 6
    }

    fun getCapacityInfo(userId: UUID, calendarDate: LocalDate): CapacityInfo {
        val capacityHours = getCapacity(userId, calendarDate)
        val plannedMinutes = dailyPlanRepository
            .findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByCreatedAtAsc(userId, calendarDate)
            .mapNotNull { entity ->
                val task = taskRepository.findById(entity.taskId).orElse(null)
                task?.estimatedDurationMinutes
            }
            .sum()
        val plannedHours = plannedMinutes / 60
        return CapacityInfo(
            capacityHours = capacityHours,
            plannedHours = plannedHours,
            overCapacity = plannedHours > capacityHours
        )
    }

    private fun rolloverFromYesterday(userId: UUID, today: LocalDate) {
        val yesterday = today.minusDays(1)

        val yesterdayPlans = dailyPlanRepository
            .findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByCreatedAtAsc(userId, yesterday)
        if (yesterdayPlans.isEmpty()) return

        val existingToday = dailyPlanRepository
            .findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByCreatedAtAsc(userId, today)
        val todayTaskIds = existingToday.map { it.taskId }.toSet()

        val now = clock.instant()

        for (plan in yesterdayPlans) {
            val task = taskRepository.findById(plan.taskId).orElse(null) ?: continue

            if (task.status == TaskStatus.COMPLETED || task.status == TaskStatus.CANCELLED) continue
            if (todayTaskIds.contains(plan.taskId)) continue

            val rolloverChain = plan.rolloverFromDate ?: yesterday
            val rolloverCount = countRolloversInChain(plan)

            if (rolloverCount >= MAX_ROLLOVERS) continue

            plan.deletedAt = now

            val remark = "Carried over from $yesterday"
            DailyPlanEntity(
                userId = userId,
                taskId = plan.taskId,
                calendarDate = today,
                remark = remark,
                rolloverFromDate = rolloverChain,
                createdAt = now
            ).also { dailyPlanRepository.save(it) }
        }
    }

    private fun countRolloversInChain(plan: DailyPlanEntity): Int {
        var current: DailyPlanEntity = plan
        var count = 0
        while (true) {
            val fromDate = current.rolloverFromDate ?: return count
            val previous = dailyPlanRepository
                .findByUserIdAndCalendarDateOrderByCreatedAtAsc(current.userId, fromDate)
                .find { it.taskId == current.taskId }
            if (previous == null) return count
            count++
            current = previous
        }
    }

    @EventListener
    fun onTaskCompleted(event: TaskCompletedEvent) {
        removeFuturePlans(event.taskId, event.userId)
    }

    @EventListener
    fun onTaskCancelled(event: TaskCancelledEvent) {
        removeFuturePlans(event.taskId, event.userId)
    }

    private fun removeFuturePlans(taskId: UUID, userId: UUID) {
        val today = userTimezoneService.today(userId)
        val futureEntries = dailyPlanRepository.findFutureActiveByTaskId(taskId, today)
        val now = clock.instant()
        futureEntries.forEach { it.deletedAt = now }
    }
}

data class CapacityInfo(
    val capacityHours: Int,
    val plannedHours: Int,
    val overCapacity: Boolean
)
