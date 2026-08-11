package com.productivityos.topthree

import com.productivityos.project.ProjectRepository
import com.productivityos.project.ProjectStatus
import com.productivityos.task.TaskRepository
import com.productivityos.task.TaskStatus
import com.productivityos.user.UserTimezoneService
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.time.LocalDate
import java.util.UUID

@Service
@Transactional
class TopThreeService(
    private val dailyTopThreeRepository: DailyTopThreeRepository,
    private val taskRepository: TaskRepository,
    private val projectRepository: ProjectRepository,
    private val userTimezoneService: UserTimezoneService,
    private val clock: Clock
) {
    @Transactional(readOnly = true)
    fun list(userId: UUID, calendarDate: LocalDate): List<TopThreeResponse> {
        val today = userTimezoneService.today(userId)
        val isPast = calendarDate.isBefore(today)

        val entries = if (isPast) {
            dailyTopThreeRepository.findByUserIdAndCalendarDateOrderByPositionAsc(userId, calendarDate)
        } else {
            dailyTopThreeRepository.findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByPositionAsc(userId, calendarDate)
        }

        return entries.map { entity ->
            if (entity.deletedAt != null && isPast) {
                TopThreeResponse.deleted(entity, entity.position)
            } else {
                val task = taskRepository.findById(entity.taskId).orElse(null)
                TopThreeResponse.from(entity, task?.title, task?.completedAt)
            }
        }
    }

    fun select(userId: UUID, calendarDate: LocalDate, taskId: UUID, position: Int?): TopThreeResponse {
        val today = userTimezoneService.today(userId)
        require(!calendarDate.isBefore(today)) { "Past dates are view-only" }

        val eligibility = checkEligible(taskId, userId)
        require(eligibility.eligible) { eligibility.reason!! }

        val activeCount = dailyTopThreeRepository.countActiveByUserIdAndDate(userId, calendarDate)
        require(activeCount < 3) { "Top 3 is full" }

        val existing = dailyTopThreeRepository
            .findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByPositionAsc(userId, calendarDate)
        require(existing.none { it.taskId == taskId }) { "Task is already in the Top 3 for this date" }

        val targetPosition = resolvePosition(position, existing)

        val now = clock.instant()
        val entity = DailyTopThreeEntity(
            userId = userId,
            taskId = taskId,
            calendarDate = calendarDate,
            position = targetPosition,
            selectedAt = now
        )
        val saved = dailyTopThreeRepository.save(entity)
        return TopThreeResponse.from(saved, null, null)
    }

    fun reorder(userId: UUID, calendarDate: LocalDate, selectionId: UUID, newPosition: Int): List<TopThreeResponse> {
        val today = userTimezoneService.today(userId)
        require(!calendarDate.isBefore(today)) { "Past dates are view-only" }
        require(newPosition in 1..3) { "Position must be between 1 and 3" }

        val entries = dailyTopThreeRepository
            .findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByPositionAsc(userId, calendarDate)

        val target = entries.find { it.id == selectionId }
            ?: throw NoSuchElementException("Selection not found: $selectionId")
        require(target.userId == userId) { "Selection does not belong to the current user" }

        val oldPosition = target.position
        if (oldPosition == newPosition) return entries.map { TopThreeResponse.from(it, null, null) }

        if (newPosition < oldPosition) {
            entries.filter { it.position in newPosition until oldPosition }
                .forEach { it.position += 1 }
        } else {
            entries.filter { it.position in (oldPosition + 1)..newPosition }
                .forEach { it.position -= 1 }
        }
        target.position = newPosition

        return dailyTopThreeRepository
            .findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByPositionAsc(userId, calendarDate)
            .map { TopThreeResponse.from(it, null, null) }
    }

    fun remove(userId: UUID, calendarDate: LocalDate, selectionId: UUID): List<TopThreeResponse> {
        val today = userTimezoneService.today(userId)
        require(!calendarDate.isBefore(today)) { "Past dates are view-only" }

        val entries = dailyTopThreeRepository
            .findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByPositionAsc(userId, calendarDate)

        val target = entries.find { it.id == selectionId }
            ?: throw NoSuchElementException("Selection not found: $selectionId")
        require(target.userId == userId) { "Selection does not belong to the current user" }

        target.deletedAt = clock.instant()

        val removedPosition = target.position
        entries.filter { it.position > removedPosition }
            .forEach { it.position -= 1 }

        return dailyTopThreeRepository
            .findByUserIdAndCalendarDateAndDeletedAtIsNullOrderByPositionAsc(userId, calendarDate)
            .map { TopThreeResponse.from(it, null, null) }
    }

    private fun checkEligible(taskId: UUID, userId: UUID): EligibilityResult {
        val task = taskRepository.findById(taskId).orElse(null)
            ?: return EligibilityResult.ineligible("Task not found")

        if (task.userId != userId) return EligibilityResult.ineligible("Task does not belong to the current user")
        if (task.deletedAt != null) return EligibilityResult.ineligible("Task is deleted")
        if (task.status == TaskStatus.COMPLETED) return EligibilityResult.ineligible("Task is completed")
        if (task.status == TaskStatus.CANCELLED) return EligibilityResult.ineligible("Task is cancelled")

        val projectId = task.projectId
        if (projectId != null) {
            val project = projectRepository.findById(projectId).orElse(null)
            if (project != null && project.status == ProjectStatus.ARCHIVED) {
                return EligibilityResult.ineligible("Task belongs to an archived project")
            }
        }

        return EligibilityResult.eligible()
    }

    private fun resolvePosition(requested: Int?, existing: List<DailyTopThreeEntity>): Int {
        if (requested != null) {
            require(requested in 1..3) { "Position must be between 1 and 3" }
            val occupied = existing.map { it.position }.toSet()
            if (!occupied.contains(requested)) return requested

            existing.filter { it.position >= requested }
                .sortedByDescending { it.position }
                .forEach { it.position += 1 }
            return requested
        }

        val occupied = existing.map { it.position }.toSet()
        return (1..3).first { it !in occupied }
    }
}
