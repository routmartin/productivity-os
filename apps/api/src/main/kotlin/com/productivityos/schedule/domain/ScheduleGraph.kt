package com.productivityos.schedule.domain

data class ScheduleGraph(
    val date: String,
    val wakeTime: String,
    val targetBedtime: String,
    val projectedBedtime: String,
    val overflowMinutes: Int,
    val phases: List<SchedulePhase>,
    val nodes: List<ScheduleNode>,
    val edges: List<ScheduleEdge>
)
