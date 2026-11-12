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
        "06:30 – 09:00",
        "warning"
    ),
    DEEP_FOCUS(
        "deep-focus",
        "Deep Focus Work",
        "Uninterrupted creative flow on Top 1 & Top 2",
        "09:00 – 12:30",
        "accent"
    ),
    AFTERNOON(
        "afternoon",
        "Afternoon Momentum",
        "Top 3, collaboration, shallow work & reset",
        "12:30 – 18:00",
        "blue"
    ),
    BEDTIME(
        "bedtime",
        "Bedtime Sanctuary",
        "Digital curfew, reflection, reading & sleep recovery",
        "21:00 – 22:30",
        "success"
    );

    companion object {
        fun fromValue(value: String): SchedulePhaseId? =
            entries.firstOrNull { it.value.equals(value, ignoreCase = true) }
    }
}
