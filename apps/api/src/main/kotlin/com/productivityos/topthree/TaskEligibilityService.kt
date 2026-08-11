package com.productivityos.topthree

import com.productivityos.task.TaskRepository
import com.productivityos.task.TaskStatus
import org.springframework.stereotype.Service
import java.util.UUID

@Service
class TaskEligibilityService(
    private val taskRepository: TaskRepository
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
        return EligibilityResult.eligible()
    }
}
