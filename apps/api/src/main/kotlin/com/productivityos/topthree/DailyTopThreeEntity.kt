package com.productivityos.topthree

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table
import jakarta.persistence.Version
import java.time.Instant
import java.time.LocalDate
import java.util.UUID

@Entity
@Table(name = "daily_top_three")
class DailyTopThreeEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    val id: UUID? = null,

    @Column(name = "user_id", nullable = false)
    val userId: UUID,

    @Column(name = "task_id", nullable = false)
    val taskId: UUID,

    @Column(name = "calendar_date", nullable = false)
    val calendarDate: LocalDate,

    @Column(nullable = false)
    var position: Int,

    @Column(name = "selected_at", nullable = false)
    val selectedAt: Instant,

    @Column(name = "deleted_at")
    var deletedAt: Instant? = null,

    @Version
    var version: Long = 0
) {
    fun toDomain(): DailyTopThree = DailyTopThree(
        id = id!!,
        userId = userId,
        taskId = taskId,
        calendarDate = calendarDate,
        position = position,
        selectedAt = selectedAt,
        deletedAt = deletedAt
    )
}
