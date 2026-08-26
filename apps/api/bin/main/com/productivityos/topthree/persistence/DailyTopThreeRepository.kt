package com.productivityos.topthree.persistence

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import java.time.LocalDate
import java.util.UUID

interface DailyTopThreeRepository : JpaRepository<DailyTopThreeEntity, UUID> {

    fun findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByPositionAsc(
        userId: UUID, calendarDate: LocalDate
    ): List<DailyTopThreeEntity>

    fun findByUserIdAndCalendarDateOrderByPositionAsc(
        userId: UUID, calendarDate: LocalDate
    ): List<DailyTopThreeEntity>

    fun findByTaskIdAndDeletedAtIsNull(taskId: UUID): List<DailyTopThreeEntity>

    @Query("SELECT COUNT(d) FROM DailyTopThreeEntity d WHERE d.userId = :userId AND d.calendarDate = :date AND d.deletedAt IS NULL")
    fun countActiveByUserIdAndDate(userId: UUID, date: LocalDate): Int
}
