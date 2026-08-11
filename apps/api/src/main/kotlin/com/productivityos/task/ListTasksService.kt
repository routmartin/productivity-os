package com.productivityos.task

import com.productivityos.user.CurrentUser
import org.springframework.data.domain.PageRequest
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional(readOnly = true)
class ListTasksService(
    private val taskRepository: TaskRepository,
    private val currentUser: CurrentUser
) {

    fun listActive(page: Int, size: Int): List<TaskResponse> {
        val userId = currentUser.id()
        val pageable = PageRequest.of(page, size)
        return taskRepository.findActiveByUserId(userId, pageable)
            .content
            .map { TaskResponse.from(it) }
    }
}
