package com.productivityos.dailyplan

import com.productivityos.task.TaskCancelledEvent
import com.productivityos.task.TaskCompletedEvent
import com.productivityos.task.TaskRepository
import com.productivityos.user.UserTimezoneService
import org.springframework.context.event.EventListener
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
    private val clock: Clock
) {
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
