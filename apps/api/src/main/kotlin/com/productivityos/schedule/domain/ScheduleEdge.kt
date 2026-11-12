package com.productivityos.schedule.domain

data class ScheduleEdge(
    val id: String,
    val fromNodeId: String,
    val toNodeId: String,
    val type: String? = "sequential",
    val active: Boolean? = false,
    val label: String? = null
)
