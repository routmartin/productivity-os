package com.productivityos.goal

import java.time.Instant
import java.time.LocalDate
import java.util.UUID

data class Goal(
    val id: UUID,
    val userId: UUID,
    val title: String,
    val description: String? = null,
    val status: GoalStatus = GoalStatus.DRAFT,
    val deadline: LocalDate? = null,
    val completedAt: Instant? = null
) {
    fun activate(): Goal {
        require(status == GoalStatus.DRAFT) { "Only Draft goals can be activated" }
        return copy(status = GoalStatus.ACTIVE)
    }

    fun complete(now: Instant): Goal {
        require(status == GoalStatus.ACTIVE) { "Only Active goals can be completed" }
        return copy(status = GoalStatus.COMPLETED, completedAt = now)
    }

    fun reopen(): Goal {
        require(status == GoalStatus.COMPLETED) { "Only Completed goals can be reopened" }
        return copy(status = GoalStatus.ACTIVE)
    }

    fun archive(): Goal {
        require(status == GoalStatus.COMPLETED) { "Only Completed goals can be archived" }
        return copy(status = GoalStatus.ARCHIVED)
    }
}
