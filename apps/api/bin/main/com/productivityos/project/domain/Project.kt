package com.productivityos.project.domain

import java.time.Instant
import java.time.LocalDate
import java.util.UUID

data class Project(
    val id: UUID,
    val userId: UUID,
    val title: String,
    val description: String? = null,
    val goalId: UUID? = null,
    val status: ProjectStatus = ProjectStatus.DRAFT,
    val deadline: LocalDate? = null,
    val completedAt: Instant? = null
) {
    fun activate(): Project {
        require(status == ProjectStatus.DRAFT) { "Only Draft projects can be activated" }
        return copy(status = ProjectStatus.ACTIVE)
    }

    fun returnToDraft(): Project {
        require(status == ProjectStatus.ACTIVE) { "Only Active projects can return to Draft" }
        return copy(status = ProjectStatus.DRAFT)
    }

    fun complete(now: Instant): Project {
        require(status == ProjectStatus.ACTIVE) { "Only Active projects can be completed" }
        return copy(status = ProjectStatus.COMPLETED, completedAt = now)
    }

    fun archive(): Project {
        require(status == ProjectStatus.COMPLETED) { "Only Completed projects can be archived" }
        return copy(status = ProjectStatus.ARCHIVED)
    }
}
