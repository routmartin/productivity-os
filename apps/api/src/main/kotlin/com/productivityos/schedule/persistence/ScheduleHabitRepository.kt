package com.productivityos.schedule.persistence

import org.springframework.data.jpa.repository.JpaRepository
import java.util.Optional
import java.util.UUID

interface ScheduleHabitRepository : JpaRepository<ScheduleHabitEntity, UUID> {
    fun findByUserIdAndDeletedAtIsNullOrderByOrderIndexAsc(userId: UUID): List<ScheduleHabitEntity>
    fun findByIdAndUserIdAndDeletedAtIsNull(id: UUID, userId: UUID): Optional<ScheduleHabitEntity>
    fun countByUserIdAndDeletedAtIsNull(userId: UUID): Long
}
