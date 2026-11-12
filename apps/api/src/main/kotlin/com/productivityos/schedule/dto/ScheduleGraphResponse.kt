package com.productivityos.schedule.dto

data class ScheduleGraphResponse(
    val date: String,
    val wakeTime: String,
    val targetBedtime: String,
    val projectedBedtime: String,
    val overflowMinutes: Int,
    val phases: List<SchedulePhaseDTO>,
    val nodes: List<ScheduleNodeDTO>,
    val edges: List<ScheduleEdgeDTO>
)
