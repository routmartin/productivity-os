package com.productivityos.topthree

import com.productivityos.project.ProjectRepository
import com.productivityos.project.ProjectStatus
import com.productivityos.task.TaskRepository
import com.productivityos.task.TaskStatus
import org.springframework.stereotype.Service
import java.util.UUID

@Service
class TaskEligibilityService(
    private val taskRepository: TaskRepository,
    private val projectRepository: ProjectRepository
) {
    fun checkEligible(taskId: UUID, userId: UUID): EligibilityResult {
        val task = taskRepository.findById(taskId).orElse(null)
            ?: return EligibilityResult.ineligible("Task not found")

        if (task.userId != userId) {
            return EligibilityResult.ineligible("Task does not belong to the current user")
        }
        if (task.deletedAt != null) {
            return EligibilityResult.ineligible("Task is deleted")
        }
        if (task.status == TaskStatus.COMPLETED) {
            return EligibilityResult.ineligible("Task is completed")
        }
        if (task.status == TaskStatus.CANCELLED) {
            return EligibilityResult.ineligible("Task is cancelled")
        }

        val projectId = task.projectId
        if (projectId != null) {
            val project = projectRepository.findById(projectId).orElse(null)
            if (project != null && project.status == ProjectStatus.ARCHIVED) {
                return EligibilityResult.ineligible("Task belongs to an archived project")
            }
        }

        return EligibilityResult.eligible()
    }
}
