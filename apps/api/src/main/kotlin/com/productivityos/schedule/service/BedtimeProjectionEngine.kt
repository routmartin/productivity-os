package com.productivityos.schedule.service

import org.springframework.stereotype.Component
import kotlin.math.max
import kotlin.math.min

@Component
class BedtimeProjectionEngine {

    fun calculateOverflow(pendingHabits: Int, incompleteActivities: Int): Int {
        val totalPending = max(0, pendingHabits) + max(0, incompleteActivities)
        return min(45, totalPending * 15)
    }

    fun calculateProjectedTime(targetBedtime: String, overflowMinutes: Int): String {
        val parts = targetBedtime.split(":")
        val baseHour = parts.getOrNull(0)?.toIntOrNull() ?: 22
        val baseMinute = parts.getOrNull(1)?.toIntOrNull() ?: 30
        val totalMinutes = baseHour * 60 + baseMinute + max(0, overflowMinutes)
        val hours = (totalMinutes / 60) % 24
        val minutes = totalMinutes % 60
        return String.format("%02d:%02d", hours, minutes)
    }
}
