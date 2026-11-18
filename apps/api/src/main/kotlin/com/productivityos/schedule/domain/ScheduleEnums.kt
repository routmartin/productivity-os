package com.productivityos.schedule.domain

enum class ScheduleNodeType(val value: String) {
    ANCHOR("anchor"),
    HABIT("habit"),
    TASK("task"),
    RECHARGE("recharge");

    companion object {
        fun fromValue(value: String): ScheduleNodeType =
            entries.firstOrNull { it.value.equals(value, ignoreCase = true) }
                ?: if (value.equals("activity", ignoreCase = true)) TASK else HABIT
    }
}

enum class ScheduleEdgeType(val value: String) {
    SEQUENTIAL("sequential"),
    PREREQUISITE("prerequisite"),
    PHASE("phase")
}

enum class SchedulePhaseId(
    val value: String,
    val defaultTitle: String,
    val defaultSubtitle: String,
    val defaultTimeRange: String,
    val tone: String
) {
    MORNING(
        "morning",
        "Morning Activation",
        "Rise, hydrate, move & set daily direction",
        "06:20 – 10:00",
        "warning"
    ),
    DEEP_FOCUS(
        "deep-focus",
        "Deep Focus Work",
        "Uninterrupted creative flow on primary deliverables",
        "10:00 – 12:00",
        "accent"
    ),
    AFTERNOON(
        "afternoon",
        "Afternoon Momentum",
        "Review, collaboration, deep execution & wrap-up",
        "12:00 – 18:30",
        "blue"
    ),
    BEDTIME(
        "bedtime",
        "Bedtime Sanctuary",
        "Dinner, decompression, learning & sleep recovery",
        "20:00 – 23:20",
        "success"
    );

    companion object {
        fun fromValue(value: String): SchedulePhaseId? =
            entries.firstOrNull { it.value.equals(value, ignoreCase = true) }
    }
}
