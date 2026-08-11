package com.productivityos.topthree

import com.productivityos.user.UserTimezoneService
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.util.UUID

@Service
@Transactional
class ReorderTaskService(
    private val dailyTopThreeRepository: DailyTopThreeRepository,
    private val userTimezoneService: UserTimezoneService
) {
    fun reorder(userId: UUID, calendarDate: LocalDate, selectionId: UUID, newPosition: Int): List<TopThreeResponse> {
        val today = userTimezoneService.today(userId)
        require(!calendarDate.isBefore(today)) { "Past dates are view-only" }
        require(newPosition in 1..3) { "Position must be between 1 and 3" }

        val entries = dailyTopThreeRepository
            .findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByPositionAsc(userId, calendarDate)

        val target = entries.find { it.id == selectionId }
            ?: throw NoSuchElementException("Selection not found: $selectionId")

        require(target.userId == userId) { "Selection does not belong to the current user" }

        val oldPosition = target.position
        if (oldPosition == newPosition) return entries.map { TopThreeResponse.from(it, null, null) }

        if (newPosition < oldPosition) {
            entries.filter { it.position in newPosition until oldPosition }
                .forEach { it.position += 1 }
        } else {
            entries.filter { it.position in (oldPosition + 1)..newPosition }
                .forEach { it.position -= 1 }
        }
        target.position = newPosition

        return dailyTopThreeRepository
            .findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByPositionAsc(userId, calendarDate)
            .map { TopThreeResponse.from(it, null, null) }
    }
}
