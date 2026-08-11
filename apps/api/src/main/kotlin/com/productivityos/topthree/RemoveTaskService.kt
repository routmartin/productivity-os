package com.productivityos.topthree

import com.productivityos.user.UserTimezoneService
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.time.LocalDate
import java.util.UUID

@Service
@Transactional
class RemoveTaskService(
    private val dailyTopThreeRepository: DailyTopThreeRepository,
    private val userTimezoneService: UserTimezoneService,
    private val clock: Clock
) {
    fun remove(userId: UUID, calendarDate: LocalDate, selectionId: UUID): List<TopThreeResponse> {
        val today = userTimezoneService.today(userId)
        require(!calendarDate.isBefore(today)) { "Past dates are view-only" }

        val entries = dailyTopThreeRepository
            .findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByPositionAsc(userId, calendarDate)

        val target = entries.find { it.id == selectionId }
            ?: throw NoSuchElementException("Selection not found: $selectionId")

        require(target.userId == userId) { "Selection does not belong to the current user" }

        val now = clock.instant()
        target.deletedAt = now

        val removedPosition = target.position
        entries.filter { it.position > removedPosition }
            .forEach { it.position -= 1 }

        return dailyTopThreeRepository
            .findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByPositionAsc(userId, calendarDate)
            .map { TopThreeResponse.from(it, null, null) }
    }
}
