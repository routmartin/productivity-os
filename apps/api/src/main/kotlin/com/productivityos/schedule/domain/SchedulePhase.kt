package com.productivityos.schedule.domain

data class SchedulePhase(
    val id: String,
    val title: String,
    val subtitle: String,
    val timeRange: String,
    val colorTone: String? = null
)
