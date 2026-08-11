package com.productivityos.topthree

import com.productivityos.user.UserTimezoneService
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.time.LocalDate
import java.util.UUID

@Service
@Transactional
class SelectTaskService(
    private val dailyTopThreeRepository: DailyTopThreeRepository,
    private val taskEligibilityService: TaskEligibilityService,
    private val userTimezoneService: UserTimezoneService,
    private val clock: Clock
) {
    fun select(userId: UUID, calendarDate: LocalDate, taskId: UUID, position: Int?): TopThreeResponse {
        val today = userTimezoneService.today(userId)
        require(!calendarDate.isBefore(today)) { "Past dates are view-only" }

        val eligibility = taskEligibilityService.checkEligible(taskId, userId)
        require(eligibility.eligible) { eligibility.reason!! }

        val activeCount = dailyTopThreeRepository.countActiveByUserIdAndDate(userId, calendarDate)
        require(activeCount < 3) { "Top 3 is full" }

        val existing = dailyTopThreeRepository
            .findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByPositionAsc(userId, calendarDate)
        require(existing.none { it.taskId == taskId }) { "Task is already in the Top 3 for this date" }

        val targetPosition = resolvePosition(position, existing)

        val now = clock.instant()
        val entity = DailyTopThreeEntity(
            userId = userId,
            taskId = taskId,
            calendarDate = calendarDate,
            position = targetPosition,
            selectedAt = now
        )
        val saved = dailyTopThreeRepository.save(entity)
        return TopThreeResponse.from(saved, null, null)
    }

    private fun resolvePosition(requested: Int?, existing: List<DailyTopThreeEntity>): Int {
        if (requested != null) {
            require(requested in 1..3) { "Position must be between 1 and 3" }
            val occupied = existing.map { it.position }.toSet()
            if (!occupied.contains(requested)) return requested

            existing.filter { it.position >= requested }
                .sortedByDescending { it.position }
                .forEach { it.position += 1 }
            return requested
        }

        val occupied = existing.map { it.position }.toSet()
        return (1..3).first { it !in occupied }
    }
}
