package com.productivityos.dailyplan.persistence

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import java.time.LocalDate
import java.util.UUID

interface DailyPlanRepository : JpaRepository<DailyPlanEntity, UUID> {

    fun findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByCreatedAtAsc(
        userId: UUID, calendarDate: LocalDate
    ): List<DailyPlanEntity>

    fun findByUserIdAndCalendarDateOrderByCreatedAtAsc(
        userId: UUID, calendarDate: LocalDate
    ): List<DailyPlanEntity>

    @Query("SELECT dp FROM DailyPlanEntity dp WHERE dp.taskId = :taskId AND dp.calendarDate > :today AND dp.deletedAt IS NULL")
    fun findFutureActiveByTaskId(taskId: UUID, today: LocalDate): List<DailyPlanEntity>
}
