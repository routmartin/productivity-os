package com.productivityos.schedule.persistence

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "schedule_habits")
class ScheduleHabitEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    val id: UUID? = null,

    @Column(name = "user_id", nullable = false)
    val userId: UUID,

    @Column(nullable = false)
    var title: String,

    @Column
    var subtitle: String? = null,

    @Column(nullable = false)
    var icon: String = "sun.max",

    @Column(nullable = false)
    var phase: String,

    @Column(name = "target_time")
    var targetTime: String? = null,

    @Column(name = "duration_minutes", nullable = false)
    var durationMinutes: Int = 15,

    @Column(name = "order_index", nullable = false)
    var orderIndex: Int = 0,

    @Column(nullable = false)
    var active: Boolean = true,

    @Column
    var notes: String? = null,

    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: Instant,

    @Column(name = "deleted_at")
    var deletedAt: Instant? = null
)
