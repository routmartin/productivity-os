package com.productivityos.topthree

import com.productivityos.task.TaskDeletedEvent
import com.productivityos.task.TaskRestoredEvent
import com.productivityos.user.UserTimezoneService
import org.springframework.context.event.EventListener
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock

@Service
@Transactional
class TopThreeSyncService(
    private val dailyTopThreeRepository: DailyTopThreeRepository,
    private val userTimezoneService: UserTimezoneService,
    private val clock: Clock
) {
    @EventListener
    fun onTaskDeleted(event: TaskDeletedEvent) {
        val today = userTimezoneService.today(event.userId)
        val activeEntries = dailyTopThreeRepository.findByTaskIdAndDeletedAtIsNull(event.taskId)
            .filter { it.userId == event.userId && !it.calendarDate.isBefore(today) }

        val now = clock.instant()
        activeEntries.forEach { it.deletedAt = now }

        val affectedDates = activeEntries.map { it.calendarDate }.distinct()
        for (date in affectedDates) {
            val remaining = dailyTopThreeRepository
                .findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByPositionAsc(event.userId, date)
            remaining.sortedBy { it.position }
                .forEachIndexed { index, entity -> entity.position = index + 1 }
        }
    }

    @EventListener
    fun onTaskRestored(event: TaskRestoredEvent) {
    }
}
