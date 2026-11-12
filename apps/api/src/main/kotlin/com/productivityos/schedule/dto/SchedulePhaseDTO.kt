package com.productivityos.schedule.dto

data class SchedulePhaseDTO(
    val id: String,
    val title: String,
    val subtitle: String,
    val timeRange: String,
    val colorTone: String? = null
)
