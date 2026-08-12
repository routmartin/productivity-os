package com.productivityos.dailyplan

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
@Table(name = "daily_plans")
class DailyPlanEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    val id: UUID? = null,

    @Column(name = "user_id", nullable = false)
    val userId: UUID,

    @Column(name = "task_id", nullable = false)
    val taskId: UUID,

    @Column(name = "calendar_date", nullable = false)
    val calendarDate: LocalDate,

    @Column
    val remark: String? = null,

    @Column(name = "rollover_from_date")
    val rolloverFromDate: LocalDate? = null,

    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: Instant,

    @Column(name = "deleted_at")
    var deletedAt: Instant? = null
) {
    fun toDomain(): DailyPlan = DailyPlan(
        id = id!!,
        userId = userId,
        taskId = taskId,
        calendarDate = calendarDate,
        remark = remark
    )
}
