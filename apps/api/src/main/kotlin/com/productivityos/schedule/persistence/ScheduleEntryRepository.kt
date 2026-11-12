package com.productivityos.schedule.persistence

import org.springframework.data.jpa.repository.JpaRepository
import java.time.LocalDate
import java.util.Optional
import java.util.UUID

interface ScheduleEntryRepository : JpaRepository<ScheduleEntryEntity, UUID> {
    fun findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByOrderIndexAsc(userId: UUID, date: LocalDate): List<ScheduleEntryEntity>
    fun findByIdAndUserIdAndDeletedAtIsNull(id: UUID, userId: UUID): Optional<ScheduleEntryEntity>
}
