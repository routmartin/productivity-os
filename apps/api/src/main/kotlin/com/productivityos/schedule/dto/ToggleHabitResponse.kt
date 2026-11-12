package com.productivityos.schedule.dto

import java.util.UUID

data class ToggleHabitResponse(
    val habitId: UUID,
    val completed: Boolean,
    val streak: Int,
    val history: List<HabitStreakDayDTO>,
    val updatedEdges: List<ScheduleEdgeDTO>,
    val projectedBedtime: String,
    val overflowMinutes: Int
)
