package com.productivityos.schedule.persistence

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import java.time.LocalDate
import java.util.Optional
import java.util.UUID

interface ScheduleHabitOccurrenceRepository : JpaRepository<ScheduleHabitOccurrenceEntity, UUID> {
    fun findByUserIdAndCalendarDate(userId: UUID, date: LocalDate): List<ScheduleHabitOccurrenceEntity>
    fun findByUserIdAndHabitIdAndCalendarDate(userId: UUID, habitId: UUID, date: LocalDate): Optional<ScheduleHabitOccurrenceEntity>
    fun findByUserIdAndHabitIdAndCalendarDateBetween(userId: UUID, habitId: UUID, fromDate: LocalDate, toDate: LocalDate): List<ScheduleHabitOccurrenceEntity>
    fun findByUserIdAndCalendarDateBetween(userId: UUID, fromDate: LocalDate, toDate: LocalDate): List<ScheduleHabitOccurrenceEntity>

    @Modifying
    @Query("DELETE FROM ScheduleHabitOccurrenceEntity o WHERE o.userId = :userId AND o.habitId = :habitId AND o.calendarDate = :date")
    fun deleteByUserIdAndHabitIdAndCalendarDate(userId: UUID, habitId: UUID, date: LocalDate): Int
}
