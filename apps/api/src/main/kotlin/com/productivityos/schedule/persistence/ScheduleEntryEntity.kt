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
@Table(name = "schedule_entries")
class ScheduleEntryEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    val id: UUID? = null,

    @Column(name = "user_id", nullable = false)
    val userId: UUID,

    @Column(name = "calendar_date", nullable = false)
    val calendarDate: LocalDate,

    @Column(name = "step_type", nullable = false)
    var stepType: String,

    @Column(nullable = false)
    var phase: String,

    @Column(nullable = false)
    var title: String,

    @Column
    var subtitle: String? = null,

    @Column(name = "time_label")
    var timeLabel: String? = null,

    @Column(name = "duration_minutes", nullable = false)
    var durationMinutes: Int = 30,

    @Column(name = "in_focus", nullable = false)
    var inFocus: Boolean = false,

    @Column(name = "completed_minutes", nullable = false)
    var completedMinutes: Int = 0,

    @Column(name = "order_index", nullable = false)
    var orderIndex: Int = 0,

    @Column
    var notes: String? = null,

    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: Instant,

    @Column(name = "deleted_at")
    var deletedAt: Instant? = null
)
