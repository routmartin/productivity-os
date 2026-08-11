package com.productivityos.topthree

import com.productivityos.task.TaskRepository
import com.productivityos.user.UserTimezoneService
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.util.UUID

@Service
@Transactional(readOnly = true)
class ListTopThreeService(
    private val dailyTopThreeRepository: DailyTopThreeRepository,
    private val taskRepository: TaskRepository,
    private val userTimezoneService: UserTimezoneService
) {
    fun list(userId: UUID, calendarDate: LocalDate): List<TopThreeResponse> {
        val today = userTimezoneService.today(userId)
        val isPast = calendarDate.isBefore(today)

        val entries = if (isPast) {
            dailyTopThreeRepository.findByUserIdAndCalendarDateOrderByPositionAsc(userId, calendarDate)
        } else {
            dailyTopThreeRepository.findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByPositionAsc(userId, calendarDate)
        }

        return entries.map { entity ->
            if (entity.deletedAt != null && isPast) {
                TopThreeResponse.deleted(entity, entity.position)
            } else {
                val task = taskRepository.findById(entity.taskId).orElse(null)
                TopThreeResponse.from(entity, task?.title, task?.completedAt)
            }
        }
    }
}
