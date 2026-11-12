package com.productivityos.schedule.persistence

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.time.Instant
import java.time.LocalDate
import java.util.UUID

@Entity
@Table(name = "schedule_habit_occurrences")
class ScheduleHabitOccurrenceEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    val id: UUID? = null,

    @Column(name = "user_id", nullable = false)
    val userId: UUID,

    @Column(name = "habit_id", nullable = false)
    val habitId: UUID,

    @Column(name = "calendar_date", nullable = false)
    val calendarDate: LocalDate,

    @Column(name = "completed_at", nullable = false)
    val completedAt: Instant
)
